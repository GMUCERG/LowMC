library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity LowMC_top_FOBOS is
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
	signal ciphertext : std_logic_vector(128 - 1 downto 0);
	signal go             : std_logic;
	signal ready          : std_logic;

	type state is (S_IDLE, S_RUN, S_DONE);
	signal current_state : state;
	signal next_state    : state;

begin

	ctrl : process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= S_IDLE;
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
			when S_IDLE =>
				pdi_ready <= '1';
				sdi_ready <= '1';
				if pdi_valid = '1' and sdi_valid = '1' then
					next_state <= S_RUN;
					go         <= '1';
				else
					next_state <= S_IDLE;
				end if;

			when S_RUN =>
				if ready = '1' then
					next_state <= S_DONE;
				else
					next_state <= S_RUN;
				end if;
			when others =>              --DONE
				if do_ready = '1' then
					do_valid   <= '1';
					next_state <= S_IDLE;
				else
					next_state <= S_DONE;
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
	
    LowMC_top_inst : entity work.LowMC_top
    port map (
        clk => clk,
        rst => rst,
        pt => plaintext,
        k => key,
        go => go,
        done => ready,
        ciphertext => ciphertext
    );


end architecture RTL;

