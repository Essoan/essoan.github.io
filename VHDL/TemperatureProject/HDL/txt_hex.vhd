----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.11.2022 15:49:58
-- Design Name: 
-- Module Name: txt_hex - Behavioral
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
use ieee.numeric_std.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity txt_hex is
    Port ( SW   :   in      std_logic_vector(3 downto 0)  ;
           hex  :   out     std_logic_vector(7 downto 0) );
end txt_hex;

architecture Behavioral of txt_hex is


begin
                   
       process(SW)
        
        begin
        
        case SW is
        
        when "0000" => hex <=   x"30"   ;
        when "0001" => hex <=   x"31"   ;
        when "0010" => hex <=   x"32"   ;
        when "0011" => hex <=   x"33"   ;
        when "0100" => hex <=   x"34"   ;
        when "0101" => hex <=   x"35"   ;
        when "0110" => hex <=   x"36"   ;
        when "0111" => hex <=   x"37"   ;
        when "1000" => hex <=   x"38"   ;
        when "1001" => hex <=   x"39"   ;
        
        when "1010" => hex <=   x"41"   ;
        when "1011" => hex <=   x"42"   ;
        when "1100" => hex <=   x"43"   ;
        when "1101" => hex <=   x"44"   ;
        when "1110" => hex <=   x"45"   ;
        when others => hex <=   x"46"   ;
        end case;
        
        
        --reg_ut <= SW;
end process;

end Behavioral;
