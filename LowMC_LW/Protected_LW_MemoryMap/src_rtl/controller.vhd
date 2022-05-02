library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity controller is
	port(
		clk          : in  std_logic;
		rst          : in  std_logic;
		go           : in  std_logic;
		sel_SK       : out std_logic;
		en_sipo      : out std_logic;
		KL_addr1     : out std_logic_vector(12 - 1 downto 0);
		KL_addr2     : out std_logic_vector(11 - 1 downto 0);
		sel_SP       : out std_logic;
		sel_do       : out std_logic;
		sel_to_state : out std_logic_vector(2 - 1 downto 0);
		en_s, en_c   : out std_logic;
		en_prng : out std_logic;
		ready        : out std_logic
	);
end entity controller;

architecture RTL of controller is
	constant MULT_LATENCY : integer := 64;
	signal sel_KL, sel_C     : std_logic;
	type state_type is (S_IDLE, S_Key, S_Sbox, S_Linear, S_Const, S_Add_Key, S_FINAL);
	signal state, state_next : state_type;

	signal r, r_next : unsigned(5 - 1 downto 0);
	signal i, i_next : unsigned(7 - 1 downto 0);
begin

	KL_addr1 <= sel_KL & std_logic_vector(r(3 downto 0)) & '0' & std_logic_vector(i(5 downto 0)) when sel_C = '0' else "1000000" & std_logic_vector(r(4 downto 0));

	KL_addr2 <= sel_KL & std_logic_vector(r(2 downto 0)) & '0' & std_logic_vector(i(5 downto 0));
	
	

	reg : process(clk, rst)
	begin
		if rst = '1' then
			state <= S_IDLE;
			r     <= (others => '0');
			i     <= (others => '0');
		elsif rising_edge(clk) then
			state <= state_next;
			r     <= r_next;
			i     <= i_next;
		end if;
	end process;

	comb : process(all)
	begin
		sel_SK       <= '0';
		en_sipo      <= '0';
		sel_KL       <= '0';
		sel_C        <= '0';
		sel_SP       <= '0';
		sel_to_state <= "00";
		en_s         <= '0';
		en_c         <= '0';
		ready        <= '0';
		en_prng <= '0';
		i_next       <= i;
		r_next       <= r;
		state_next   <= state;
		sel_do <= r(4);
		case state is
			when S_IDLE =>
				if go = '1' then
					state_next <= S_Key;
					i_next     <= i + 1;
					sel_KL     <= '0';
				else
					state_next <= S_IDLE;
				end if;
			when S_Key =>
				sel_KL     <= '0';
				sel_SK   <= '0';
				en_sipo  <= '1';
				if i = MULT_LATENCY-1 or i = MULT_LATENCY then
					en_prng <= '1';
				end if;
				if i >= MULT_LATENCY then
					i_next <= (others => '0');
					r_next     <= r + 1;
					if r >= NUM_ROUNDS - 1 then
						state_next <= S_Add_Key;
					else
						state_next <= S_Sbox;
					end if;
				else
					i_next <= i + 1;
				end if;
			when S_Sbox =>
				if r = 1 then
					sel_SP <= '0';
				else
					sel_SP <= '1';
				end if;

				en_s         <= '1';
				sel_to_state <= "01";
				i_next       <= i + 1;
				sel_KL     <= '1';
				state_next   <= S_Linear;
			when S_Linear =>
				sel_KL     <= '1';
				sel_SK   <= '1';
				en_sipo  <= '1';
				if i >= MULT_LATENCY then
					i_next     <= (others => '0');
					sel_C <= '1';
					state_next <= S_Const;
				else
					i_next <= i + 1;
				end if;
			when S_Const =>
				en_s         <= '1';
				sel_to_state <= "00";
				sel_do <= '0';
				state_next   <= S_Key;
			when S_Add_Key =>
				sel_to_state <= "10";
				en_s         <= '1';
				sel_SP       <= '1';
				state_next   <= S_FINAL;
			when S_FINAL =>
				en_c       <= '1';
				i_next     <= (others => '0');
				r_next     <= (others => '0');
				ready      <= '1';
				state_next <= S_IDLE;
		end case;
	end process;

end architecture RTL;

