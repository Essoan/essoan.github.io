#include <Wire.h>
#include <Adafruit_INA219.h>    // Current sensors
#include <Adafruit_GFX.h>       // Display library
#include <Adafruit_SH110X.h>    // Library for 0.9" displays
#include <Adafruit_SSD1306.h>   // Library for 1.3" displays

#define oled_width 128          // Number of width pixels in display
#define oled_height 64          // Number of height pixels in display

#define pinSDA 6                // The I2C SDA pin
#define pinSCL 7                // The I2C SCL pin

#define oled_adr 0x3C           // I2C address of the OLED
#define I2C_INA219_1 0x40       // I2C address of the first current sensor
#define I2C_INA219_2 0x41       // I2C address of the second current sensor
#define I2C_INA219_3 0x44       // I2C address of the third current sensor

#define oled_rst -1             // OLED reset pin default

Adafruit_INA219 ina219_1(0x40); // Initiate current sensor 1 
Adafruit_INA219 ina219_2(0x41); // Initiate current sensor 2
Adafruit_INA219 ina219_3(0x44); // Initiate current sensor 3

// Initiate the OLED
Adafruit_SH1106G display(oled_width, oled_height, &Wire, oled_rst);

void setup() {
  Serial.begin(115200); // Start serial monitor
  ina219_1.begin();     // Start the current sensor
  ina219_2.begin();     // Start the current sensor 
  ina219_3.begin();     // Start the current sensor
  display.begin(0x3C, true);  // Start the OLED
  display.clearDisplay();     // Clear the display
  
  analogWriteFreq(500000); // this sets frequency to 520 kHz. Mcu may owerwrite frequency to optimal value.
  analogWriteRange(4096); // The resolution of the duty-cycle.
  analogReadResolution(12); // Resolution of the ADC readings.
}
// class for setting PWM parameters and updating dutycycle and fetching output voltages.
class PWM {
  int Dc {};
  size_t pwmPin {};

public:
  // Set the PWM pinout
  PWM (size_t pinOut){
    pwmPin = pinOut;
  }
  // Function for setting the PWM dutycycle for each output pin.
  void doPWM (double dutyCycle){
    Dc = dutyCycle;
    analogWrite(pwmPin, Dc);
  }

  // Function for determining output voltage.
  double Vo (double R_1, double R_2, double V_ref, double V_trim, double duty_Range, size_t pin){
    size_t readPin {pin};
    double R1 {R_1};
    double R2 {R_2};
    double Vref {V_ref};
    double Vtrim {V_trim};
    double dutyRange {duty_Range};
    
    double VoRead {analogRead(readPin)};

    double Vdiv {((R1 + R2) / R2)};
    double Vo {(VoRead * ((Vref) / dutyRange) * (Vdiv + Vtrim))};

    return Vo;
  }
};

// Initiating the three PWM outputs.

PWM signal_1(16);
PWM signal_2(17);
PWM signal_3(18);

// Pins for the ADC readings
size_t Bu1_readPin {28};
size_t Bu2_readPin {27};

// Meassured resistance of voltage dividers for Buck converters.
double R1_Bu1 {14890};
double R2_Bu1 {4630};

double R1_Bu2 {14840};
double R2_Bu2 {4650};

// Reference voltages
double Vref {3.300};
double Vref_Bu1 {3.300};
double Vref_Bu2 {5.000};

// calculations of the voltage dividers
double Vdivider_Bu1 {((R1_Bu1 + R2_Bu1) / R2_Bu1)};
double Vdivider_Bu2 {((R1_Bu2 + R2_Bu2) / R2_Bu2)};

// Values for trimming the output of the converters to meassurements
double Vtrim_Bu1 {-0.200};
double Vtrim_Bu2 {-0.130};
double Vtrim_Se1 {0.000};

int dutyRange {4095}; // The dutycycle range
int dutyC_Bu1 {2048}; // Buck converter 1 initial duty-cycle value
int dutyC_Bu2 {2048}; // Buck converter 2 initial duty-cycle value
int dutyC_Se1 {2048}; // SEPIC initial duty-cycle value
int dutyStep {8};     // Buck converter duty-cycle steps
int dutyStep_S {16};  // SEPIC duty-cycle steps

double Pi_Se1_old {}; // variable for old power reading for P&O algorithm
double Vi_Se1_old {}; // variable for old voltage reading for P&O algorithm

void loop() {
  
  double Vo_Bu1 = signal_1.Vo(R1_Bu1, R2_Bu1, Vref, Vtrim_Bu1, dutyRange, Bu1_readPin); // Fetch output voltage readings for the 3.3 V Buck converter
  double Vo_Bu2 = signal_2.Vo(R1_Bu2, R2_Bu2, Vref, Vtrim_Bu2, dutyRange, Bu2_readPin); // Fetch output voltage readings for the 5 V Buck converter
//  double Vi_Se1 = signal_1.Vo(R1_Se1, R2_Se1, Vref, Vtrim_Se1, dutyRange, Se1_readPin); // Used in early design of SEPIC for stabilizing output votlage. Now obsolete.

  double Ii_Se1 = (ina219_1.getCurrent_mA() * 0.87); // current readings for the SEPIC input, adjustments done so sensor is in tune with DMM (not in use).
  double Vi_read = (ina219_1.getBusVoltage_V() + (ina219_1.getShuntVoltage_mV() / 1000)); // voltage readings for the SEPIC input
  double Vi_Se1 = (Vi_read * 1.1); // Input voltage adjustment to DMM
  double Pi_Se1 = (ina219_1.getPower_mW()); // Power reading from current sensor
  double Vo_Se1 = {(ina219_3.getBusVoltage_V() + (ina219_3.getShuntVoltage_mV() / 1000))}; // Output voltage from the SEPIC
//  double Pi_Se1 = (Vi_Se1 * Ii_Se1); // Alternate way for power reading (not in use).
  double nochange {dutyC_Se1}; // Variable for storing the current duty cycle for no perturbation events.
  
  double dP {Pi_Se1 - Pi_Se1_old}; // change in input power calculation.
  double dV {Vi_Se1 - Vi_Se1_old}; // change in voltage calculation.
  
// =====================================================================================
// ===== Load Variation algorithms of SMPS Buck converters                         =====
// =====================================================================================
  // there is a slight buffer around the reference voltage to avoid unnecessary adjustments to dutycycle
  if ((Vo_Bu1) < (Vref_Bu1 - 0.01) && (dutyC_Bu1 < 3886)){ // If output voltage is less than the reference voltage - the buffer voltage
    dutyC_Bu1 += dutyStep; // increase the duty-cycle
  }
  
  if ((Vo_Bu1) > (Vref_Bu1 + 0.01) && (dutyC_Bu1 > 410)){ // If output voltage is above the reference voltage + the buffer voltage
    dutyC_Bu1 -= dutyStep; // Reduce the duty-cycle
  }
  
  if ((Vo_Bu2) < (Vref_Bu2 - 0.01) && (dutyC_Bu2 < 3886)){ // If output voltage is less than the reference voltage - the buffer voltage
    dutyC_Bu2 += dutyStep; // Increase the duty-cycle
  }
  
  if ((Vo_Bu2) > (Vref_Bu2 + 0.01) && (dutyC_Bu2 > 410)){ // If output voltage is above the reference voltage + the buffer voltage
    dutyC_Bu2 -= dutyStep; // Increase the duty-cycle
  }
// =====================================================================================
// ===== Load Variation algorithms of SMPS SEPIC converter                         =====
// =====================================================================================
// Constant output voltage adjustment for SEPIC - Not in use.
//  if ((Vi_Se1) < (Vref_Se1 - 0.05) && (dutyC_Se1 > 410)){
//    dutyC_Se1 -= dutyStep;
//  }
//  if ((Vi_Se1) > (Vref_Se1 + 0.05) && (dutyC_Se1 < 3686)){
//    dutyC_Se1 += dutyStep;
//  }
// =====================================================================================
// ===== P&O and output voltage control algorithm for SMPS SEPIC                   =====
// =====================================================================================
  if (Vo_Se1 < 4.10) {  // If sentence for absolute maximum output voltage, continue if output voltage is less than or equal to 4.1 V
    if (dP != 0){       // If there is a change between old and new readings, continue ...
      if ((dP > 0.0) && (dutyC_Se1 < 3585) && (dutyC_Se1 > 512)){
        if ((dV > 0.0)){
          dutyC_Se1 -= dutyStep_S; // if difference in power and voltage is above zero, reduce duty-cycle (left side of P-I curve).
        }
        else {
          dutyC_Se1 += dutyStep_S; // if difference in voltage is less than zero, increase duty-cycle (Right side of P-I curve), also max duty-cycle is implemented in the if-else sentences.
        } 
      }
      else if ((dP < 0.0) && (dutyC_Se1 > 512 ) && (dutyC_Se1 < 3585)){
        if ((dV > 0.0)){ 
          dutyC_Se1 += dutyStep_S; // If difference in power is less than zero and difference in voltage is above zero (Right side of P-I curve), increase duty-cycle.
        }
        else {
          dutyC_Se1 -= dutyStep_S; // If difference in voltage is less than zero (left side of P-I curve, increase duty cycle.
        }
      }
    }
    else {
      dutyC_Se1 = nochange; // if there is no change, dont perturb the duty-cycle.
    }
  }
  else if ((Vo_Se1 >= 4.10) && (dutyC_Se1 < 3585)) { // If output voltage is above 4.1, reduce the duty step, increase the duty step.
    dutyC_Se1 += dutyStep_S; // This keeps the current power point on the left side of the P-I curve when adjusting the powerpoint to correct for output voltage.
  }
    
  Pi_Se1_old = Pi_Se1; // Overwrite old values with the current values.
  Vi_Se1_old = Vi_Se1;
  
  signal_1.doPWM(dutyC_Bu1);  // Update the new duty-cycle for the 3.3 V Buck converter.
  signal_2.doPWM(dutyC_Bu2);  // Update the new duty-cycle for the 5 V Buck converter. 
  signal_3.doPWM(dutyC_Se1);  // Update the new duty-cycle for the SEPIC.
  
  displaydata(); //Run the display function

  // Send values to the serial output
  // Serial.print("Voltage out: "); Serial.print(Vo_Bu1); Serial.print(" "); Serial.print(dutyC_Bu1); Serial.print(" "); Serial.print(Vo_Bu2); Serial.print(" "); Serial.print(dutyC_Bu2); Serial.println(" ");
}

// function to display lines, text and SEPIC data on the OLED display
void displaydata() {
  // Variables for readings
  double shuntvoltage_in {};
  double busvoltage_in {};
  double current_mA_in {};
  double filtered_mA_in {};
  double loadvoltage_in {};
  double power_mW_in {};
  double energy_in {};

  double shuntvoltage_out {};
  double busvoltage_out {};
  double current_mA_out {};
  double filtered_mA_out {};
  double loadvoltage_out {};
  double power_mW_out {};
  double energy_out {};

  // Get readings from input sensor
  shuntvoltage_in = ina219_1.getShuntVoltage_mV();
  busvoltage_in = ina219_1.getBusVoltage_V();
  current_mA_in = ina219_1.getCurrent_mA();
  power_mW_in = ina219_1.getPower_mW();
  loadvoltage_in = busvoltage_in + (shuntvoltage_in / 1000);
  energy_in = (energy_in + (loadvoltage_in * (current_mA_in / 3600)));

  // Get readings for output sensor
  shuntvoltage_out = ina219_3.getShuntVoltage_mV();
  busvoltage_out = ina219_3.getBusVoltage_V();
  current_mA_out = ina219_3.getCurrent_mA();
  power_mW_out = ina219_3.getPower_mW();
  loadvoltage_out = busvoltage_out + (shuntvoltage_out / 1000);
  energy_out = (energy_out + (loadvoltage_out * (current_mA_out / 3600)));

  // Initialisation and top data
  display.clearDisplay();       // Clear display for new update
  display.setTextColor(WHITE);  // Text color if display is multicolor
  display.setTextSize(1);       // set text size
  display.setCursor(0, 0);      // sets the current cursor for text / data placement
  display.println("CubeSat EPS"); // Header
  display.setCursor(70, 0);
  display.print("DC:");
  display.setCursor(88, 0);
  display.print(((dutyC_Se1/4097.00)*100));
  display.setCursor(119, 0);
  display.print("%");

  // horisontal lines
  display.setCursor(0, 5);
  display.println("---------------------"); 
  display.setCursor(1, 5);
  display.println("--------------------");   
  display.setCursor(0, 47);
  display.println("---------------------");
  display.setCursor(1, 47);
  display.println("--------------------");
  
  // Left vertical lines
  display.setCursor(-2, 11);
  display.print("|");
  display.setCursor(-2, 8);
  display.print("|");
  display.setCursor(-2, 21);
  display.print("|");
  display.setCursor(-2, 18);
  display.print("|");
  display.setCursor(-2, 31);
  display.print("|");
  display.setCursor(-2, 28);
  display.print("|");
  display.setCursor(-2, 41);
  display.print("|");
  display.setCursor(-2, 38);
  display.print("|");
  display.setCursor(-2, 53);
  display.print("|");
  display.setCursor(-2, 47);
  display.print("|");
  display.setCursor(-2, 55);
  display.print("|");
  
  // Middle vertical lines
  display.setCursor(60, 11);
  display.print("|");
  display.setCursor(60, 8);
  display.print("|");
  display.setCursor(60, 21);
  display.print("|");
  display.setCursor(60, 18);
  display.print("|");
  display.setCursor(60, 31);
  display.print("|");
  display.setCursor(60, 28);
  display.print("|");
  display.setCursor(60, 41);
  display.print("|");
  display.setCursor(60, 38);
  display.print("|");
  display.setCursor(60, 53);
  display.print("|");
  display.setCursor(60, 47);
  display.print("|");
  display.setCursor(60, 55);
  display.print("|");
  
  // Right vertical lines
  display.setCursor(122, 11);
  display.print("|");
  display.setCursor(122, 8);
  display.print("|");
  display.setCursor(122, 21);
  display.print("|");
  display.setCursor(122, 18);
  display.print("|");
  display.setCursor(122, 31);
  display.print("|");
  display.setCursor(122, 28);
  display.print("|");
  display.setCursor(122, 41);
  display.print("|");
  display.setCursor(122, 38);
  display.print("|");
  display.setCursor(122, 53);
  display.print("|");
  display.setCursor(122, 47);
  display.print("|");
  display.setCursor(122, 55);
  display.print("|");

  // Text & data fields
  display.setCursor(5, 11);
  display.print("Input: ");
  display.setCursor(5, 21);
  display.print(loadvoltage_in);
  display.setCursor(49, 21);
  display.print("V");
  display.setCursor(5, 31);
  display.print(current_mA_in);
  display.setCursor(49, 31);
  display.print("mA");
  display.setCursor(5, 41);
  display.print(power_mW_in);
  display.setCursor(49, 41);
  display.print("mW");
  display.setCursor(67, 11);
  display.print("Output: ");
  display.setCursor(67, 21);
  display.print(loadvoltage_out);
  display.setCursor(111, 21);
  display.print("V");
  display.setCursor(67, 31);
  display.print(current_mA_out);
  display.setCursor(111, 31);
  display.print("mA");
  display.setCursor(67, 41);
  display.print(power_mW_out);
  display.setCursor(111, 41);
  display.print("mW");
  display.display();
  
}
