library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_mat_mult is
    port (
        clk   : in std_logic;
        key_a   : in std_logic_vector(128 - 1 downto 0);
        key_b   : in std_logic_vector(128 - 1 downto 0);

        state_a : in std_logic_vector(128 - 1 downto 0);
        state_b : in std_logic_vector(128 - 1 downto 0);

        sel_SK    : in std_logic;
        addr      : in std_logic_vector(wr-1 downto 0);

        from_piso_a : in std_logic_vector(U - 1 downto 0);
        from_piso_b : in std_logic_vector(U - 1 downto 0);

        Cout    : out std_logic_vector(128 - 1 downto 0);

        to_sipo_a : out std_logic_vector(U - 1 downto 0);
        to_sipo_b : out std_logic_vector(U - 1 downto 0);

        to_xor_a  : out std_logic_vector(97 downto 0);
        to_xor_b  : out std_logic_vector(97 downto 0)
    );
end entity pr_mat_mult;

architecture RTL of pr_mat_mult is
    signal to_and_a      : std_logic_vector(128 - 1 downto 0);
    signal to_and_b      : std_logic_vector(128 - 1 downto 0);

    signal from_parity_a : std_logic_vector(U - 1 downto 0);
    signal from_parity_b : std_logic_vector(U - 1 downto 0);

    type arr_128 is array (U - 1 downto 0) of std_logic_vector(128 - 1 downto 0);
    signal ROM_do       : arr_128;

    signal from_and_128_a : arr_128;
    signal from_and_128_b : arr_128;

    type arr_98 is array (U - 1 downto 0) of std_logic_vector(98 - 1 downto 0);
    signal from_and_98_a : arr_98;
    signal from_and_98_b : arr_98;
begin
    to_and_a <= key_a when sel_SK = '0' else state_a;
    to_and_b <= key_b when sel_SK = '0' else state_b;


    Cout   <= ROM_do(0);

    gen_mult : for i in 0 to U - 1 generate
        ROM : entity work.single_port_ROM
            generic map(
                ROM_NUM => i
            )
            port map(
                clk  => clk,
                addr => addr,
                do   => ROM_do(i)
            );
        from_and_128_a(i) <= ROM_do(i) and to_and_a;
        from_and_128_b(i) <= ROM_do(i) and to_and_b;


        from_and_98_a(i)  <= ROM_do(i)(97 downto 0) and (97 downto 0 => from_piso_a(i));
        from_and_98_b(i)  <= ROM_do(i)(97 downto 0) and (97 downto 0 => from_piso_b(i));

        from_parity_a(i)     <= xor from_and_128_a(i);
        from_parity_b(i)     <= xor from_and_128_b(i);

        to_sipo_a(i) <= from_parity_a(i);
        to_sipo_b(i) <= from_parity_b(i);

    end generate gen_mult;

    process (from_and_98_a)
        variable tmp : std_logic_vector(97 downto 0);
    begin
        tmp := (others => '0');
        for j in 0 to U - 1 loop
            tmp := tmp xor from_and_98_a(j);
        end loop;
        to_xor_a <= tmp;
    end process;

    process (from_and_98_b)
        variable tmp : std_logic_vector(97 downto 0);
    begin
        tmp := (others => '0');
        for j in 0 to U - 1 loop
            tmp := tmp xor from_and_98_b(j);
        end loop;
        to_xor_b <= tmp;
    end process;

end architecture RTL;