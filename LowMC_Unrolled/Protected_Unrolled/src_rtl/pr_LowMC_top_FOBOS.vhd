library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_LowMC_top_FOBOS is
	generic(U: integer := 16);
	port(
		clk       : in  STD_LOGIC;
		rst       : in  STD_LOGIC;
		pdi_data  : in  STD_LOGIC_VECTOR(128 - 1 downto 0);
		pdi_valid : in  STD_LOGIC;
		pdi_ready : out STD_LOGIC;
		sdi_data  : in  STD_LOGIC_VECTOR(128 - 1 downto 0);
		sdi_valid : in  STD_LOGIC;
		sdi_ready : out STD_LOGIC;
		rdi_data  : in  STD_LOGIC_VECTOR(128 - 1 downto 0);
		rdi_valid : in  STD_LOGIC;
		rdi_ready : out STD_LOGIC;
		do_data   : out STD_LOGIC_VECTOR(128 - 1 downto 0);
		do_valid  : out STD_LOGIC;
		do_ready  : in  STD_LOGIC
	);
end entity pr_LowMC_top_FOBOS;

architecture RTL of pr_LowMC_top_FOBOS is
	signal plaintext_a, key_a       : std_logic_vector(128 - 1 downto 0);
	signal plaintext_b, key_b       : std_logic_vector(128 - 1 downto 0);
	signal en_plaintext_a, en_key_a : std_logic;
	signal en_plaintext_b, en_key_b : std_logic;

	signal sel_SK                     : std_logic;
	signal en_sipo                    : std_logic;
	signal sel_SP                     : std_logic;
	signal sel_to_state               : std_logic_vector(2 - 1 downto 0);
	signal en_s                       : std_logic;
	signal en_c                       : std_logic;
	signal en_prng                    : std_logic;
	signal random_bits                : std_logic_vector(128 - 1 downto 0);
	signal triv_out, triv_reg         : std_logic_vector(64 - 1 downto 0);
	signal KL_addra                   : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal KL_addrb                   : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal ciphertext_a, ciphertext_b : std_logic_vector(128 - 1 downto 0);
	signal sel_ciphertext             : std_logic;

	type state is (IDLE, RUN, DONE);
	signal current_state : state;
	signal next_state    : state;
	signal i, i_next     : unsigned(0 downto 0);
	signal go            : std_logic;
	signal ready         : std_logic;
	signal reseed        : std_logic;
begin
ctrl : process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= IDLE;
				i             <= (others => '0');

			else
				current_state <= next_state;
				i             <= i_next;

			end if;

		end if;

	end process;

	comb : process(current_state, pdi_valid, sdi_valid, do_ready, go, ready, i, rdi_valid)
	begin
		-- defaults
		pdi_ready      <= '0';
		sdi_ready      <= '0';
		rdi_ready      <= '0';
		do_valid       <= '0';
		go             <= '0';
		next_state     <= current_state;
		i_next         <= i;
		en_key_a       <= '0';
		en_key_b       <= '0';
		en_plaintext_a <= '0';
		en_plaintext_b <= '0';
		reseed         <= '0';
		sel_ciphertext <= '0';
		case current_state is
			when IDLE =>
				if pdi_valid = '1' and sdi_valid = '1' then
					if i = 1 then
						en_key_b       <= '1';
						en_plaintext_b <= '1';
						next_state     <= RUN;
						go             <= '1';
						pdi_ready <= '1';
						sdi_ready <= '1';
						i_next         <= (others => '0');
					else -- i == 0
						if rdi_valid = '1' then 
							en_key_a       <= '1';
							en_plaintext_a <= '1';
							reseed         <= '1';
							pdi_ready <= '1';
							sdi_ready <= '1';
							rdi_ready <= '1';
							i_next    <= i + 1;
						else
							next_state <= IDLE;
						end if;
					end if;
				else
					next_state <= IDLE;
				end if;

			when RUN =>
				if ready = '1' then
					next_state <= DONE;
				else
					next_state <= RUN;
				end if;
			when others =>              --DONE
				sel_ciphertext <= i(0);
				if do_ready = '1' then
					do_valid <= '1';
					i_next   <= i + 1;
					if i = 1 then
						next_state <= IDLE;
						i_next     <= (others => '0');
					end if;
				end if;
		end case;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if en_plaintext_a = '1' then
				plaintext_a <= pdi_data;
			end if;

			if en_plaintext_b = '1' then
				plaintext_b <= pdi_data;
			end if;

			if en_key_a = '1' then
				key_a <= sdi_data;
			end if;

			if en_key_b = '1' then
				key_b <= sdi_data;
			end if;
		end if;
	end process;

	do_data <= ciphertext_a when sel_ciphertext = '0' else ciphertext_b;

	gen_prng : entity work.prng_trivium_enhanced
		generic map(
			N => 1
		)
		port map(
			clk        => clk,
			rst        => rst,
			en_prng    => en_prng,
			seed       => rdi_data,
			reseed     => reseed,
			reseed_ack => open,
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
	   generic map(U => U)
		port map(
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
			random_bits  => random_bits(90 - 1 downto 0),
			ciphertext_a => ciphertext_a,
			ciphertext_b => ciphertext_b
		);

	gen_controller : entity work.controller
	   generic map(U => U)
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
			en_prng      => en_prng,
			ready        => ready
		);
end architecture RTL;
