library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity LowMC_top_FOBOS is
	generic(U : integer := 16);
	port(
		clk       : in  STD_LOGIC;
		rst       : in  STD_LOGIC;
		pdi_data  : in  STD_LOGIC_VECTOR(128 - 1 downto 0);
		pdi_valid : in  STD_LOGIC;
		pdi_ready : out STD_LOGIC;
		sdi_data  : in  STD_LOGIC_VECTOR(128 - 1 downto 0);
		sdi_valid : in  STD_LOGIC;
		sdi_ready : out STD_LOGIC;
		do_data   : out STD_LOGIC_VECTOR(128 - 1 downto 0);
		do_valid  : out STD_LOGIC;
		do_ready  : in  STD_LOGIC
	);
end entity LowMC_top_FOBOS;

architecture RTL of LowMC_top_FOBOS is

	signal plaintext, key : std_logic_vector(128 - 1 downto 0);
	signal sel_SK         : std_logic;
	signal en_sipo        : std_logic;
	signal KL_addra       : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal KL_addrb       : std_logic_vector(13 - log2ceil(U) - 1 downto 0);
	signal sel_SP         : std_logic;
	signal sel_to_state   : std_logic_vector(2 - 1 downto 0);
	signal en_s           : std_logic;
	signal en_c           : std_logic;
	signal ciphertext : std_logic_vector(128 - 1 downto 0);
	signal go             : std_logic;
	signal ready          : std_logic;

	type state is (IDLE, RUN, DONE);
	signal current_state : state;
	signal next_state    : state;

begin

	ctrl : process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= IDLE;
			else
				current_state <= next_state;
			end if;

		end if;

	end process;

	comb : process(current_state, pdi_valid, sdi_valid, do_ready, ready)
	begin
		-- defaults
		pdi_ready  <= '0';
		sdi_ready  <= '0';
		do_valid   <= '0';
		go         <= '0';
		next_state <= current_state;

		case current_state is
			when IDLE =>
				pdi_ready <= '1';
				sdi_ready <= '1';
				if pdi_valid = '1' and sdi_valid = '1' then
					next_state <= RUN;
					go         <= '1';
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
				if do_ready = '1' then
					do_valid   <= '1';
					next_state <= IDLE;
				else
					next_state <= DONE;
				end if;
		end case;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if pdi_valid = '1' then
				plaintext <= pdi_data;
			end if;

			if sdi_valid = '1' then
				key <= sdi_data;
			end if;

			if ready = '1' then
				do_data <= ciphertext;
			end if;
		end if;
	end process;
	gen_datapath : entity work.datapath
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

