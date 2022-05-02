library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_lowmc_dp is
    port (
        clk : in std_logic;

        key_a : in std_logic_vector(128 - 1 downto 0);
        key_b : in std_logic_vector(128 - 1 downto 0);

        plaintext_a : in std_logic_vector(128 - 1 downto 0);
        plaintext_b : in std_logic_vector(128 - 1 downto 0);

        sel_SK : in std_logic;
        r_cnt  : in integer range 0 to NUM_ROUNDS;

        en_perm : in std_logic;
        en_piso : in std_logic;
        en_sipo : in std_logic;

        en_s1_r, init_s1_r : in std_logic;
        sel_pt             : in std_logic;
        sel_C0             : in std_logic;
        sel_s0_pt          : in std_logic;
        sel_to_sbox        : in std_logic;

        sel_30_32 : in std_logic;

        sel_s0 : in std_logic;
        sel_s1 : in std_logic;
        sel_Ci : in std_logic;

        addr         : in std_logic_vector(wr - 1 downto 0);
        en_s0, en_s1 : in std_logic;

        random_bits                : in std_logic_vector(90 - 1 downto 0);
        ciphertext_a, ciphertext_b : out std_logic_vector(128 - 1 downto 0)
    );
end entity;

architecture RTL of pr_lowmc_dp is
    signal s0_a, s0_0_a, s0_1_a : std_logic_vector(30 - 1 downto 0);
    signal s0_b, s0_0_b, s0_1_b : std_logic_vector(30 - 1 downto 0);

    signal s1_a : std_logic_vector(98 - 1 downto 0);
    signal s1_b : std_logic_vector(98 - 1 downto 0);

    signal state_a : std_logic_vector(128 - 1 downto 0);
    signal state_b : std_logic_vector(128 - 1 downto 0);

    signal state_p_a : std_logic_vector(128 - 1 downto 0);
    signal state_p_b : std_logic_vector(128 - 1 downto 0);

    signal s1_p_a : std_logic_vector(98 - 1 downto 0);
    signal s1_p_b : std_logic_vector(98 - 1 downto 0);

    signal s1_r_a : std_logic_vector(98 - 1 downto 0);
    signal s1_r_b : std_logic_vector(98 - 1 downto 0);

    signal pt_0_a : std_logic_vector(128 - 1 downto 0);
    signal pt_0_b : std_logic_vector(128 - 1 downto 0);

    signal piso_a : std_logic_vector(31 downto 0);
    signal piso_b : std_logic_vector(31 downto 0);

    signal sipo_a : std_logic_vector(127 downto 0);
    signal sipo_b : std_logic_vector(127 downto 0);

    signal from_piso_a : std_logic_vector(U - 1 downto 0);
    signal from_piso_b : std_logic_vector(U - 1 downto 0);

    signal to_sipo_a : std_logic_vector(U - 1 downto 0);
    signal to_sipo_b : std_logic_vector(U - 1 downto 0);

    signal to_xor_a : std_logic_vector(98 - 1 downto 0);
    signal to_xor_b : std_logic_vector(98 - 1 downto 0);

    signal sipo_p_C0_a : std_logic_vector(97 downto 0);
    signal sipo_p_C0_b : std_logic_vector(97 downto 0);

    signal add_Ci_a, Ci_a : std_logic_vector(29 downto 0);
    signal add_Ci_b, Ci_b : std_logic_vector(29 downto 0);

    signal to_sbox_a : std_logic_vector(29 downto 0);
    signal to_sbox_b : std_logic_vector(29 downto 0);

    signal from_sipo_30_a : std_logic_vector(29 downto 0);
    signal from_sipo_30_b : std_logic_vector(29 downto 0);
    signal Cout           : std_logic_vector(127 downto 0);
begin

    state_a <= s0_a & s1_a;
    state_b <= s0_b & s1_b;

    pr_mat_mult_inst : entity work.pr_mat_mult
        port map(
            clk         => clk,
            key_a       => key_a,
            key_b       => key_b,
            state_a     => state_a,
            state_b     => state_b,
            sel_SK      => sel_SK,
            addr        => addr,
            from_piso_a => from_piso_a,
            from_piso_b => from_piso_b,
            Cout        => Cout,
            to_sipo_a   => to_sipo_a,
            to_sipo_b   => to_sipo_b,
            to_xor_a    => to_xor_a,
            to_xor_b    => to_xor_b
        );

    perm_inst_a : entity work.perm
        port map(
            State_DI => state_a,
            Round_DI => r_cnt,
            State_DO => state_p_a
        );

    perm_inst_b : entity work.perm
        port map(
            State_DI => state_b,
            Round_DI => r_cnt,
            State_DO => state_p_b
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if en_perm = '1' then
                s1_p_a <= state_p_a(97 downto 0);
                s1_p_b <= state_p_b(97 downto 0);
            end if;
        end if;
    end process;


    piso_inst : process (clk)
    begin
        if rising_edge(clk) then
            if en_perm = '1' then
                piso_a(29 downto 0) <= state_p_a(127 downto 98);
                piso_b(29 downto 0) <= state_p_b(127 downto 98);
            elsif en_piso = '1' then
                piso_a <= (u - 1 downto 0 => '0') & piso_a(31 downto u);
                piso_b <= (u - 1 downto 0 => '0') & piso_b(31 downto u);
            end if;
        end if;
    end process;

    from_piso_a <= piso_a(u - 1 downto 0);
    from_piso_b <= piso_b(u - 1 downto 0);

    sipo_inst : process (clk)
    begin
        if rising_edge(clk) then
            if en_sipo = '1' then
                sipo_a <= to_sipo_a & sipo_a(127 downto u);
                sipo_b <= to_sipo_b & sipo_b(127 downto u);
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if en_s1_r = '1' then
                if init_s1_r = '1' then
                    s1_r_a <= to_xor_a;
                    s1_r_b <= to_xor_b;
                else
                    s1_r_a <= s1_r_a xor to_xor_a;
                    s1_r_b <= s1_r_b xor to_xor_b;
                end if;
            end if;
        end if;
    end process;

    pt_0_a <= plaintext_a when sel_pt = '1' else (others => '0');
    pt_0_b <= plaintext_b when sel_pt = '1' else (others => '0');

    -- s(1)
    sipo_p_C0_a <= sipo_a(97 downto 0) xor Cout(97 downto 0) when sel_C0 = '1' else sipo_a(97 downto 0);
    sipo_p_C0_b <= sipo_b(97 downto 0)                       when sel_C0 = '1' else sipo_b(97 downto 0);

    process (clk)
    begin
        if rising_edge(clk) then
            if en_s1 = '1' then
                if sel_s1 = '0' then
                    s1_a <= sipo_p_C0_a xor pt_0_a(97 downto 0);
                    s1_b <= sipo_p_C0_b xor pt_0_b(97 downto 0);
                else
                    s1_a <= s1_r_a xor s1_p_a;
                    s1_b <= s1_r_b xor s1_p_b;
                end if;
            end if;
        end if;
    end process;

    -- s(0)
    gen_sipo_30 : if U = 1 or U = 2 generate
        from_sipo_30_a <= sipo_a(127 downto 98) when sel_30_32 = '0' else sipo_a(127 downto 98);
        from_sipo_30_b <= sipo_b(127 downto 98) when sel_30_32 = '0' else sipo_b(127 downto 98);
    end generate;

    gen_sipo_30_U_4 : if U > 2 generate
        from_sipo_30_a <= sipo_a(127 downto 98) when sel_30_32 = '0' else sipo_a(125 downto 96);
        from_sipo_30_b <= sipo_b(127 downto 98) when sel_30_32 = '0' else sipo_b(125 downto 96);
    end generate;

    Ci_a <= Cout(127 downto 98) when sel_Ci = '0' else (others => '0');
    Ci_b <= (others => '0') when sel_Ci = '0' else (others => '0');

    add_Ci_a  <= from_sipo_30_a xor Ci_a;
    add_Ci_b  <= from_sipo_30_b xor Ci_b;

    s0_0_a    <= add_Ci_a xor s0_a when sel_s0_pt = '0' else add_Ci_a xor pt_0_a(127 downto 98);
    s0_0_b    <= add_Ci_b xor s0_b when sel_s0_pt = '0' else add_Ci_b xor pt_0_b(127 downto 98);

    to_sbox_a <= s0_a when sel_to_sbox = '0' else from_sipo_30_a;
    to_sbox_b <= s0_b when sel_to_sbox = '0' else from_sipo_30_b;

    SBOXES_GEN : for i in 0 to 9 generate
		sbox : entity work.sbox_3TI
			port map(
				a_1  => to_sbox_a(3 * i),
				a_2  => to_sbox_b(3 * i),
				b_1  => to_sbox_a(3 * i + 1),
				b_2  => to_sbox_b(3 * i + 1),
				c_1  => to_sbox_a(3 * i + 2),
				c_2  => to_sbox_b(3 * i + 2),
				m    => random_bits(9*(i+1)-1 downto 9*i),
				o1_1 => s0_1_a(3 * i),
				o1_2 => s0_1_b(3 * i),
				o2_1 => s0_1_a(3 * i + 1),
				o2_2 => s0_1_b(3 * i + 1),
				o3_1 => s0_1_a(3 * i + 2),
				o3_2 => s0_1_b(3 * i + 2)
			);
	end generate;

    process (clk)
    begin
        if rising_edge(clk) then
            if en_s0 = '1' then
                if sel_s0 = '0' then
                    s0_a <= s0_0_a;
                    s0_b <= s0_0_b;
                else
                    s0_a <= s0_1_a;
                    s0_b <= s0_1_b;
                end if;
            end if;
        end if;
    end process;

    ciphertext_a <= state_a;
    ciphertext_b <= state_b;

end architecture RTL;