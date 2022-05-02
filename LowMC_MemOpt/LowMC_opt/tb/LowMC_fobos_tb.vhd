library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity LW_LowMC_FOBOS_tb is
end entity LW_LowMC_FOBOS_tb;

architecture RTL of LW_LowMC_FOBOS_tb is

	signal clk       : STD_LOGIC := '1';
	signal rst       : STD_LOGIC := '1';
	signal pdi_data  : STD_LOGIC_VECTOR(128 - 1 downto 0);
	signal pdi_valid : STD_LOGIC;
	signal pdi_ready : STD_LOGIC;
	signal sdi_data  : STD_LOGIC_VECTOR(128 - 1 downto 0);
	signal sdi_valid : STD_LOGIC;
	signal sdi_ready : STD_LOGIC;
	signal do_data   : STD_LOGIC_VECTOR(128 - 1 downto 0);
	signal do_valid  : STD_LOGIC;
	signal do_ready  : STD_LOGIC;

	signal t : time;

	constant clk_period : time := 10 ns;

--	signal ciphertext : std_logic_vector(128 - 1 downto 0) := "11110001000011100010111000000110001000001100100111011000000101110111001001001100011101000111010101010001010010001111011110000000";
    signal ciphertext : std_logic_vector(128 - 1 downto 0) := x"B1BC4CAE191BD9FE49CE297BDAE1C2C7";

begin

	--component instantiation
	DUT : entity work.LowMC_top_FOBOS
		port map(
			clk       => clk,
			rst       => rst,
			pdi_data  => pdi_data,
			pdi_valid => pdi_valid,
			pdi_ready => pdi_ready,
			sdi_data  => sdi_data,
			sdi_valid => sdi_valid,
			sdi_ready => sdi_ready,
			do_data   => do_data,
			do_valid  => do_valid,
			do_ready  => do_ready
		);

	clk <= not clk after clk_period / 2;
	rst <= '0' after 2 * clk_period;

	process
	begin
		wait for 2.5 * clk_period;
		pdi_valid <= '1';
		sdi_valid <= '1';
		wait for clk_period;
		pdi_valid <= '0';
		sdi_valid <= '0';
		wait;
	end process;

	do_ready <= '1';
--	pdi_data <= "01011000101101011010110111110001001100101001011110010011111100001100000011010001001010110001100101001110100011100001011011111101";
    pdi_data <= x"23846CAE90F1BBEBA63C0C995E1CB7DE";
--	sdi_data <= "10000101111101100010011100100110000111011010110100010101100101111100010011011101100101001101001000110001001110010001100101110110";
    sdi_data <= x"29BEE1D65249F1E9B3DB873E240D0647";
	process
		variable debug_line : line;
	begin
		wait for 2 * clk_period;
		wait on do_valid;
		wait for clk_period;
		write(debug_line, string'("Simulation time is:"));
		write(debug_line, t'image(now));
		writeline(output, debug_line);

		report "simulation completed"
		severity FAILURE;
	end process;
end architecture RTL;

