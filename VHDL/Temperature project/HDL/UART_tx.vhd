----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2022 23:05:31
-- Design Name: 
-- Module Name: UART_tx - Behavioral
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_tx is
    Port ( baud_clk     :   in STD_LOGIC    ;
           clk          :   in  std_logic   ;
           c1_in        :   in  std_logic_vector (7 downto 0);
           c2_in        :   in  std_logic_vector (7 downto 0);
           c3_in        :   in  std_logic_vector (7 downto 0);
           k1_in        :   in  std_logic_vector (7 downto 0);
           k2_in        :   in  std_logic_vector (7 downto 0);
           k3_in        :   in  std_logic_vector (7 downto 0);
           f1_in        :   in  std_logic_vector (7 downto 0);
           f2_in        :   in  std_logic_vector (7 downto 0);
           f3_in        :   in  std_logic_vector (7 downto 0);
           fortegn_c    :   in  std_logic_vector (7 downto 0);
           fortegn_f    :   in  std_logic_vector (7 downto 0);
           tx           :   out STD_LOGIC   );
            
end UART_tx;

architecture Behavioral of UART_tx is

type    arr     is array (1 to 270) of  std_logic_vector (7 downto 0)                ;
type    tarr    is array (1 to 48)   of  std_logic_vector (7 downto 0)               ;


type state is (ready, ready2, ready3, start, start2, start3, stop, stop2, stop3);
signal  present_state   :   state   :=  ready                                        ;
signal  tmp_loc         :   std_logic_vector(7 downto 0)                             ; 
signal  tell            :   integer :=  0                                            ;
signal  parity_chk      :   std_logic_vector (7 downto 0)                            ;
signal  odd_parity_bit  :   std_logic                                                ;
signal  parity_tmp      :   std_logic_vector(5 downto 0)                             ;

signal   i      :   integer :=  0   ;
signal   j      :   integer :=  1   ;
signal   k      :   integer :=  1   ;
signal   l      :   integer :=  1   ;
signal   n      :   integer :=  0   ;

signal init_clr :   integer :=  1   ;


signal t_instructions: tarr ;

constant   data2   :   tarr    :=  t_instructions (1 to 48);
constant   clr     :   std_logic_vector (7 downto 0)    :=  x"0C"   ;

--  Input of the hardcoded header information
---------------------------------------------------------------------------------------------------------------
constant    data    :   arr     :=  ( x"01",x"20",X"48",x"65",x"61",x"64",x"65",x"72",x"20",x"49",x"6E",x"66",x"6F",x"72",x"6D",
                                    x"61",x"74",x"69",x"6F",x"6E",x"3A",x"0d",x"0A",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"0d",x"0A",X"20",X"45",X"4C",X"45",X"2D",X"32",X"38",X"30",X"31",X"20",X"2F",
                                    X"20",X"46",X"50",X"47",X"41",X"20",X"2F",X"20",X"46",X"41",X"4C",X"4C",X"20",X"2D",
                                    X"20",X"32",X"30",X"32",X"32",X"0d",x"0A",X"20",X"43",x"6F",x"75",x"72",x"73",x"65",x"20",
                                    X"50",x"72",x"6F",x"6A",x"65",x"63",x"74",x"20",X"3A",x"20",X"69",x"32",x"63",x"20",
                                    X"54",x"65",x"6D",x"70",x"65",x"72",x"61",x"74",x"75",x"72",x"65",x"0d",x"0A",x"20",X"41",
                                    x"75",x"74",x"68",x"6F",x"72",x"28",x"73",x"29",x"20",x"20",x"20",x"20",x"20",x"20",
                                    x"3A",x"20",X"48",x"61",x"61",x"6B",x"6F",x"6E",x"20",X"53",x"61",x"6E",x"64",x"76",
                                    x"69",x"6B",x"20",x"26",x"20",X"45",x"73",x"70",x"65",x"6E",x"20",X"41",x"6E",x"64",
                                    x"72",x"65",x"73",x"65",x"6E",x"0d",x"0A",x"20",X"47",x"72",x"6F",x"75",x"70",x"20",x"20",
                                    x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"3A",x"20",x"30",x"32",x"0d",x"0A",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",
                                    x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"3D",x"0d",x"0A",x"0A"                            );  
                                    -- static one time output (270 signs, please update number if changed)!                                   
begin

process(clk)
begin

if rising_edge (clk)  then
    if  tell = 100000    then
    
--  These following instructions updates the constant data2 array every milis.
---------------------------------------------------------------------------------------------------------------   
        t_instructions(1 to 16)     <=  ( x"20",X"54",x"65",x"6D",x"70",x"65",x"72",x"61",x"74",x"75",x"72",x"65",x"3A",x"0A",x"0A",x"0d"  );  
        t_instructions(17 to 19)    <=  ( x"02",x"20",x"20" )   ;
        t_instructions(20)          <=  fortegn_c               ;
        t_instructions(21)          <=  c3_in                   ;
        t_instructions(22)          <=  c2_in                   ;
        t_instructions(23)          <=  c1_in                   ;
        t_instructions(24 to 25)    <=  ( x"2A",x"43" )         ;
        t_instructions(26 to 27)    <=  ( x"0A",x"0d" )         ;
        t_instructions(28 to 30)    <=  ( x"20",x"20",x"20" )   ;
        t_instructions(31)          <=  k3_in                   ;
        t_instructions(32)          <=  k2_in                   ;
        t_instructions(33)          <=  k1_in                   ;
        t_instructions(34 to 35)    <=  ( x"2A",x"4B" )         ;
        t_instructions(36 to 37)    <=  ( x"0A",x"0d" )         ;
        t_instructions(38 to 39)    <=  ( x"20",x"20" )         ;
        t_instructions(40)          <=  fortegn_f               ; 
        t_instructions(41)          <=  f3_in                   ;
        t_instructions(42)          <=  f2_in                   ;
        t_instructions(43)          <=  f1_in                   ;
        t_instructions(44 to 45)    <=  ( x"2A",x"46" )         ;
        t_instructions(46 to 48)    <=  ( x"0A",x"0d",x"03" )   ;
---------------------------------------------------------------------------------------------------------------
        tell                        <=  0                       ;
    else                              
        tell                        <=  tell +  1               ;
    end if;      
end if; 
end process;

---------------------------------------------------------------------------------------------------------------
--  The next process updates the terminal output with a baudrate of 4800.
--  We first transmit the header, then the Temperature konstant and the temperature data.
--  The last part is done by building an array where temperature data is included from the 
--  converter. Whether the temperature for celcius and fahrenheit is below zero is also
--  included. The process is designed in three parts, where one part waits for the other
--  then starts upon completion of the previous part.
--  Part 3 is the clearing of the terminal window, and will run after approximately 
--  10 seconds. The process then starts over and present new temperature data.
---------------------------------------------------------------------------------------------------------------
--  first stage   ---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
process(baud_clk)
begin 

-- Part 1  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
 if rising_edge (baud_clk)  then
    if present_state    =   ready   then
        i <= i + 1  ;
        if  i = 8   then
            tx  <=  '0' ;    
            i <=  0    ;
            present_state   <=    start ;
            
        end if;
    end if; 

-- Part 2  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------   
    if present_state    =   start    then      
        i   <=     i + 1;
            tmp_loc   <=  data(j)(7 downto 0);

        if  i = 16 then
                tx  <=  tmp_loc (0);
                parity_chk(0)   <=  tmp_loc(0);
            end if;
            if  i = 32 then
                tx  <=  tmp_loc (1);
                parity_chk(1)   <=  tmp_loc(1);
            end if;
            if  i = 48 then
                tx  <=  tmp_loc (2);
                parity_chk(2)   <=  tmp_loc(2);
            end if;
            if  i = 64 then
                tx  <=  tmp_loc (3);
                parity_chk(3)   <=  tmp_loc(3);
            end if;
            if  i = 80 then
                tx  <=  tmp_loc (4);
                parity_chk(4)   <=  tmp_loc(4);
            end if;
            if  i = 96 then
                tx  <=  tmp_loc (5);
                parity_chk(5)   <=  tmp_loc(5);
            end if;
            if  i = 112 then
                tx  <=  tmp_loc (6);
                parity_chk(6)   <=  tmp_loc(6);
            end if;
            if  i = 128 then
                tx  <=  tmp_loc (7);
                parity_chk(7)   <=  tmp_loc(7);
            end if;
        
        if  i = 144 then
            tx  <=  '1';
        end if;
        
        if  i = 160 then
            tx  <=  '1' ;
        end if;
        
        if  i = 176 then
            parity_tmp(0)   <=  parity_tmp(0)       xor     parity_chk(1)       ;
            parity_tmp(1)   <=  parity_tmp(0)       xor     parity_chk(2)       ;  
            parity_tmp(2)   <=  parity_tmp(1)       xor     parity_chk(3)       ;
            parity_tmp(3)   <=  parity_tmp(2)       xor     parity_chk(4)       ;
            parity_tmp(4)   <=  parity_tmp(3)       xor     parity_chk(5)       ;
            parity_tmp(5)   <=  parity_tmp(4)       xor     parity_chk(6)       ;
        
            odd_parity_bit  <=  not (parity_tmp(5)  xor     parity_chk(7)      );
        end if;
            
        if  i = 192 then
            i <= 0;
            present_state    <=  stop    ;
        end if;
    end if;
    
-- Part 3  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------    
    if present_state    =   stop    then
        if  j   =   270  then
            
            present_state   <=  ready2;
            j   <=  270;
        else
            present_state   <=  ready;    
            j   <=  j   +   1;
        end if;
    end if;

--  second stage   --------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

-- Part 1  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
    if present_state    =   ready2   then
        
        i <= i + 1  ;
        if  i = 8   then
            tx  <=  '0' ;    
            i <=   0   ;
            present_state   <=    start2 ;
        end if;
    end if; 
    
-- Part 2  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------    
   if present_state = start2 then
        i   <=     i + 1;
            tmp_loc   <=  data2(k)(7 downto 0);
        if  i = 16 then
                tx  <=  tmp_loc (0);
                parity_chk(0)   <=  tmp_loc(0);
            end if;
            if  i = 32 then
                tx  <=  tmp_loc (1);
                parity_chk(1)   <=  tmp_loc(1);
            end if;
            if  i = 48 then
                tx  <=  tmp_loc (2);
                parity_chk(2)   <=  tmp_loc(2);
            end if;
            if  i = 64 then
                tx  <=  tmp_loc (3);
                parity_chk(3)   <=  tmp_loc(3);
            end if;
            if  i = 80 then
                tx  <=  tmp_loc (4);
                parity_chk(4)   <=  tmp_loc(4);
            end if;
            if  i = 96 then
                tx  <=  tmp_loc (5);
                parity_chk(5)   <=  tmp_loc(5);
            end if;
            if  i = 112 then
                tx  <=  tmp_loc (6);
                parity_chk(6)   <=  tmp_loc(6);
            end if;
            if  i = 128 then
                tx  <=  tmp_loc (7);
                parity_chk(7)   <=  tmp_loc(7);
            end if;
        if  i = 144 then
            tx  <=  '1';
        end if;
        
        if  i = 160 then
            tx  <=  '1' ;
        end if;
        
        if  i = 176 then
            parity_tmp(0)   <=  parity_tmp(0)       xor     parity_chk(1)       ;
            parity_tmp(1)   <=  parity_tmp(0)       xor     parity_chk(2)       ;  
            parity_tmp(2)   <=  parity_tmp(1)       xor     parity_chk(3)       ;
            parity_tmp(3)   <=  parity_tmp(2)       xor     parity_chk(4)       ;
            parity_tmp(4)   <=  parity_tmp(3)       xor     parity_chk(5)       ;
            parity_tmp(5)   <=  parity_tmp(4)       xor     parity_chk(6)       ;
        
            odd_parity_bit  <=  not (parity_tmp(5)  xor     parity_chk(7)      );
        end if;
            
        if  i = 192 then
            i <= 0;
            present_state    <=  stop2    ;
        end if;
    end if;  
-- Part 3  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
    if present_state    =   stop2    then
        if  j   =   270  then
            if k    =   48  then
                 if     l   =   768000  then
                        present_state   <=  ready3  ;
                        l   <=  1   ;
                 else       
                        present_state   <=  stop2;
                        l   <=  l   +   1;
                end if;    
            else
                present_state   <=  ready2;    
                k   <=  k   +   1;
            end if;
        end if;
    end if;

--  last stage   ----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
 
-- Part 1  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
            if present_state    =   ready3   then
                i <= i + 1  ;
                if  i = 8   then
                    tx  <=  '0' ;    
                    i <=   0   ;
                    present_state   <=    start3 ;
                end if;
            end if; 
            
-- Part 2  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
        if present_state = start3 then
            i   <=     i + 1;
                tmp_loc   <=  clr(7 downto 0);
            if  i = 16 then
                tx  <=  tmp_loc (0);
                parity_chk(0)   <=  tmp_loc(0);
            end if;
            if  i = 32 then
                tx  <=  tmp_loc (1);
                parity_chk(1)   <=  tmp_loc(1);
            end if;
            if  i = 48 then
                tx  <=  tmp_loc (2);
                parity_chk(2)   <=  tmp_loc(2);
            end if;
            if  i = 64 then
                tx  <=  tmp_loc (3);
                parity_chk(3)   <=  tmp_loc(3);
            end if;
            if  i = 80 then
                tx  <=  tmp_loc (4);
                parity_chk(4)   <=  tmp_loc(4);
            end if;
            if  i = 96 then
                tx  <=  tmp_loc (5);
                parity_chk(5)   <=  tmp_loc(5);
            end if;
            if  i = 112 then
                tx  <=  tmp_loc (6);
                parity_chk(6)   <=  tmp_loc(6);
            end if;
            if  i = 128 then
                tx  <=  tmp_loc (7);
                parity_chk(7)   <=  tmp_loc(7);
            end if;
            if  i = 144 then
                tx  <=  '1' ;
            end if;
            
            if  i = 160 then
                tx  <=  '1' ;
            end if;
            
            if  i = 176 then
                parity_tmp(0)   <=  parity_tmp(0)       xor     parity_chk(1)       ;
                parity_tmp(1)   <=  parity_tmp(0)       xor     parity_chk(2)       ;  
                parity_tmp(2)   <=  parity_tmp(1)       xor     parity_chk(3)       ;
                parity_tmp(3)   <=  parity_tmp(2)       xor     parity_chk(4)       ;
                parity_tmp(4)   <=  parity_tmp(3)       xor     parity_chk(5)       ;
                parity_tmp(5)   <=  parity_tmp(4)       xor     parity_chk(6)       ;
        
                odd_parity_bit  <=  not (parity_tmp(5)  xor     parity_chk(7)      );
            end if;
            
            if  i = 192 then
                i <= 0;
                n <= 2;   
                present_state    <=  stop3    ;
            end if;
        end if;  
        
-- Part 3  ----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------    
        if present_state    =   stop3    then
            if  n = 2   then
                n           <=  1   ;
                k           <=  1   ;
                j           <=  1   ; 
                present_state   <=  ready;  
            end if;
        end if;
    end if;
        
end process;         
            
end Behavioral;
