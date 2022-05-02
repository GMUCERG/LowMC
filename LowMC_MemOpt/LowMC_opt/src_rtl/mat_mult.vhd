library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity mat_mult is
    port (
        clk   : in std_logic;
        key   : in std_logic_vector(128 - 1 downto 0);
        state : in std_logic_vector(128 - 1 downto 0);

        sel_SK    : in std_logic;
        addr      : in std_logic_vector(wr-1 downto 0);
        from_piso : in std_logic_vector(U - 1 downto 0);

        Cout    : out std_logic_vector(128 - 1 downto 0);
        to_sipo : out std_logic_vector(U - 1 downto 0);
        to_xor  : out std_logic_vector(97 downto 0)
    );
end entity mat_mult;

architecture RTL of mat_mult is
    signal to_and      : std_logic_vector(128 - 1 downto 0);
    signal from_parity : std_logic_vector(U - 1 downto 0);

    type arr_128 is array (U - 1 downto 0) of std_logic_vector(128 - 1 downto 0);
    signal ROM_do       : arr_128;
    signal from_and_128 : arr_128;
    type arr_98 is array (U - 1 downto 0) of std_logic_vector(98 - 1 downto 0);
    signal from_and_98 : arr_98;
begin
    to_and <= key when sel_SK = '0' else state;
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
        from_and_128(i) <= ROM_do(i) and to_and;
        from_and_98(i)  <= ROM_do(i)(97 downto 0) and (97 downto 0 => from_piso(i));

        from_parity(i)     <= xor from_and_128(i);
        to_sipo(i) <= from_parity(i);

    end generate gen_mult;

    process (from_and_98)
        variable tmp : std_logic_vector(97 downto 0);
    begin
        tmp := (others => '0');
        for j in 0 to U - 1 loop
            tmp := tmp xor from_and_98(j);
        end loop;
        to_xor <= tmp;
    end process;

end architecture RTL;