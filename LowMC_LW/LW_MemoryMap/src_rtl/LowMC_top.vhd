library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity LowMC_top is
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
	signal KL_addr1       : std_logic_vector(12 - 1 downto 0);
	signal KL_addr2       : std_logic_vector(11 - 1 downto 0);
	signal sel_SP         : std_logic;
	signal sel_to_state   : std_logic_vector(2 - 1 downto 0);
	signal en_s           : std_logic;
	signal sel_do: std_logic;
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
		port map(
			sel_do => sel_do,
			clk          => clk,
			key          => key,
			plaintext    => plaintext,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addr1     => KL_addr1,
			KL_addr2     => KL_addr2,
			sel_SP       => sel_SP,
			sel_to_state => sel_to_state,
			en_s         => en_s,
			en_c         => en_c,
			ciphertext   => ciphertext
		);

	gen_controller : entity work.controller
		port map(
			sel_do => sel_do,
			clk          => clk,
			rst          => rst,
			go           => go,
			sel_SK       => sel_SK,
			en_sipo      => en_sipo,
			KL_addr1     => KL_addr1,
			KL_addr2     => KL_addr2,
			sel_SP       => sel_SP,
			sel_to_state => sel_to_state,
			en_s         => en_s,
			en_c         => en_c,
			ready        => ready
		);

end architecture RTL;
