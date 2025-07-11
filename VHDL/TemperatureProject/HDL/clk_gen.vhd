library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity clk_gen is
generic(clk_in_speed, clk_out_speed: integer);
port(
clk_in: in std_logic;
clk_out: out std_logic  );

end entity clk_gen;

architecture Behavioral of clk_gen is

function num_bits(n: natural) return natural is
begin
if n > 0 then
return 1 + num_bits(n / 2);
else
return 1;
end if;
end num_bits;

constant max_counter: natural := clk_in_speed / clk_out_speed / 2;
constant counter_bits: natural := num_bits(max_counter);

signal counter: unsigned(counter_bits - 1 downto 0) := (others => '0');
signal clk_signal: std_logic;

begin
update_counter: process(clk_in)
begin
if clk_in'event and clk_in = '1' then
if counter = max_counter then
counter <= to_unsigned(0, counter_bits);
clk_signal <= not clk_signal;
else
counter <= counter + 1;
end if;
end if;
end process;

clk_out <= clk_signal;

end Behavioral;