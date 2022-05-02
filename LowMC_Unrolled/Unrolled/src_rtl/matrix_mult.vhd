library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity matrix_mult is
	generic(
		U : integer := 1
	);
	port(
		clk      : in  std_logic;
		key      : in  std_logic_vector(128 - 1 downto 0);
		state    : in  std_logic_vector(128 - 1 downto 0);
		
		sel_SK   : in  std_logic;
		en_sipo  : in  std_logic;
		KL_addra : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		KL_addrb : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		
		C_data   : out std_logic_vector(128-1 downto 0);
		dout     : out std_logic_vector(128 - 1 downto 0)
	);
end entity matrix_mult;

architecture RTL of matrix_mult is
	type arr_128 is array (U - 1 downto 0) of std_logic_vector(128 - 1 downto 0);
	type arr_sipo is array (U - 1 downto 0) of std_logic_vector(128 / (2 * U) - 1 downto 0);
	signal doA, doB               : arr_128;
	signal from_and_1, from_and_2 : arr_128;
	signal parity_1, parity_2     : std_logic_vector(U-1 downto 0);
	signal sipo_1, sipo_2           : arr_sipo;
	signal to_and                 : std_logic_vector(128 - 1 downto 0);
begin
	to_and <= key when sel_SK = '0' else state;
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
		from_and_1(i) <= doA(i) and to_and;
		from_and_2(i) <= doB(i) and to_and;

		parity_1(i) <= xor from_and_1(i);
		parity_2(i) <= xor from_and_2(i);

		process(clk)
		begin
			if rising_edge(clk) then
				if en_sipo = '1' then
					sipo_1(i) <= sipo_1(i)(128 / (2 * U) - 2 downto 0) & parity_1(i);
					sipo_2(i) <= sipo_2(i)(128 / (2 * U) - 2 downto 0) & parity_2(i);
				end if;
			end if;
		end process;

		dout((128/U)*(U-i) -1 downto (128/U)*(U-i-1)) <= sipo_1(i) & sipo_2(i);
	end generate gen_mult;

end architecture RTL;
