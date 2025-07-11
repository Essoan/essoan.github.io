----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.11.2022 12:12:50
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
  Port ( 
        clk : in std_logic := '0' ;
        reset: in std_logic;
        LED : out std_logic_vector(15 downto 0);
        TMP_SDA : inout std_logic;
        TMP_SCL : inout std_logic;
       -- btn : in std_logic --på bryter
        sseg : out std_logic_vector (7 downto 0);
        AN : out std_logic_vector (7 downto 0);
        tx  :   out std_logic ;
        temperatur_addr : in std_logic_vector(6 downto 0 ):= "1001011"  
        
        );
end top;

architecture Behavioral of top is
    
    
   -- signal adress_kbl: std_logic_vector (6 downto 0) :="0000000";   
     
    signal bin_bcd_wire_in : std_logic_vector(15 downto 0);
    signal temp_wire : std_logic_vector(15 downto 0);
    signal bcd0_w,bcd1_w, bcd2_w, bcd3_w : std_logic_vector(3 downto 0);
    signal sseg0_w, sseg1_w, sseg2_w, sseg3_w : std_logic_vector (7 downto 0);
    signal sseg_info0, sseg_info1:std_logic_vector(7 downto 0);
    signal baud, sec_clk: std_logic ;
    signal hex_0_w, hex_1_w, hex_2_w, hex_3_w     : std_logic_vector (3 downto 0);
    signal hex_4_w, hex_5_w, hex_6_w, hex_7_w     : std_logic_vector (3 downto 0);
    signal hex_8_w, hex_9_w, hex_10_w, hex_11_w   : std_logic_vector (3 downto 0);
    signal c1_in, c2_in, c3_in                    : std_logic_vector (7 downto 0);
    signal k1_in, k2_in, k3_in                    : std_logic_vector (7 downto 0);
    signal f1_in, f2_in, f3_in                    : std_logic_vector (7 downto 0);
    
    signal hex_0        : std_logic_vector (7 downto 0);
    signal hex_1        : std_logic_vector (7 downto 0);
    signal hex_2        : std_logic_vector (7 downto 0);
    signal hex_3        : std_logic_vector (7 downto 0);
    signal hex_4        : std_logic_vector (7 downto 0);
    signal hex_5        : std_logic_vector (7 downto 0);
    signal hex_6        : std_logic_vector (7 downto 0);
    signal hex_7        : std_logic_vector (7 downto 0);
    signal hex_8        : std_logic_vector (7 downto 0);
    
    signal tmp_clk      : std_logic ;
    signal c_out        : std_logic_vector(15 downto 0);
    signal k_out        : std_logic_vector(15 downto 0);
    signal f_out        : std_logic_vector(15 downto 0);
    signal fortegn_c    : std_logic_vector (7 downto 0);
    signal fortegn_f    : std_logic_vector (7 downto 0);
     
    
    
   
   
--    signal celcius : unsigned (15 downto 0):="0000000000000001";
 --   signal konv_c : unsigned (4 downto 0):="10000";
 --   signal konv_kelvin : unsigned (11 downto 0):="000100010001";
 --   signal konv_9 : signed (4 downto 0):= "01001";
 --   signal konv_5: signed (3 downto 0):="0101";
 --   signal konv_32:signed (6 downto 0):="0100000";
  --  signal kelvin: unsigned (15 downto 0):="0000000000000000";
 --   signal fahrenheit: unsigned (19 downto 0):="00000000000000000000";
 --   signal fahrenheit2: unsigned (15 downto 0):="0000000000000000";
    
 --   signal test : integer :=(-4*9)/5;
--    signal test2 : integer :=32;
 --   signal test3: integer :=0;
 --   signal test4 : signed (3 downto 0):="1000";
 --   signal test5 : integer :=0;
    
   -- signal test : unsigned (15 downto 0)
   
      signal ena_w, busy_w, ack_w, sda_w, scl_w, rw_w : std_logic:='0';
      signal addr_w : std_logic_vector(6 downto 0);
      signal data_wr_w, data_rd_w : std_logic_vector (7 downto 0); 
   
    
begin
-- i2c_ena

        tmp: entity work.pmod_temp_sensor_adt7420(behavior)  
           --  generic map (temp_sensor_addr => "1001011" )  
--            port map (clk => clk, reset_n => reset, temperature => temp_wire, scl => scl_w, 
--                       sda => sda_w                                                                            
--             );
             port map (clk => clk, reset_n => reset, temperature => temp_wire, scl => scl_w, 
                       sda => sda_w, i2c_ack_err => ack_w , i2c_ena => ena_w, i2c_addr => addr_w,
                       i2c_rw => rw_w , i2c_data_wr => data_wr_w ,
                       i2c_busy => busy_w , i2c_data_rd => data_rd_w                                
             );
             
             TMP_SDA <= sda_w; TMP_SCL <=scl_w;
             
            i2c: entity work.i2c_master(logic)
--            GENERIC MAP(input_clk => sys_clk_freq, bus_clk => 400_000)
            PORT MAP(clk => clk, reset_n => reset, ena => ena_w, addr => addr_w,
             rw => rw_w, data_wr => data_wr_w, busy => busy_w,
           --  data_rd => i2c_data_rd, ack_error => i2c_ack_err, sda => sda,
            data_rd => data_rd_w, ack_error => ack_w, sda => sda_w,
             scl => scl_w);   
             

        sseg0: entity work.hex_sseg(Behavioral)
         port map (clk => clk,  reset => reset, SW =>bcd0_w,  sseg => sseg0_w);
              
        sseg1: entity work.hex_sseg(Behavioral)
         port map (clk => clk,  reset => reset, SW =>bcd1_w,  sseg => sseg1_w);
          
        sseg2: entity work.hex_sseg(Behavioral)
         port map (clk => clk,  reset => reset, SW =>bcd2_w,  sseg => sseg2_w);
          

         
        disp : entity work. disp_mux(arch)
            port map (clk => clk, reset => reset, in0 => sseg0_w, in1 => sseg1_w, in2 => sseg2_w, in3 => sseg3_w, in4 => sseg_info0, in5=>sseg_info1, an =>AN(7 downto 0) , sseg => sseg);   
           
        tmp_konv:entity work.tmp_konvertering(Behavioral)
           port map(clk=>clk, bin_in=>temp_wire,seg1=>sseg_info1,seg0=>sseg_info0, konv_out => bin_bcd_wire_in, seg_minus => sseg3_w, c_out => c_out, k_out => k_out, f_out => f_out, fortegn_c =>  fortegn_c, fortegn_f => fortegn_f ) ;--, 
            
        bin_bcd_0: entity work.bin2bcd(fum)
            port map (input => bin_bcd_wire_in, ones =>bcd0_w, tens => bcd1_w, hundreds => bcd2_w, thousands => bcd3_w);
            
        bin_bcd_1: entity work.bin2bcd(fum)
            port map (input => c_out, ones => hex_0_w, tens => hex_1_w, hundreds => hex_2_w, thousands => hex_3_w);
            
        bin_bcd_2: entity work.bin2bcd(fum)
            port map (input => k_out, ones => hex_4_w, tens => hex_5_w, hundreds => hex_6_w, thousands => hex_7_w);
            
        bin_bcd_3: entity work.bin2bcd(fum)
            port map (input => f_out, ones => hex_8_w, tens => hex_9_w, hundreds => hex_10_w, thousands => hex_11_w);
      
        baud_gen:   entity  work.baud_clock(Behavioral)
            port    map (   clk => clk, baud_clk    => baud );
        
--        transmitter:    entity  work.transmitter(Behavioral)
--        port    map (   clk =>  baud, reset =>  reset, tx_start => tx_start, s_tick =>  s_tick, din => din, tx_done_tick    =>  tx_done_tick    );

        hex0: entity work.txt_hex(Behavioral)
            port map (SW =>hex_0_w,  hex => c1_in);
              
        hex1: entity work.txt_hex(Behavioral)
            port map (SW =>hex_1_w,  hex => c2_in);
          
        hex2: entity work.txt_hex(Behavioral)
            port map (SW =>hex_2_w,  hex => c3_in);
        
        hex3: entity work.txt_hex(Behavioral)
            port map (SW =>hex_4_w,  hex => k1_in);
              
        hex4: entity work.txt_hex(Behavioral)
            port map (SW =>hex_5_w,  hex => k2_in);
          
        hex5: entity work.txt_hex(Behavioral)
            port map (SW =>hex_6_w,  hex => k3_in);
        
        hex6: entity work.txt_hex(Behavioral)
            port map (SW =>hex_8_w,  hex => f1_in);
              
        hex7: entity work.txt_hex(Behavioral)
            port map (SW =>hex_9_w,  hex => f2_in);
          
        hex8: entity work.txt_hex(Behavioral)
            port map (SW =>hex_10_w,  hex => f3_in);
        
--        tmp_upd:    entity work.temp_update_clock(Behavioral)
--            port    map (   clk => clk, upd_tmp_clk => tmp_clk   );
        
        UART_tx:    entity work.UART_tx(Behavioral)
            port    map (   clk => clk, baud_clk => baud, tx => tx, c1_in => c1_in, c2_in => c2_in, c3_in => c3_in, k1_in => k1_in, k2_in => k2_in, k3_in => k3_in, f1_in => f1_in, f2_in => f2_in, f3_in => f3_in, fortegn_c =>  fortegn_c, fortegn_f => fortegn_f   );
      


end Behavioral;
