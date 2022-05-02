library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity LOWMC_tb is
end LOWMC_tb;

architecture arch of LOWMC_tb is
	--Signal Decleration
	signal clk      : std_logic := '1';
	signal rst      : std_logic := '1';
	signal go       : std_logic := '0';
	signal ready    : std_logic;
	signal k      : STD_LOGIC_VECTOR(128 - 1 downto 0);
	signal en_k   : std_logic := '0';
	signal pt       : STD_LOGIC_VECTOR(128 - 1 downto 0);
	signal en_pt    : std_logic := '0';
	signal ct  : STD_LOGIC_VECTOR(128 - 1 downto 0);

	signal t : time;

	constant clk_period : time := 10 ns;

	signal ciphertext : std_logic_vector(128 - 1 downto 0) := x"B1BC4CAE191BD9FE49CE297BDAE1C2C7";
begin

	--component instantiation
	DUT : entity work.LowMC_top(OPT_ADDR)
		port map(
			clk        => clk,
			rst        => rst,
			pt         => pt,
			k          => k,
			go         => go,
			done      => ready,
			ciphertext => ct
		);

	clk <= not clk after clk_period / 2;
	rst <= '0' after 2 * clk_period;

	process
	begin
		wait for 2.5 * clk_period;
		en_k <= '1';
		en_pt <= '1';
		wait for clk_period;
		en_k <= '0';
		en_pt <= '0';
		wait for clk_period;
		go <= '1';
		wait for clk_period;
		go <= '0';
		wait;
	end process;

	pt <= x"23846CAE90F1BBEBA63C0C995E1CB7DE";
	k <= x"29BEE1D65249F1E9B3DB873E240D0647";

	process
		variable debug_line : line;
	begin
		wait for 2 * clk_period;
		wait on ready;
		wait for clk_period;
		write(debug_line, string'("Simulation time is:"));
		write(debug_line, t'image(now));
		writeline(output, debug_line);

		report "simulation completed!"
		severity FAILURE;
	end process;

end arch;
