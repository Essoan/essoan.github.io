----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.11.2022 16:19:13
-- Design Name: 
-- Module Name: temp_update_clock - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity temp_update_clock is
    Port ( clk              :   in  STD_LOGIC;
           upd_tmp_clk   :   out std_logic   :=  '0' );
end temp_update_clock;

architecture Behavioral of temp_update_clock is

signal teller   :   integer   :=     0  ;
signal tmp_clk  :   std_logic :=    '0' ;

begin
process (clk, teller)
    begin
 
    if (clk'event and clk='1') then 
        if  teller  =   10000000   then
            teller  <=   0;
        else
            teller <= teller  + 1;
            tmp_clk    <=  not tmp_clk;
        end if;
    end if;         
                                                                
end process;

upd_tmp_clk  <=  tmp_clk ;

end Behavioral;
