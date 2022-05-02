library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity pr_LowMC_tb is
end entity pr_LowMC_tb;

architecture RTL of pr_LowMC_tb is
	--Signal Declaration
	signal clk   : std_logic := '1';
	signal rst   : std_logic := '1';
	signal go    : std_logic := '0';
	signal ready : std_logic;

	signal k    : std_logic_vector(128 - 1 downto 0) := x"29BEE1D65249F1E9B3DB873E240D0647";
	signal k_a  : std_logic_vector(128 - 1 downto 0) := x"33333333333333333333333333333333";
	signal k_b  : std_logic_vector(128 - 1 downto 0) := k xor k_a;
	signal en_k : std_logic                          := '0';

	signal pt             : std_logic_vector(128 - 1 downto 0) := x"23846CAE90F1BBEBA63C0C995E1CB7DE";
	signal pt_a           : std_logic_vector(128 - 1 downto 0) := x"22222222222222222222222222222222";
	signal pt_b           : std_logic_vector(128 - 1 downto 0) := pt xor pt_a;
	signal en_pt          : std_logic                          := '0';
	signal ct, ct_a, ct_b : std_logic_vector(128 - 1 downto 0);

	signal t : time;

	signal seed         : std_logic_vector(128 - 1 downto 0) := x"22222222222222222222222222222222";
	signal reseed       : std_logic                          := '0';
	signal reseed_ack   : std_logic;
	constant clk_period : time                               := 10 ns;

	signal ciphertext : std_logic_vector(128 - 1 downto 0) := x"B1BC4CAE191BD9FE49CE297BDAE1C2C7";
begin
	ct <= ct_a xor ct_b;

	DUT : entity work.pr_lowmc_top
		port map(
			seed         => seed,
			reseed       => reseed,
			clk          => clk,
			rst          => rst,
			pt_a         => pt_a,
			pt_b         => pt_b,
			k_a          => k_a,
			k_b          => k_b,
			go           => go,
			done        => ready,
			ciphertext_a => ct_a,
			ciphertext_b => ct_b
		);
	clk <= not clk after clk_period / 2;
	rst <= '0' after 2 * clk_period;

	process
	begin
		wait for 2.5 * clk_period;
		en_k  <= '1';
		en_pt <= '1';
		reseed <= '1';
		wait for clk_period;
		en_k  <= '0';
		en_pt <= '0';
		reseed <= '0';
		go    <= '1';
		wait for clk_period;
		go    <= '0';
		wait;
	end process;

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

end architecture RTL;
