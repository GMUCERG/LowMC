library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_LowMC_top is
	generic(U : integer := 16);
	port(
		clk                        : in  std_logic;
		rst                        : in  std_logic;
		seed                       : in  std_logic_vector(128 - 1 downto 0);
		reseed                     : in  std_logic;
		reseed_ack                 : out std_logic;
		pt_a, pt_b                 : in  std_logic_vector(128 - 1 downto 0);
		en_pt                      : in  std_logic;
		k_a, k_b                   : in  std_logic_vector(128 - 1 downto 0);
		en_k                       : in  std_logic;
		go                         : in  std_logic;
		ready                      : out std_logic;
		ciphertext_a, ciphertext_b : out std_logic_vector(128 - 1 downto 0)
	);
end entity pr_LowMC_top;

architecture RTL of pr_LowMC_top is
	signal plaintext_a, key_a : std_logic_vector(128 - 1 downto 0);
	signal plaintext_b, key_b : std_logic_vector(128 - 1 downto 0);
	signal sel_SK             : std_logic;
	signal en_sipo            : std_logic;
	signal KL_addra           : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal KL_addrb           : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal sel_SP             : std_logic;
	signal sel_to_state       : std_logic_vector(2 - 1 downto 0);
	signal en_s               : std_logic;
	signal en_c               : std_logic;
	signal en_prng            : std_logic;
	signal random_bits        : std_logic_vector(128 - 1 downto 0);
	signal triv_out, triv_reg : std_logic_vector(64-1 downto 0);
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if en_pt = '1' then
				plaintext_a <= pt_a;
				plaintext_b <= pt_b;
			end if;

			if en_k = '1' then
				key_a <= k_a;
				key_b <= k_b;
			end if;
		end if;
	end process;

	gen_datapath : entity work.pr_datapath
		generic map(
			U => U
		)
		port map(
			random_bits  => random_bits(90-1 downto 0),
			clk          => clk,
			key_a        => key_a,
			key_b        => key_b,
			plaintext_a  => plaintext_a,
			plaintext_b  => plaintext_b,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addra     => KL_addra,
			KL_addrb     => KL_addrb,
			sel_SP       => sel_SP,
			sel_to_state => sel_to_state,
			en_s         => en_s,
			en_c         => en_c,
			ciphertext_a => ciphertext_a,
			ciphertext_b => ciphertext_b
		);
	gen_controller : entity work.controller
		generic map(
			U => U
		)
		port map(
			en_prng      => en_prng,
			clk          => clk,
			rst          => rst,
			go           => go,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addra     => KL_addra,
			KL_addrb     => KL_addrb,
			sel_SP       => sel_SP,
			sel_to_state => sel_to_state,
			en_s         => en_s,
			en_c         => en_c,
			ready        => ready
		);
	gen_prng: entity work.prng_trivium_enhanced
		generic map(
			N => 1
		)
		port map(
			clk        => clk,
			rst        => rst,
			en_prng    => en_prng,
			seed       => seed,
			reseed     => reseed,
			reseed_ack => reseed_ack,
			rdi_data   => triv_out,
			rdi_ready  => '1',
			rdi_valid  => open
		);
	process(clk)
	begin
		if rising_edge(clk) then
			triv_reg <= triv_out;
		end if;
	end process;
	random_bits <= triv_out & triv_reg;

end architecture RTL;
