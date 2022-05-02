library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity matrix_mult is
	port(
		clk      : in  std_logic;
		key      : in  std_logic_vector(128 - 1 downto 0);
		state    : in  std_logic_vector(128 - 1 downto 0);
		sel_SK   : in  std_logic;
		sel_do   : in  std_logic;
		en_sipo  : in  std_logic;
		KL_addr1 : in  std_logic_vector(12 - 1 downto 0);
		KL_addr2 : in  std_logic_vector(11 - 1 downto 0);
		C_data   : out std_logic_vector(128 - 1 downto 0);
		dout     : out std_logic_vector(128 - 1 downto 0)
	);
end entity matrix_mult;

architecture RTL of matrix_mult is
	signal ROM_1_doA, ROM_1_doB   : std_logic_vector(128 - 1 downto 0);
	signal ROM_2_doA, ROM_2_doB   : std_logic_vector(128 - 1 downto 0);
	signal doA, doB               : std_logic_vector(128 - 1 downto 0);
	signal from_and_1, from_and_2 : std_logic_vector(128 - 1 downto 0);
	signal parity_1, parity_2     : std_logic;
	signal sipo_1, sipo_2         : std_logic_vector(64 - 1 downto 0);
	signal to_and                 : std_logic_vector(128 - 1 downto 0);

	signal KL_addr1_B : std_logic_vector(12 - 1 downto 0);
	signal KL_addr2_B : std_logic_vector(11 - 1 downto 0);
begin
	to_and <= key when sel_SK = '0' else state;
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

	from_and_1 <= doA and to_and;
	from_and_2 <= doB and to_and;

	parity_1 <= xor from_and_1;
	parity_2 <= xor from_and_2;

	process(clk)
	begin
		if rising_edge(clk) then
			if en_sipo = '1' then
				sipo_1 <= sipo_1(64 - 2 downto 0) & parity_1;
				sipo_2 <= sipo_2(64 - 2 downto 0) & parity_2;
			end if;
		end if;
	end process;

	dout <= sipo_1 & sipo_2;

end architecture RTL;
