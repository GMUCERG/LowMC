library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity LowMC_top is
	generic(U : integer := 16);
	port(
		clk        : in  std_logic;
		rst        : in  std_logic;
		pt         : in  std_logic_vector(128 - 1 downto 0);
		en_pt      : in  std_logic;
		k          : in  std_logic_vector(128 - 1 downto 0);
		en_k       : in  std_logic;
		go         : in  std_logic;
		ready      : out std_logic;
		ciphertext : out std_logic_vector(128 - 1 downto 0)
	);
end entity LowMC_top;

architecture RTL of LowMC_top is
	signal plaintext, key : std_logic_vector(128 - 1 downto 0);
	signal sel_SK         : std_logic;
	signal en_sipo        : std_logic;
	signal KL_addra       : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal KL_addrb       : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal sel_SP         : std_logic;
	signal sel_to_state   : std_logic_vector(2 - 1 downto 0);
	signal en_s           : std_logic;
	signal en_c           : std_logic;
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if en_pt = '1' then
				plaintext <= pt;
			end if;

			if en_k = '1' then
				key <= k;
			end if;
		end if;
	end process;

	gen_datapath : entity work.datapath(RTL)
		generic map(
			U => U
		)
		port map(
			clk          => clk,
			key          => key,
			plaintext    => plaintext,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addra     => KL_addra,
			KL_addrb     => KL_addrb,
			sel_SP       => sel_SP,
			sel_to_state => sel_to_state,
			en_s         => en_s,
			en_c         => en_c,
			ciphertext   => ciphertext
		);

	gen_controller : entity work.controller
		generic map(
			U => U
		)
		port map(
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

end architecture RTL;
