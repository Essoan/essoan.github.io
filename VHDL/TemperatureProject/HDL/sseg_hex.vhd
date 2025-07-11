----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.09.2022 13:34:35
-- Design Name: 
-- Module Name: hex_sseg - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity hex_sseg is
   Port ( --dp : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR (3 downto 0); --hex
           clk, reset : in std_logic;
           sseg : out STD_LOGIC_VECTOR (7 downto 0) -- tall
         --  AN : out STD_LOGIC_VECTOR (7 downto 0); --segment
         --  clk_ut : out std_logic;
         --  reg_ut : out std_logic_vector (3 downto 0));
         );
           
end hex_sseg;



architecture Behavioral of hex_sseg is

 -- signal clk2 : std_logic;
  --signal SW_tmp : STD_LOGIC_VECTOR (15 downto 0) :="0000000000000000"; --hex
  
 -- signal         sseg :  STD_LOGIC_VECTOR (6 downto 0); -- tall
 -- signal         AN :  STD_LOGIC_VECTOR (7 downto 0); --segment

begin
                      
       process(SW)
        
        begin
        
        case SW is
        
        when "0000" => sseg <= "11000000";
        when "0001" => sseg <= "11111001";
        when "0010" => sseg <= "10100100";
        when "0011" => sseg <= "10110000";
        when "0100" => sseg <= "10011001";
        when "0101" => sseg <= "10010010";
        when "0110" => sseg <= "10000010";
        when "0111" => sseg <= "11111000";
        when "1000" => sseg <= "10000000";
        when "1001" => sseg <= "10011000";
        
        
        when "1010" => sseg <= "10001000";
        when "1011" => sseg <= "10000011";
        when "1100" => sseg <= "11000110";
        when "1101" => sseg <= "10100001";
        when "1110" => sseg <= "10000110";
        when others => sseg <= "10001110";
        end case;
        
        
        --reg_ut <= SW;
end process;


end Behavioral;
