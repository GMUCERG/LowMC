library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_datapath is
	generic(
		U : integer := 1
	);
	port(
		clk                        : in  std_logic;
		key_a, key_b               :     std_logic_vector(128 - 1 downto 0);
		plaintext_a, plaintext_b   :     std_logic_vector(128 - 1 downto 0);
		sel_SK                     : in  std_logic;
		en_sipo                    : in  std_logic;
		KL_addra                   : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		KL_addrb                   : in  std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		sel_SP                     : in  std_logic;
		sel_to_state               : in  std_logic_vector(2 - 1 downto 0);
		en_s, en_c                 : in  std_logic;
		random_bits                : in  std_logic_vector(90 - 1 downto 0);
		ciphertext_a, ciphertext_b : out std_logic_vector(128 - 1 downto 0)
	);
end entity pr_datapath;

architecture RTL of pr_datapath is
	signal state_a, to_state_a              : std_logic_vector(128 - 1 downto 0);
	signal state_b, to_state_b              : std_logic_vector(128 - 1 downto 0);
	signal C_data                           : std_logic_vector(128 - 1 downto 0);
	signal from_mat_mult_a, from_mat_mult_b : std_logic_vector(128 - 1 downto 0);
	signal to_xor_a, to_sbox_a, from_sbox_a : std_logic_vector(128 - 1 downto 0);
	signal to_xor_b, to_sbox_b, from_sbox_b : std_logic_vector(128 - 1 downto 0);
begin

	gen_mat_mult : entity work.pr_matrix_mult
		generic map(
			U => U
		)
		port map(
			clk      => clk,
			key_a    => key_a,
			key_b    => key_b,
			state_a  => state_a,
			state_b  => state_b,
			sel_SK   => sel_SK,
			en_sipo  => en_sipo,
			KL_addra => KL_addra,
			KL_addrb => KL_addrb,
			C_data   => C_data,
			dout_a   => from_mat_mult_a,
			dout_b   => from_mat_mult_b
		);
	process(clk)
	begin
		if rising_edge(clk) then
			if en_s = '1' then
				state_a <= to_state_a;
				state_b <= to_state_b;
			end if;
			--			if en_c = '1' then
			--				ciphertext <= state;
			--			end if;
		end if;
	end process;

	ciphertext_a <= state_a;
	ciphertext_b <= state_b;

	to_xor_a <= state_a when sel_SP = '1' else plaintext_a;
	to_xor_b <= state_b when sel_SP = '1' else plaintext_b;

	to_sbox_a <= to_xor_a xor from_mat_mult_a;
	to_sbox_b <= to_xor_b xor from_mat_mult_b;

	SBOXES_GEN : for i in 0 to 9 generate
		sbox : entity work.sbox_3TI
			port map(
				a_1  => to_sbox_a(98 + 3 * i),
				a_2  => to_sbox_b(98 + 3 * i),
				b_1  => to_sbox_a(98 + 3 * i + 1),
				b_2  => to_sbox_b(98 + 3 * i + 1),
				c_1  => to_sbox_a(98 + 3 * i + 2),
				c_2  => to_sbox_b(98 + 3 * i + 2),
				m    => random_bits(9*(i+1)-1 downto 9*i),
				o1_1 => from_sbox_a(98 + 3 * i),
				o1_2 => from_sbox_b(98 + 3 * i),
				o2_1 => from_sbox_a(98 + 3 * i + 1),
				o2_2 => from_sbox_b(98 + 3 * i + 1),
				o3_1 => from_sbox_a(98 + 3 * i + 2),
				o3_2 => from_sbox_b(98 + 3 * i + 2)
			);
	end generate;

	from_sbox_a(97 downto 0) <= to_sbox_a(97 downto 0);
	from_sbox_b(97 downto 0) <= to_sbox_b(97 downto 0);

	with sel_to_state select to_state_a <=
		C_data xor from_mat_mult_a when "00",
		from_sbox_a when "01",
		to_sbox_a	when others;

	with sel_to_state select to_state_b <=
		from_mat_mult_b when "00",
		from_sbox_b when "01",
		to_sbox_b	when others;
end architecture RTL;
