library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity controller is
	generic(
		U : integer := 1
	);
	port(
		clk          : in  std_logic;
		rst          : in  std_logic;
		go           : in  std_logic;
		sel_SK       : out std_logic;
		en_sipo      : out std_logic;
		KL_addra     : out std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		KL_addrb     : out std_logic_vector(13 - log2ceil(U) - 1 downto 0);
		sel_SP       : out std_logic;
		sel_to_state : out std_logic_vector(2 - 1 downto 0);
		en_s, en_c   : out std_logic;
		en_prng      : out std_logic;
		ready        : out std_logic
	);
end entity controller;

architecture RTL of controller is
	constant MULT_LATENCY : integer := 128 / (2 * U);
	constant AB_OFFSET: integer := 128 / (2 * U);
	constant L_OFFSET     : integer := (128 / U) * 21;
	constant C_OFFSET     : integer := (128 / U) * 21 + (128 / U) * 20;
	constant SHIFT_AMT: integer := log2ceil(128/U);

	type state_type is (S_IDLE, S_Key, S_Sbox, S_Linear, S_Const, S_Add_Key, S_FINAL);
	signal state, state_next : state_type;

	signal r, r_next : unsigned(13 - log2ceil(U) - 1 downto 0);
	signal i, i_next : unsigned(13 - log2ceil(U) - 1 downto 0);
begin

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
		KL_addra     <= (others => '0');
		KL_addrb     <= (others => '0');
		sel_SP       <= '0';
		sel_to_state <= "00";
		en_s         <= '0';
		en_c         <= '0';
		ready        <= '0';
		en_prng      <= '0';
		i_next       <= i;
		r_next       <= r;
		state_next   <= state;
		case state is
			when S_IDLE =>
				if go = '1' then
					state_next <= S_Key;
					i_next <= i + 1;
					KL_addra <= std_logic_vector(i);
					KL_addrb <= std_logic_vector(i + AB_OFFSET);
				else
					state_next <= S_IDLE;
				end if;
			when S_Key =>
				KL_addra <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')));
				KL_addrb <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')) + AB_OFFSET);
				sel_SK <= '0';
				en_sipo <= '1';
				if i = MULT_LATENCY-1 or i = MULT_LATENCY then
					en_prng <= '1';
				end if;
				
				if i >= MULT_LATENCY then
					i_next <= (others => '0');
					if r >= NUM_ROUNDS-1 then
						state_next <= S_Add_Key;
					else
						state_next <= S_Sbox;
					end if;
				else
				    i_next <= i + 1;
				end if;	
			when S_Sbox =>
			 if r = 0 then
			     sel_SP <= '0';
			 else
			     sel_SP <= '1';
			 end if;
				
				en_s <= '1';
				sel_to_state <= "01";
				i_next <= i + 1;
				KL_addra <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')) + L_OFFSET);
				KL_addrb <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')) + AB_OFFSET + L_OFFSET);
				state_next <= S_Linear;
			when S_Linear =>
				KL_addra <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')) + L_OFFSET);
				KL_addrb <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')) + AB_OFFSET + L_OFFSET);
				sel_SK <= '1';
				en_sipo <= '1';
				if i >= MULT_LATENCY then
					i_next <= (others => '0');
					KL_addra <= std_logic_vector(r + C_OFFSET);
					r_next <= r + 1;
					state_next <= S_Const; 
				else 
				    i_next <= i + 1;
				end if;
			when S_Const =>
				en_s <= '1';
				sel_to_state <= "00";
				KL_addra <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')));
                KL_addrb <= std_logic_vector(i + (r(13 - log2ceil(U) - SHIFT_AMT - 1 downto 0) & (SHIFT_AMT-1 downto 0 => '0')) + AB_OFFSET);
				state_next <= S_Key;
			when S_Add_Key =>
				sel_to_state <= "10";
				en_s <= '1';
				sel_SP <= '1';
				state_next <= S_FINAL;
			when S_FINAL =>
				en_c <= '1';
				i_next <= (others => '0');
				r_next <= (others => '0');
				ready <= '1';
				state_next <= S_IDLE;
		end case;
	end process;

end architecture RTL;

