library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity pr_LowMC_top_FOBOS_tb is
end entity pr_LowMC_top_FOBOS_tb;

architecture arch of pr_LowMC_top_FOBOS_tb is
	constant U: integer := 4;
	signal clk       : STD_LOGIC := '1';
	signal rst, rstn : STD_LOGIC := '1';
	signal t : time;
	constant clk_period : time := 10 ns;
	
	signal pt   : std_logic_vector(128 - 1 downto 0) := x"23846CAE90F1BBEBA63C0C995E1CB7DE";
	signal pt1  : std_logic_vector(128 - 1 downto 0) := x"22222222222222222222222222222222";
	signal key  : std_logic_vector(128 - 1 downto 0) := x"29BEE1D65249F1E9B3DB873E240D0647";
	signal key1 : std_logic_vector(128 - 1 downto 0) := x"33333333333333333333333333333333";
	--	signal pt2, key2 : std_logic_vector(128 - 1 downto 0);
	signal seed : std_logic_vector(128 - 1 downto 0) := x"22222222222222222222222222222222";
	
	signal ciphertext : std_logic_vector(128 - 1 downto 0) := x"B1BC4CAE191BD9FE49CE297BDAE1C2C7";
	
	signal pr_pdi_fifo_write              : std_logic;
	signal pr_pdi_ready                   : std_logic;
	signal pr_pdi_empty, not_pr_pdi_empty : std_logic;
	signal pr_sdi_fifo_write              : std_logic;
	signal pr_sdi_ready                   : std_logic;
	signal pr_sdi_empty, not_pr_sdi_empty : std_logic;
	signal pr_rdi_fifo_write              : std_logic;
	signal pr_rdi_ready                   : std_logic;
	signal pr_rdi_empty, not_pr_rdi_empty : std_logic;
	signal pr_do_data                     : std_logic_vector(128 - 1 downto 0);
	signal do_fifo_data                   : std_logic_vector(128 - 1 downto 0);
	signal do_fifo_full, not_do_fifo_full : std_logic;
	signal pdi_fifo_data                  : std_logic_vector(128 - 1 downto 0);
	signal pr_pdi_data                    : std_logic_vector(128 - 1 downto 0);
	signal sdi_fifo_data                  : std_logic_vector(128 - 1 downto 0);
	signal pr_sdi_data                    : std_logic_vector(128 - 1 downto 0);
	signal rdi_fifo_data                  : std_logic_vector(128 - 1 downto 0);
	signal pr_rdi_data                    : std_logic_vector(128 - 1 downto 0);
	signal pr_do_valid                    : STD_LOGIC;
	signal not_do_fifo_empty              : std_logic;
	signal do_fifo_empty                  : std_logic;
begin
	
	clk  <= not clk after clk_period / 2;
	rst  <= '0' after 2 * clk_period;
	rstn <= not rst;
	
	-- Protected component verification
	pdi_fifo : entity work.fifo
		generic map(
			G_LOG2DEPTH => 4,
			G_W         => 128,
			G_ODELAY    => False
		)
		port map(
			clk          => clk,
			rstn         => rstn,
			write        => pr_pdi_fifo_write,
			read         => pr_pdi_ready,
			di_data      => pdi_fifo_data,
			do_data      => pr_pdi_data,
			almost_full  => open,
			almost_empty => open,
			full         => open,
			empty        => pr_pdi_empty
		);
	sdi_fifo : entity work.fifo
		generic map(
			G_LOG2DEPTH => 4,
			G_W         => 128,
			G_ODELAY    => False
		)
		port map(
			clk          => clk,
			rstn         => rstn,
			write        => pr_sdi_fifo_write,
			read         => pr_sdi_ready,
			di_data      => sdi_fifo_data,
			do_data      => pr_sdi_data,
			almost_full  => open,
			almost_empty => open,
			full         => open,
			empty        => pr_sdi_empty
		);

	rdi_fifo : entity work.fifo
		generic map(
			G_LOG2DEPTH => 4,
			G_W         => 128,
			G_ODELAY    => False
		)
		port map(
			clk          => clk,
			rstn         => rstn,
			write        => pr_rdi_fifo_write,
			read         => pr_rdi_ready,
			di_data      => rdi_fifo_data,
			do_data      => pr_rdi_data,
			almost_full  => open,
			almost_empty => open,
			full         => open,
			empty        => pr_rdi_empty
		);

	do_fifo : entity work.fifo
		generic map(
			G_LOG2DEPTH => 4,
			G_W         => 128,
			G_ODELAY    => False
		)
		port map(
			clk          => clk,
			rstn         => rstn,
			write        => pr_do_valid,
			read         => not_do_fifo_empty,
			di_data      => pr_do_data,
			do_data      => do_fifo_data,
			almost_full  => open,
			almost_empty => open,
			full         => do_fifo_full,
			empty        => do_fifo_empty
		);
	not_do_fifo_empty <= not do_fifo_empty;

	protected_LOWMC : entity work.pr_LowMC_top_FOBOS
		port map(
			clk       => clk,
			rst       => rst,
			pdi_data  => pr_pdi_data,
			pdi_valid => not_pr_pdi_empty,
			pdi_ready => pr_pdi_ready,
			sdi_data  => pr_sdi_data,
			sdi_valid => not_pr_sdi_empty,
			sdi_ready => pr_sdi_ready,
			rdi_data  => pr_rdi_data,
			rdi_valid => not_pr_rdi_empty,
			rdi_ready => pr_rdi_ready,
			do_data   => pr_do_data,
			do_valid  => pr_do_valid,
			do_ready  => not_do_fifo_full
		);
		

	not_pr_pdi_empty <= not pr_pdi_empty;
	not_pr_sdi_empty <= not pr_sdi_empty;
	not_pr_rdi_empty <= not pr_rdi_empty;
	not_do_fifo_full <= not do_fifo_full;

	process
	begin
		wait for 2.5 * clk_period;
		pdi_fifo_data     <= pt1;
		sdi_fifo_data     <= key1;
		rdi_fifo_data     <= seed;
		pr_pdi_fifo_write <= '1';
		pr_sdi_fifo_write <= '1';
		pr_rdi_fifo_write <= '1';
		wait for clk_period;
		pdi_fifo_data     <= pt xor pt1;
		sdi_fifo_data     <= key xor key1;
        rdi_fifo_data     <= seed;
		pr_pdi_fifo_write <= '1';
		pr_sdi_fifo_write <= '1';
		pr_rdi_fifo_write <= '1';
		wait for clk_period;
		pdi_fifo_data     <= pt1;
		sdi_fifo_data     <= key1;
		rdi_fifo_data     <= seed;
		pr_pdi_fifo_write <= '1';
		pr_sdi_fifo_write <= '1';
		pr_rdi_fifo_write <= '1';
		wait for clk_period;
		pdi_fifo_data     <= pt xor pt1;
		sdi_fifo_data     <= key xor key1;
        rdi_fifo_data     <= seed;
		pr_pdi_fifo_write <= '1';
		pr_sdi_fifo_write <= '1';
		pr_rdi_fifo_write <= '1';
		wait for clk_period;
		pr_pdi_fifo_write <= '0';
		pr_sdi_fifo_write <= '0';
		pr_rdi_fifo_write <= '0';
		wait;
	end process;

	-- Checking process
	process
		variable debug_line : line;
	begin
		wait for 2 * clk_period;
		wait on not_do_fifo_empty;
		wait for clk_period;
		write(debug_line, string'("Simulation time is:"));
		write(debug_line, t'image(now));
		writeline(output, debug_line);

		report "simulation completed";
		-- severity FAILURE;
	end process;

end architecture arch;
