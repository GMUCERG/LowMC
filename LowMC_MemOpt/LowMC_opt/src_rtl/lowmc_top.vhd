library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity LowMC_top is
    port (
        clk        : in std_logic;
        rst        : in std_logic;
        pt         : in std_logic_vector(128 - 1 downto 0);
        k          : in std_logic_vector(128 - 1 downto 0);
        go         : in std_logic;
        done       : out std_logic;
        ciphertext : out std_logic_vector(128 - 1 downto 0)
    );
end entity LowMC_top;

architecture RTL of LowMC_top is
    signal plaintext, key : std_logic_vector(128 - 1 downto 0);
    signal sel_SK         : std_logic;

    signal en_perm, en_piso, en_sipo      : std_logic;
    signal en_s1_r, init_s1_r, sel_s1     : std_logic;
    signal sel_pt, sel_C0, sel_Ci         : std_logic;
    signal sel_s0_pt, sel_to_sbox, sel_s0 : std_logic;
    signal en_s0, en_s1                   : std_logic;
    signal addr                           : std_logic_vector(wr - 1 downto 0);
    signal sel_30_32                      : std_logic;

    type state_type is (S_IDLE, S_Key, S_Add_Key_C0, S_Sbox, S_ki, S_ki_Ci, S_Zi, S_Ri, S_ADD_si,
        S_Kr, S_kr_Cr, S_Zr, S_Zr_done, S_FINAL, S_WAIT);
    signal state, state_next : state_type;

    signal r, r_next : integer range 0 to NUM_ROUNDS - 2;
    signal i, i_next : unsigned(wr - 1 downto 0);

    constant MAT_SIZE  : integer := (30 + U - 1)/U;
    constant K0_OFFSET : integer := 0;
    constant Ki_OFFSET : integer := 128/U;
    constant Zi_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20;
    constant Ri_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19;
    constant Zr_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19 + ((30 + U - 1)/U) * 19;
    constant C0_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19 + ((30 + U - 1)/U) * 19 + 128/U;
    constant Ci_OFFSET : integer := C0_OFFSET + 1;

    constant MAT_MULT_CYCLE : integer := (30 + U - 1)/U;
begin

    plaintext <= pt;
    key       <= k;
    lowmc_dp_inst : entity work.lowmc_dp
        port map(
            clk         => clk,
            key         => key,
            plaintext   => plaintext,
            sel_SK      => sel_SK,
            r_cnt       => r,
            en_perm     => en_perm,
            en_piso     => en_piso,
            en_sipo     => en_sipo,
            en_s1_r     => en_s1_r,
            init_s1_r   => init_s1_r,
            sel_pt      => sel_pt,
            sel_C0      => sel_C0,
            sel_Ci      => sel_Ci,
            sel_s0_pt   => sel_s0_pt,
            sel_to_sbox => sel_to_sbox,
            sel_s0      => sel_s0,
            sel_s1      => sel_s1,
            addr        => addr,
            sel_30_32   => sel_30_32,
            en_s0       => en_s0,
            en_s1       => en_s1,
            ciphertext  => ciphertext
        );

    reg : process (clk, rst)
    begin
        if rst = '1' then
            state <= S_IDLE;
        elsif rising_edge(clk) then
            state <= state_next;
        end if;
    end process;

    reg_act : process (clk)
    begin
        if rising_edge(clk) then
            r <= r_next;
            i <= i_next;
        end if;
    end process;

    comb : process (all)
    begin
        en_perm     <= '0';
        en_piso     <= '0';
        en_sipo     <= '0';
        en_s1_r     <= '0';
        init_s1_r   <= '0';
        sel_s1      <= '0';
        sel_pt      <= '0';
        sel_C0      <= '0';
        sel_s0_pt   <= '0';
        sel_to_sbox <= '0';
        sel_s0      <= '0';
        en_s0       <= '0';
        en_s1       <= '0';
        sel_Ci      <= '0';
        addr        <= (others => '0');
        done        <= '0';
        i_next      <= i;
        r_next      <= r;
        sel_30_32   <= '0';
        state_next  <= state;
        sel_SK      <= '0';

        case state is
            when S_IDLE =>
                if go = '1' then
                    i_next     <= i + 1;
                    addr       <= std_logic_vector(i + K0_OFFSET);
                    state_next <= S_KEY;
                    r_next     <= 0;
                    i_next     <= (others => '0');
                end if;
            when S_KEY =>
                addr    <= std_logic_vector(i + K0_OFFSET);
                sel_SK  <= '0';
                en_sipo <= '1';
                if i >= 128/U then
                    state_next <= S_Add_Key_C0;
                    i_next     <= (others => '0');
                    addr       <= std_logic_vector(to_unsigned(C0_OFFSET, addr'length));
                else
                    i_next <= i + 1;
                end if;
            when S_Add_Key_C0 =>
                sel_pt <= '1';
                -- s(0)
                sel_s0_pt <= '1';
                sel_s0    <= '0';
                en_s0     <= '1';
                sel_Ci    <= '0';
                -- s(1)
                sel_C0 <= '1';
                sel_s1 <= '0';
                en_s1  <= '1';

                state_next <= S_Sbox;

            when S_Sbox =>
                -- s(0)
                en_s0       <= '1';
                sel_s0      <= '1';
                sel_to_sbox <= '0';
                state_next  <= S_Ki;

                addr   <= std_logic_vector(i + r * MAT_SIZE + Ki_OFFSET);
                i_next <= i + 1;
            when S_ki =>
                -- Add permuted s(1)
                if r > 0 and i = 1 then
                    en_s1  <= '1';
                    sel_s1 <= '1';
                end if;
                sel_SK  <= '0';
                en_sipo <= '1';
                addr    <= std_logic_vector(i + r * MAT_SIZE + Ki_OFFSET);
                if i >= MAT_MULT_CYCLE then
                    state_next <= S_ki_Ci;
                    addr       <= std_logic_vector(to_unsigned(r + Ci_OFFSET, addr'length));
                    i_next     <= (others => '0');
                else
                    i_next <= i + 1;
                end if;
            when S_ki_Ci =>
                sel_30_32  <= '1';
                state_next <= S_Zi;
                en_s0      <= '1';
                sel_s0     <= '0';
                sel_s0_pt  <= '0';

                addr   <= std_logic_vector(i + r * MAT_SIZE + Zi_OFFSET);
                i_next <= i + 1;

            when S_Zi =>
                -- Enable permutation
                if i = 1 then
                    en_piso <= '1';
                    en_perm <= '1';
                end if;

                if i = MAT_MULT_CYCLE + 1 then
                    state_next  <= S_Ri;
                    sel_to_sbox <= '1';
                    sel_s0      <= '1';
                    en_s0       <= '1';
                    sel_30_32   <= '1';
                    addr        <= std_logic_vector(to_unsigned(r * MAT_SIZE + Ri_OFFSET, addr'length));
                    i_next      <= to_unsigned(1, i'length);
                else
                    sel_SK  <= '1';
                    en_sipo <= '1';
                    addr    <= std_logic_vector(i + r * MAT_SIZE + Zi_OFFSET);
                    i_next  <= i + 1;
                end if;
            when S_Ri =>
                en_piso <= '1';
                en_s1_r <= '1';
                addr    <= std_logic_vector(i + r * MAT_SIZE + Ri_OFFSET);
                if i = MAT_MULT_CYCLE then
                    if r = NUM_ROUNDS - 2 then
                        state_next <= S_Kr;
                        r_next     <= 0;
                    else
                        state_next <= S_ki;
                        r_next     <= r + 1;
                    end if;
                    addr   <= std_logic_vector(to_unsigned((r + 1) * MAT_SIZE + Ki_OFFSET, addr'length));
                    i_next <= to_unsigned(1, i'length);
                elsif i = 1 then
                    init_s1_r <= '1';
                    i_next    <= i + 1;
                else
                    i_next <= i + 1;
                end if;
            when S_Kr =>
                -- Add permuted s(1)
                en_s1  <= '1';
                sel_s1 <= '1';

                sel_SK  <= '0';
                en_sipo <= '1';
                addr    <= std_logic_vector(i + 19 * MAT_SIZE + Ki_OFFSET);
                if i >= MAT_MULT_CYCLE then
                    state_next <= S_kr_Cr;
                    addr       <= std_logic_vector(to_unsigned(19 + Ci_OFFSET, addr'length));
                    i_next     <= (others => '0');
                else
                    i_next <= i + 1;
                end if;

            when S_kr_CR =>
                state_next <= S_Zr;
                en_s0      <= '1';
                sel_30_32  <= '1';
                sel_s0     <= '0';
                sel_s0_pt  <= '0';
                addr       <= std_logic_vector(i + Zr_OFFSET);
                i_next     <= i + 1;
            when S_Zr =>
                addr    <= std_logic_vector(i + Zr_OFFSET);
                sel_SK  <= '1';
                en_sipo <= '1';
                if i >= 128/U then
                    state_next <= S_Zr_done;
                    i_next     <= (others => '0');
                else
                    i_next <= i + 1;
                end if;

            when S_Zr_done =>
                en_s0      <= '1';
                en_s1      <= '1';
                state_next <= S_FINAL;

                -- s(0)
                sel_s0_pt <= '1';
                sel_pt    <= '0';
                sel_s0    <= '0';
                sel_Ci    <= '1';

                -- s(1)
                sel_C0 <= '0';
                sel_s1 <= '0';

            when S_FINAL =>
                done       <= '1';
                state_next <= S_IDLE;
            when S_WAIT => -- For debug
                state_next <= S_WAIT;
            when others =>
                state_next <= S_IDLE;
        end case;
    end process;
end architecture RTL;
architecture OPT_ADDR of LowMC_top is
    signal plaintext, key : std_logic_vector(128 - 1 downto 0);
    signal sel_SK         : std_logic;

    signal en_perm, en_piso, en_sipo      : std_logic;
    signal en_s1_r, init_s1_r, sel_s1     : std_logic;
    signal sel_pt, sel_C0, sel_Ci         : std_logic;
    signal sel_s0_pt, sel_to_sbox, sel_s0 : std_logic;
    signal en_s0, en_s1                   : std_logic;
    signal addr                           : std_logic_vector(wr - 1 downto 0);
    signal sel_30_32                      : std_logic;

    type state_type is (S_IDLE, S_Key, S_Add_Key_C0, S_Sbox, S_ki, S_ki_Ci, S_Zi, S_Ri, S_ADD_si,
        S_Kr, S_kr_Cr, S_Zr, S_Zr_done, S_FINAL, S_WAIT);
    signal state, state_next : state_type;

    signal r, r_next               : integer range 0 to NUM_ROUNDS - 2;
    signal i, i_next               : unsigned(log2ceil(128/U) downto 0);
    signal addr_cnt, addr_cnt_next : unsigned(wr - 1 downto 0);

    constant MAT_SIZE  : integer := (30 + U - 1)/U;
    constant K0_OFFSET : integer := 0;
    constant Ki_OFFSET : integer := 128/U;
    constant Zi_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20;
    constant Ri_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19;
    constant Zr_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19 + ((30 + U - 1)/U) * 19;
    constant C0_OFFSET : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19 + ((30 + U - 1)/U) * 19 + 128/U;
    constant Ci_OFFSET : integer := C0_OFFSET + 1;

    constant MAT_MULT_CYCLE : integer := (30 + U - 1)/U;
begin

    plaintext <= pt;
    key       <= k;
    addr      <= std_logic_vector(addr_cnt);
    lowmc_dp_inst : entity work.lowmc_dp
        port map(
            clk         => clk,
            key         => key,
            plaintext   => plaintext,
            sel_SK      => sel_SK,
            r_cnt       => r,
            en_perm     => en_perm,
            en_piso     => en_piso,
            en_sipo     => en_sipo,
            en_s1_r     => en_s1_r,
            init_s1_r   => init_s1_r,
            sel_pt      => sel_pt,
            sel_C0      => sel_C0,
            sel_Ci      => sel_Ci,
            sel_s0_pt   => sel_s0_pt,
            sel_to_sbox => sel_to_sbox,
            sel_s0      => sel_s0,
            sel_s1      => sel_s1,
            addr        => addr,
            sel_30_32   => sel_30_32,
            en_s0       => en_s0,
            en_s1       => en_s1,
            ciphertext  => ciphertext
        );

    reg : process (clk, rst)
    begin
        if rst = '1' then
            state <= S_IDLE;
        elsif rising_edge(clk) then
            state <= state_next;
        end if;
    end process;

    reg_act : process (clk)
    begin
        if rising_edge(clk) then
            r        <= r_next;
            i        <= i_next;
            addr_cnt <= addr_cnt_next;
        end if;
    end process;

    comb : process (all)
    begin
        en_perm       <= '0';
        en_piso       <= '0';
        en_sipo       <= '0';
        en_s1_r       <= '0';
        init_s1_r     <= '0';
        sel_s1        <= '0';
        sel_pt        <= '0';
        sel_C0        <= '0';
        sel_s0_pt     <= '0';
        sel_to_sbox   <= '0';
        sel_s0        <= '0';
        en_s0         <= '0';
        en_s1         <= '0';
        sel_Ci        <= '0';
        done          <= '0';
        i_next        <= i;
        r_next        <= r;
        addr_cnt_next <= addr_cnt;
        sel_30_32     <= '0';
        state_next    <= state;
        sel_SK        <= '0';

        case state is
            when S_IDLE              =>
                addr_cnt_next <= (others => '0');
                r_next        <= 0;
                i_next        <= (others => '0');
                if go = '1' then
                    state_next    <= S_KEY;
                    addr_cnt_next <= addr_cnt + 1;
                    i_next        <= i + 1;
                end if;
            when S_KEY =>
                addr_cnt_next <= addr_cnt + 1;
                sel_SK        <= '0';
                en_sipo       <= '1';
                if i >= 128/U then
                    state_next <= S_Add_Key_C0;
                    i_next     <= (others => '0');
                else
                    i_next <= i + 1;
                end if;
            when S_Add_Key_C0 =>
                sel_pt <= '1';
                -- s(0)
                sel_s0_pt <= '1';
                sel_s0    <= '0';
                en_s0     <= '1';
                sel_Ci    <= '0';
                -- s(1)
                sel_C0 <= '1';
                sel_s1 <= '0';
                en_s1  <= '1';

                state_next <= S_Sbox;

            when S_Sbox =>
                -- s(0)
                en_s0       <= '1';
                sel_s0      <= '1';
                sel_to_sbox <= '0';
                state_next  <= S_Ki;

                addr_cnt_next <= addr_cnt + 1;
                i_next        <= i + 1;
            when S_ki =>
                -- Add permuted s(1)
                if r > 0 and i = 1 then
                    en_s1  <= '1';
                    sel_s1 <= '1';
                end if;
                sel_SK        <= '0';
                en_sipo       <= '1';
                addr_cnt_next <= addr_cnt + 1;
                if i >= MAT_MULT_CYCLE then
                    state_next <= S_ki_Ci;
                    i_next     <= (others => '0');
                else
                    i_next <= i + 1;
                end if;
            when S_ki_Ci =>
                sel_30_32  <= '1';
                state_next <= S_Zi;
                en_s0      <= '1';
                sel_s0     <= '0';
                sel_s0_pt  <= '0';

                addr_cnt_next <= addr_cnt + 1;
                i_next        <= i + 1;

            when S_Zi =>
                -- Enable permutation
                if i = 1 then
                    en_piso <= '1';
                    en_perm <= '1';
                end if;

                sel_SK        <= '1';
                en_sipo       <= '1';
                addr_cnt_next <= addr_cnt + 1;
                if i >= MAT_MULT_CYCLE  then
                    state_next  <= S_Ri;
                    i_next      <= to_unsigned(1, i'length);
                else    
                    i_next        <= i + 1;
                end if;

            when S_Ri =>
                if i = 1 then
                    sel_to_sbox <= '1';
                    sel_s0      <= '1';
                    en_s0       <= '1';
                    sel_30_32   <= '1';
                end if;

                en_piso       <= '1';
                en_s1_r       <= '1';
                addr_cnt_next <= addr_cnt + 1;
                if i = MAT_MULT_CYCLE then
                    if r = NUM_ROUNDS - 2 then
                        state_next <= S_Kr;
                        r_next     <= 0;
                    else
                        state_next <= S_ki;
                        r_next     <= r + 1;
                    end if;
                    i_next <= to_unsigned(1, i'length);
                elsif i = 1 then
                    init_s1_r <= '1';
                    i_next    <= i + 1;
                else
                    i_next <= i + 1;
                end if;

            when S_Kr =>
                -- Add permuted s(1)
                en_s1  <= '1';
                sel_s1 <= '1';

                sel_SK        <= '0';
                en_sipo       <= '1';
                addr_cnt_next <= addr_cnt + 1;
                if i >= MAT_MULT_CYCLE then
                    state_next <= S_kr_Cr;
                    i_next     <= (others => '0');
                else
                    i_next <= i + 1;
                end if;

            when S_kr_CR =>
                state_next    <= S_Zr;
                en_s0         <= '1';
                sel_30_32     <= '1';
                sel_s0        <= '0';
                sel_s0_pt     <= '0';
                addr_cnt_next <= addr_cnt + 1;
                i_next        <= i + 1;
            when S_Zr =>

                sel_SK  <= '1';
                en_sipo <= '1';
                if i >= 128/U then
                    state_next    <= S_Zr_done;
                    addr_cnt_next <= (others => '0');
                    i_next        <= (others => '0');
                else
                    addr_cnt_next <= addr_cnt + 1;
                    i_next        <= i + 1;
                end if;

            when S_Zr_done =>
                en_s0      <= '1';
                en_s1      <= '1';
                state_next <= S_FINAL;

                -- s(0)
                sel_s0_pt <= '1';
                sel_pt    <= '0';
                sel_s0    <= '0';
                sel_Ci    <= '1';

                -- s(1)
                sel_C0 <= '0';
                sel_s1 <= '0';
            when S_FINAL =>
                done       <= '1';
                state_next <= S_IDLE;
            when S_WAIT => -- For debug
                state_next <= S_WAIT;
            when others =>
                state_next <= S_IDLE;
        end case;
    end process;
end architecture OPT_ADDR;