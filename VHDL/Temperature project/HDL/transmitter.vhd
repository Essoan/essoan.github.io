----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.11.2022 21:29:33
-- Design Name: 
-- Module Name: transmitter - Behavioral
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
use ieee.numeric_std.all    ;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity transmitter is
    generic (   DBIT    :    integer :=  8      ;      --  number of databits 
                SB_TICK :    integer :=  16     );     --  number of ticks for the stop bit;
               
    Port (      clk, reset      :   in  STD_LOGIC;
                tx_start        :   in  std_logic;
                s_tick          :   in  std_logic ;
                din             :   in  std_logic_vector (7 downto 0);
                tx_done_tick    :   out std_logic ;
                tx              :   out std_logic 
                
    );

end transmitter;

architecture Behavioral of transmitter is

type    state_type is   (idle, start, data, stop)                       ;
signal  state_reg, state_next   :   state_type                          ;
signal  s_reg, s_next           :   unsigned            (3 downto 0)    ;
signal  n_reg, n_next           :   unsigned            (2 downto 0)    ;
signal  b_reg, b_next           :   std_logic_vector    (7 downto 0)    ;
signal  tx_reg, tx_next         :   std_logic                           ;

begin

--  FSMD State and Data Register
FSMD:   process(clk, reset)
        begin
            if  reset   =   '1'     then
                state_reg   <=  idle;
                s_reg       <=  ( others => '0' );
                n_reg       <=  ( others => '0' );
                b_reg       <=  ( others => '0' );
                tx_reg      <=  '1';
            elsif   (clk'event and clk = '1')   then
                state_reg   <=  state_next;
                s_reg       <=  s_next;
                n_reg       <=  n_next;
                b_reg       <=  b_next;
                tx_reg      <=  tx_next;
            end if;
        end process;

--  Next - State logic and data path functional units / routing.
NXT_ST: process (state_reg, s_reg, n_reg, b_reg, s_tick, tx_reg, tx_start, din)
            begin
                state_next      <=  state_reg   ;
                s_next          <=  s_reg       ;
                n_next          <=  n_reg       ;
                b_next          <=  b_reg       ;
                tx_next         <=  tx_reg      ;
                tx_done_tick    <=  '0'         ;
                
                case    state_reg   is
                    when idle   =>
                        tx_next <=  '1'             ;
                        if  tx_start    =   '1' then
                            state_next  <=  start   ;
                            s_next      <=  (others => '0');
                            b_next      <=  din;
                        end if;
                    when    start   =>
                        tx_next <=  '0' ;
                        if  (s_tick = '1')  then
                            if  s_reg   =   15  then
                                state_next  <=  data            ;
                                s_next      <=  (others =>  '0');
                                b_next      <=  (others =>  '0');
                            else
                                s_next      <=  s_reg   +   1   ;
                            end if;       
                        end if;
                    when    data    =>
                        tx_next <=  b_reg(0)    ;
                        if  (s_tick =   '1')    then
                            if  s_reg   =   15  then
                                s_next  <=  (others =>  '0');
                                b_next  <=  '0' &   b_reg   (7 downto 1)    ;
                                if  n_reg   =   (DBIT - 1 ) then
                                    state_next  <=  stop;
                                else
                                    n_next      <=  n_reg + 1;
                                end if;
                            else
                                s_next  <=  s_reg   +   1   ;
                            end if;
                        end if;
                    when    stop    =>  
                        tx_next <=  '1' ;
                        if  (s_tick =   '1')    then
                            if  s_reg   =   ( SB_TICK - 1 ) then
                                state_next      <=  idle    ;
                                tx_done_tick    <=  '1'     ;
                            else
                                s_next  <=  s_reg   +   1   ;
                            end if;
                        end if;
                    end case;
                end process;
                
            tx  <=  tx_reg;
            
end Behavioral;
