library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity datapath is
	generic(
		U : integer := 1
	);
	port(
		clk          : in  std_logic;
		key          :     std_logic_vector(128 - 1 downto 0);
		plaintext    :     std_logic_vector(128 - 1 downto 0);
		sel_SK       : in  std_logic;
		en_sipo      : in  std_logic;
		KL_addra     : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		KL_addrb     : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		sel_SP       : in  std_logic;
		sel_to_state : in  std_logic_vector(2 - 1 downto 0);
		en_s, en_c   : in  std_logic;
		ciphertext   : out std_logic_vector(128 - 1 downto 0)
	);
end entity datapath;

architecture RTL of datapath is
	signal state, to_state            : std_logic_vector(128 - 1 downto 0);
	signal C_data                     : std_logic_vector(128 - 1 downto 0);
	signal from_mat_mult              : std_logic_vector(128 - 1 downto 0);
	signal to_xor, to_sbox, from_sbox : std_logic_vector(128 - 1 downto 0);
begin

	gen_matrix_mult : entity work.matrix_mult
		generic map(
			U => U
		)
		port map(
			clk      => clk,
			key      => key,
			state    => state,
			sel_SK   => sel_SK,
			en_sipo  => en_sipo,
			KL_addra => KL_addra,
			KL_addrb => KL_addrb,
			C_data   => C_data,
			dout     => from_mat_mult
		);

	process(clk)
	begin
		if rising_edge(clk) then
			if en_s = '1' then
				state <= to_state;
			end if;
--			if en_c = '1' then
--				ciphertext <= state;
--			end if;
		end if;
	end process;
	
	ciphertext <= state;

	to_xor  <= state when sel_SP = '1' else plaintext;
	to_sbox <= to_xor xor from_mat_mult;
	
	SBOXES_GEN : for i in 0 to 9 generate
		sbox: entity work.s_box
			port map(
				a  => to_sbox(98+3*i),
				b  => to_sbox(98+3*i+1),
				c  => to_sbox(98+3*i+2),
				o1 => from_sbox(98+3*i),
				o2 => from_sbox(98+3*i+1),
				o3 => from_sbox(98+3*i+2)
			);
	end generate;
	
	from_sbox(97 downto 0) <= to_sbox(97 downto 0);

	with sel_to_state select to_state <=
		C_data xor from_mat_mult when "00",
		from_sbox when "01",
		to_sbox	when others;
	

end architecture RTL;
