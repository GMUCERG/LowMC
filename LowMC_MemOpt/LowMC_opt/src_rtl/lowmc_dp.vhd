library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity lowmc_dp is
    port (
        clk       : in std_logic;
        key       : in std_logic_vector(128 - 1 downto 0);
        plaintext : in std_logic_vector(128 - 1 downto 0);
        sel_SK    : in std_logic;
        r_cnt     : in integer range 0 to NUM_ROUNDS;

        en_perm : in std_logic;
        en_piso : in std_logic;
        en_sipo : in std_logic;

        en_s1_r, init_s1_r : in std_logic;
        sel_pt             : in std_logic;
        sel_C0             : in std_logic;
        sel_s0_pt          : in std_logic;
        sel_to_sbox        : in std_logic;

		sel_30_32          : in std_logic;

        sel_s0     : in std_logic;
        sel_s1     : in std_logic;
		sel_Ci     : in std_logic;

        addr         : in std_logic_vector(wr - 1 downto 0);
        -- addr_Ci      : in std_logic_vector(4 downto 0);
        en_s0, en_s1 : in std_logic;
        ciphertext   : out std_logic_vector(128 - 1 downto 0)
    );
end entity;

architecture RTL of lowmc_dp is
    signal s0, s0_0, s0_1 : std_logic_vector(30 - 1 downto 0);
    signal s1             : std_logic_vector(98 - 1 downto 0);
    signal state          : std_logic_vector(128 - 1 downto 0);
    signal state_p        : std_logic_vector(128 - 1 downto 0);
    signal s1_p           : std_logic_vector(98 - 1 downto 0);
    signal s1_r           : std_logic_vector(98 - 1 downto 0);
    signal pt_0           : std_logic_vector(128 - 1 downto 0);

    signal piso      : std_logic_vector(31 downto 0);
    signal sipo      : std_logic_vector(127 downto 0);
    signal from_piso : std_logic_vector(U - 1 downto 0);
    signal to_sipo   : std_logic_vector(U - 1 downto 0);
    signal to_xor    : std_logic_vector(98 - 1 downto 0);

    signal sipo_p_C0  : std_logic_vector(97 downto 0);
    signal add_Ci, Ci : std_logic_vector(29 downto 0);
    signal to_sbox    : std_logic_vector(29 downto 0);
	signal from_sipo_30: std_logic_vector(29 downto 0);

    signal Cout : std_logic_vector(127 downto 0);
begin

	state <= s0 & s1;

    mat_mult_inst : entity work.mat_mult
        port map(
            clk       => clk,
            key       => key,
            state     => state,
            sel_SK    => sel_SK,
            addr      => addr,
            from_piso => from_piso,
            to_sipo   => to_sipo,
            to_xor    => to_xor,
            Cout      => Cout
        );

    perm_inst : entity work.perm
        port map(
            State_DI => state,
            Round_DI => r_cnt,
            State_DO => state_p
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if en_perm = '1' then
                s1_p <= state_p(97 downto 0);
            end if;
        end if;
    end process;

    piso_inst : process (clk)
    begin
        if rising_edge(clk) then
            if en_perm = '1' then
				piso(29 downto 0) <= state_p(127 downto 98);
            elsif en_piso = '1' then
				piso <= (u - 1 downto 0 => '0') & piso(31 downto u);
            end if;
        end if;
    end process;

	from_piso <= piso(u-1 downto 0);

    sipo_inst : process (clk)
    begin
        if rising_edge(clk) then
            if en_sipo = '1' then
                sipo <= to_sipo & sipo(127 downto u);
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if en_s1_r = '1' then
                if init_s1_r = '1' then
                    s1_r <= to_xor;
                else
                    s1_r <= s1_r xor to_xor;
                end if;
            end if;
        end if;
    end process;

    pt_0 <= plaintext when sel_pt = '1' else (others => '0');
    -- s(1)
    sipo_p_C0 <= sipo(97 downto 0) xor Cout(97 downto 0) when sel_C0 = '1' else sipo(97 downto 0);
    process (clk)
    begin
        if rising_edge(clk) then
            if en_s1 = '1' then
                if sel_s1 = '0' then
                    s1 <= sipo_p_C0 xor pt_0(97 downto 0);
                else
                    s1 <= s1_r xor s1_p;
                end if;
            end if;
        end if;
    end process;


	-- s(0)
	gen_sipo_30: if U = 1 or U = 2 generate
		from_sipo_30 <= sipo(127 downto 98) when sel_30_32 = '0' else sipo(127 downto 98);
	end generate;

	gen_sipo_30_U_4: if U > 2 generate
		from_sipo_30 <= sipo(127 downto 98) when sel_30_32 = '0' else sipo(125 downto 96);
	end generate;

	Ci <= Cout(127 downto 98) when sel_Ci = '0' else (others => '0');

    add_Ci  <= from_sipo_30 xor Ci;
    s0_0    <= add_Ci xor s0 when sel_s0_pt = '0' else add_Ci xor pt_0(127 downto 98);
    to_sbox <= s0 when sel_to_sbox = '0' else from_sipo_30;

    SBOXES_GEN : for i in 0 to 9 generate
        sbox : entity work.s_box
            port map(
                a  => to_sbox(3 * i),
                b  => to_sbox(3 * i + 1),
                c  => to_sbox(3 * i + 2),
                o1 => s0_1(3 * i),
                o2 => s0_1(3 * i + 1),
                o3 => s0_1(3 * i + 2)
            );
    end generate;

    process (clk)
    begin
        if rising_edge(clk) then
            if en_s0 = '1' then
                if sel_s0 = '0' then
                    s0 <= s0_0;
                else
                    s0 <= s0_1;
                end if;
            end if;
        end if;
    end process;

    ciphertext <= state;

end architecture RTL;