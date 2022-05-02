library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pr_LW_LowMC_top is
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
end entity pr_LW_LowMC_top;

architecture RTL of pr_LW_LowMC_top is
	signal plaintext_a, key_a : std_logic_vector(128 - 1 downto 0);
	signal plaintext_b, key_b : std_logic_vector(128 - 1 downto 0);
	signal sel_SK             : std_logic;
	signal en_sipo            : std_logic;
	signal sel_SP             : std_logic;
	signal sel_to_state       : std_logic_vector(2 - 1 downto 0);
	signal en_s               : std_logic;
	signal en_c               : std_logic;
	signal en_prng            : std_logic;
	signal random_bits        : std_logic_vector(128 - 1 downto 0);
	signal triv_out, triv_reg : std_logic_vector(64 - 1 downto 0);
	signal sel_do             : std_logic;
	signal KL_addr1           : std_logic_vector(12 - 1 downto 0);
	signal KL_addr2           : std_logic_vector(11 - 1 downto 0);

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

	gen_prng : entity work.prng_trivium_enhanced
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

	gen_datapath : entity work.pr_datapath
		port map(
			clk          => clk,
			key_a        => key_a,
			key_b        => key_b,
			plaintext_a  => plaintext_a,
			plaintext_b  => plaintext_b,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addr1     => KL_addr1,
			KL_addr2     => KL_addr2,
			sel_SP       => sel_SP,
			sel_to_state => sel_to_state,
			sel_do       => sel_do,
			en_s         => en_s,
			en_c         => en_c,
			random_bits  => random_bits(90 - 1 downto 0),
			ciphertext_a => ciphertext_a,
			ciphertext_b => ciphertext_b
		);
		
	gen_controller: entity work.controller
		port map(
			clk          => clk,
			rst          => rst,
			go           => go,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addr1     => KL_addr1,
			KL_addr2     => KL_addr2,
			sel_SP       => sel_SP,
			sel_do       => sel_do,
			sel_to_state => sel_to_state,
			en_s         => en_s,
			en_c         => en_c,
			en_prng      => en_prng,
			ready        => ready
		);
		

end architecture RTL;
