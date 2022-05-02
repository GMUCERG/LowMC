library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_matrix_mult is
	port(
		clk      : in  std_logic;
		key_a      : in  std_logic_vector(128 - 1 downto 0);
		key_b      : in  std_logic_vector(128 - 1 downto 0);
		state_a    : in  std_logic_vector(128 - 1 downto 0);
		state_b    : in  std_logic_vector(128 - 1 downto 0);
		sel_SK   : in  std_logic;
		sel_do   : in  std_logic;
		en_sipo  : in  std_logic;
		KL_addr1 : in  std_logic_vector(12 - 1 downto 0);
		KL_addr2 : in  std_logic_vector(11 - 1 downto 0);
		C_data   : out std_logic_vector(128 - 1 downto 0);
		dout_a     : out std_logic_vector(128 - 1 downto 0);
		dout_b     : out std_logic_vector(128 - 1 downto 0)
	);
end entity pr_matrix_mult;

architecture RTL of pr_matrix_mult is
	signal ROM_1_doA, ROM_1_doB   : std_logic_vector(128 - 1 downto 0);
	signal ROM_2_doA, ROM_2_doB   : std_logic_vector(128 - 1 downto 0);
	signal KL_addr1_B : std_logic_vector(12 - 1 downto 0);
	signal KL_addr2_B : std_logic_vector(11 - 1 downto 0);
	signal doA, doB               : std_logic_vector(128 - 1 downto 0);
	
	
	signal from_and_1_a, from_and_2_a : std_logic_vector(128 - 1 downto 0);
	signal from_and_1_b, from_and_2_b : std_logic_vector(128 - 1 downto 0);
	
	signal parity_1_a, parity_2_a     : std_logic;
	signal parity_1_b, parity_2_b     : std_logic;
	
	signal sipo_1_a, sipo_2_a         : std_logic_vector(64 - 1 downto 0);
	signal sipo_1_b, sipo_2_b         : std_logic_vector(64 - 1 downto 0);
	
	signal to_and_a, to_and_b                 : std_logic_vector(128 - 1 downto 0);

begin
	to_and_a <= key_a when sel_SK = '0' else state_a;
	to_and_b <= key_b when sel_SK = '0' else state_b;
	
	doA    <= ROM_1_doA when sel_do = '0' else ROM_2_doA;
	doB    <= ROM_1_doB when sel_do = '0' else ROM_2_doB;
	KL_addr1_B <= KL_addr1 or "000001000000";
	KL_addr2_B <= KL_addr2 or "00001000000";
	
	C_data <= doA;

	ROM1 : entity work.dual_port_ROM
		generic map(
			FILENAME  => "ROM_contents/MM_KLC_matrix1.txt",
			ROM_DEPTH => 2**12
		)
		port map(
			clk  => clk,
			adda => KL_addr1,
			addb => KL_addr1_B,
			doa  => ROM_1_doA,
			dob  => ROM_1_doB
		);
		
	ROM2 : entity work.dual_port_ROM
		generic map(
			FILENAME  => "ROM_contents/MM_KLC_matrix2.txt",
			ROM_DEPTH => 2**11
		)
		port map(
			clk  => clk,
			adda => KL_addr2,
			addb => KL_addr2_B,
			doa  => ROM_2_doA,
			dob  => ROM_2_doB
		);

	from_and_1_a <= doA and to_and_a;
	from_and_1_b <= doA and to_and_b;
	from_and_2_a <= doB and to_and_a;
	from_and_2_b <= doB and to_and_b;

	parity_1_a <= xor from_and_1_a;
	parity_1_b <= xor from_and_1_b;
	
	parity_2_a <= xor from_and_2_a;
	parity_2_b <= xor from_and_2_b;

	process(clk)
	begin
		if rising_edge(clk) then
			if en_sipo = '1' then
				sipo_1_a <= sipo_1_a(64 - 2 downto 0) & parity_1_a;
				sipo_1_b <= sipo_1_b(64 - 2 downto 0) & parity_1_b;
				
				sipo_2_a <= sipo_2_a(64 - 2 downto 0) & parity_2_a;
				sipo_2_b <= sipo_2_b(64 - 2 downto 0) & parity_2_b;
			end if;
		end if;
	end process;

	dout_a <= sipo_1_a & sipo_2_a;
	dout_b <= sipo_1_b & sipo_2_b;

end architecture RTL;
