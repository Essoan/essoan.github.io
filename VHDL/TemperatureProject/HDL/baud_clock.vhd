----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.11.2022 20:49:27
-- Design Name: 
-- Module Name: baud_clock - Behavioral
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

entity baud_clock is
    Port (  clk         :   in  std_logic;
            baud_clk    :   out std_logic   
            );
end baud_clock;

architecture Behavioral of baud_clock is

signal baud_gen : std_logic;

begin

process(clk)

--  Below is a few examples of the baud clock calculations  ---------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--  variable baud_count :   integer range 0 to 325      --  9600 baud rate (@ 050MHz) :   ( 050 * 10^6 ) / ( 9600 * 16 )  =     325

    variable baud_count :   integer range 0 to 1302;    --  4800 baud rate (@ 100MHz) :   ( 100 * 10^6 ) / ( 4800 * 16 )  =    1302

--  variable baud_count :   integer range 0 to 651;     --  9600 baud rate (@ 100MHz) :   ( 100 * 10^6 ) / ( 9600 * 16 )  =     651

begin

if rising_edge(clk)     then    
        if baud_count   =   1302    then
            baud_gen    <=  '1' ;
            baud_count  :=  0   ;
        else
            baud_count  :=  baud_count + 1  ;
            baud_gen    <=  '0' ;
        end if;
 end if;
 end process;

baud_clk    <=  baud_gen    ;

end Behavioral;
