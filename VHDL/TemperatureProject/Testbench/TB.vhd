----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.11.2022 22:25:23
-- Design Name: 
-- Module Name: i2c_TB - Behavioral
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

----------------------------------------------------------------------------------
-- This testbench only have a basic program. The reason for that is because we 
-- decided to select our waveforms while doing the simulations in Vivado.
-- The signals in our project are all present in the simulation by running
-- only this code.

-- This was done to reduce overhead due to time constraints.
----------------------------------------------------------------------------------

entity i2c_TB is
--  Port ( );
end i2c_TB;

architecture Behavioral of i2c_TB is

signal clk, reset :std_logic :='0';


begin

clock : process
    begin
    clk <= not clk;
    wait for 5 ns;
end process;
    


uut: entity work.top(Behavioral)
    port map (clk => clk, reset =>reset );


end Behavioral;
