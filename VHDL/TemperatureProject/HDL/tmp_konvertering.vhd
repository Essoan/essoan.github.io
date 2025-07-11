----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.11.2022 20:24:14
-- Design Name: 
-- Module Name: tmp_konvertering - Behavioral
-- Project Name:  FPGA prosjekt i2c 2022 høst
-- Target Devices:  Nexys A7 50T
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tmp_konvertering is
    Port ( 
    clk : in STD_LOGIC;
    
    bin_in : in std_logic_vector (15 downto 0);
    konv_out :out std_logic_vector (15 downto 0);
    c_out, k_out, f_out : out std_logic_vector(15 downto 0);
    seg0, seg1, seg_minus: out std_logic_vector (7 downto 0);
    fortegn_c, fortegn_f: out std_logic_vector (7 downto 0):= x"20"
    
    );
end tmp_konvertering;

architecture Behavioral of tmp_konvertering is
    signal teller : integer :=0; --0 til 900000000
    signal sel : std_logic_vector (1 downto 0):="00";
     
    -- int for utregning
    signal b_buff : unsigned (12 downto 0);
    signal c_buff : integer :=0;
    signal inn_Uflagg : std_logic_vector (12 downto 0);
    signal celcius: integer :=0;
    signal kelvin: integer :=0;
    signal fahrenheit : integer :=0;
    signal c_sign : signed (15 downto 0);
    signal k_sign : signed (15 downto 0);
    signal f_sign : signed (15 downto 0);
    signal c_usign, k_usign, f_usign :unsigned (15 downto 0);
    signal sign : std_logic:='0';
    signal inngang : std_logic_vector (15 downto 0);
    
   --signal test : 
       
     
begin

    sign <= bin_in(15); -- fortegn for celcius verdi '1' for negative tall

    inn_Uflagg(12 downto 0) <=  bin_in(15 downto 3); -- høyreskifter verdiene for å tilsvare en 13 bits avlesning

    b_buff <= unsigned (inn_Uflagg); -- mellomlagring

    c_buff <= to_integer(b_buff); -- konvertering til int for aritmetiske operasjoner
    
    process (c_buff, celcius, sign) -- sjekker fortegn. Hvis '1' så regnes celcius = (DAC13 verdi - 8192)/16. Ellers er celcius = DAC13/16
    begin
    if (sign ='1') then celcius <= (c_buff-8192)/16;
    else celcius <= (c_buff/16);    
    end if;
    end process;


    --Konvertering til kelvin og fahrenheit
    
    kelvin<=celcius+273;   
    fahrenheit <= ((celcius*9)/5)+32;

    --Konverterer tilbake til unsigned før videre konvertering til std_logic_vector
    c_usign <= to_unsigned(celcius, 16);
    k_usign <= to_unsigned (kelvin, 16);
    f_usign <= to_unsigned(fahrenheit, 16);

    -- prosess for å oppdatere output til syvsegment hvert 3. sekund
process (clk, teller, sel)
    begin   
    if (clk'event and clk='1') then teller <= teller+1;
        if (teller = 300000000) then sel <= "01";
        elsif (teller = 600000000) then sel <="10";
        elsif (teller = 900000000) then sel <="00"; teller <=0;
    end if;
    end if;     
end process;


--------------OUTPUT TIL UART -----------------
process (sign, c_usign)
begin
    c_out (15 downto 13) <="000";
    if sign ='0' then c_out(12 downto 0) <= std_logic_vector (c_usign(12 downto 0));
    else c_out(12 downto 0) <= std_logic_vector(not c_usign(12 downto 0));
    end if;
end process;

process (fahrenheit, f_usign)
begin
    f_out (15 downto 13) <="000";
    if fahrenheit < 0 then f_out(12 downto 0) <= std_logic_vector(not c_usign(12 downto 0));
    else f_out(12 downto 0) <= std_logic_vector (f_usign(12 downto 0));
    end if;
end process;

k_out <= std_logic_vector (k_usign);

------------Fortegn til UART--------------------
process (celcius)
begin
if celcius <0 then fortegn_c <= x"2d";--"00101101";
else fortegn_c <= x"20"; --"00010100";
end if;
end process;

process (fahrenheit)
begin
if fahrenheit <0 then fortegn_f <= x"2d";--"00101101";
else fortegn_f <= x"20"; --"00010100";
end if;
end process;

----- output til BCD konvertering ---------------------

process( sel, sign,c_usign, k_usign,f_usign)
    begin   
    konv_out (15 downto 13) <="000";

     case sel is
     
        when "00" => if sign='0' then konv_out(12 downto 0) <= std_logic_vector (c_usign(12 downto 0));  -- "+" Celcius verdi
                    else konv_out(12 downto 0) <= std_logic_vector (not c_usign(12 downto 0));           -- "-" Celcius verdi
                    end if;                   
        when "01" => konv_out(12 downto 0)<= std_logic_vector(k_usign(12 downto 0));                     -- Kelvin verdi
        when "10" => if sign ='0' then konv_out(12 downto 0) <=  std_logic_vector(f_usign(12 downto 0)); -- "+" Fahrenheit verdi
                     else konv_out (12 downto 0) <= std_logic_vector(not f_usign(12 downto 0));          -- "-" Fahrenheit verdi
                     end if;
        when others =>konv_out(12 downto 0) <= std_logic_vector (c_usign(12 downto 0));
     
    end case;

    case sel is    
        when "00" => seg1 <= "11000110";        --C           
        when "01" => seg1 <= "10001001";        --K
        when "10" => seg1 <= "10001110";        --F
        when others => seg1 <= "11000110";     --C
         
    end case;
    case sel is    
        when "00" => seg0 <= "10011100";   -- grader symbol
        when "01" => seg0 <= "10011100";   
        when "10" => seg0 <= "10011100";
        when others => seg0 <= "11000110";    
    end case;
    
    ------------Fortegn til syvseg"
    case sel is     
        when "00" => if celcius < 0 then seg_minus <= "10111111"; 
                     else seg_minus <= "11111111";
                     end if;  -- grader symbol
        when "01" => seg_minus <= "11111111";   
        when "10" => if fahrenheit < 0 then seg_minus <= "10111111"; 
                     else seg_minus <= "11111111";
                     end if;  -- grader symbol
        when others => seg_minus <= "11000110";    
    end case;
    end process;


end Behavioral;
