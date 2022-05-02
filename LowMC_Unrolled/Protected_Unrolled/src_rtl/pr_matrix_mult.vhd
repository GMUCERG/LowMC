library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_matrix_mult is
	generic(
		U : integer := 1
	);
	port(
		clk      : in  std_logic;
		key_a    : in  std_logic_vector(128 - 1 downto 0);
		key_b    : in  std_logic_vector(128 - 1 downto 0);
		state_a  : in  std_logic_vector(128 - 1 downto 0);
		state_b  : in  std_logic_vector(128 - 1 downto 0);
		sel_SK   : in  std_logic;
		en_sipo  : in  std_logic;
		KL_addra : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		KL_addrb : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		C_data   : out std_logic_vector(128 - 1 downto 0);
		dout_a   : out std_logic_vector(128 - 1 downto 0);
		dout_b   : out std_logic_vector(128 - 1 downto 0)
	);
end entity pr_matrix_mult;

architecture RTL of pr_matrix_mult is
	type arr_128 is array (U - 1 downto 0) of std_logic_vector(128 - 1 downto 0);
	type arr_sipo is array (U - 1 downto 0) of std_logic_vector(128 / (2 * U) - 1 downto 0);
	signal doA, doB                   : arr_128;
	signal from_and_1_a, from_and_2_a : arr_128;
	signal from_and_1_b, from_and_2_b : arr_128;

	signal parity_1_a, parity_2_a : std_logic_vector(U - 1 downto 0);
	signal parity_1_b, parity_2_b : std_logic_vector(U - 1 downto 0);

	signal sipo_1_a, sipo_2_a : arr_sipo;
	signal sipo_1_b, sipo_2_b : arr_sipo;

	signal to_and_a, to_and_b : std_logic_vector(128 - 1 downto 0);
begin
	to_and_a <= key_a when sel_SK = '0' else state_a;
	to_and_b <= key_b when sel_SK = '0' else state_b;
	C_data <= doA(0);

	gen_mult : for i in 0 to U - 1 generate
		ROM : entity work.dual_port_ROM
			generic map(
				U       => U,
				ROM_NUM => i
			)
			port map(
				clk  => clk,
				adda => KL_addra,
				addb => KL_addrb,
				doa  => doA(i),
				dob  => doB(i)
			);
		from_and_1_a(i) <= doA(i) and to_and_a;
		from_and_2_a(i) <= doB(i) and to_and_a;
		
		from_and_1_b(i) <= doA(i) and to_and_b;
		from_and_2_b(i) <= doB(i) and to_and_b;

		parity_1_a(i) <= xor from_and_1_a(i);
		parity_2_a(i) <= xor from_and_2_a(i);
		
		parity_1_b(i) <= xor from_and_1_b(i);
		parity_2_b(i) <= xor from_and_2_b(i);

		process(clk)
		begin
			if rising_edge(clk) then
				if en_sipo = '1' then
					sipo_1_a(i) <= sipo_1_a(i)(128 / (2 * U) - 2 downto 0) & parity_1_a(i);
					sipo_2_a(i) <= sipo_2_a(i)(128 / (2 * U) - 2 downto 0) & parity_2_a(i);
					
					sipo_1_b(i) <= sipo_1_b(i)(128 / (2 * U) - 2 downto 0) & parity_1_b(i);
					sipo_2_b(i) <= sipo_2_b(i)(128 / (2 * U) - 2 downto 0) & parity_2_b(i);
				end if;
			end if;
		end process;

		dout_a((128/U)*(U-i) -1 downto (128/U)*(U-i-1)) <= sipo_1_a(i) & sipo_2_a(i);
		dout_b((128/U)*(U-i) -1 downto (128/U)*(U-i-1)) <= sipo_1_b(i) & sipo_2_b(i);
	end generate gen_mult;

end architecture RTL;
