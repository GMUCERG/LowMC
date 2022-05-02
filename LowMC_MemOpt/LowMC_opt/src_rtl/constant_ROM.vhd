library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use work.lowmc_pkg.all;
use std.textio.all;

entity  constant_ROM is
    port (
        clk : in std_logic;
        addr : in std_logic_vector(4 downto 0);
        do : out std_logic_vector(29 downto 0)
    );
end entity constant_ROM;

architecture RTL of constant_ROM is
    constant ROM_DEPTH : integer := 21;
    constant FILENAME  : string  := "ROM_contents/Ci.txt";
    type rom_type is array (0 to ROM_DEPTH) of std_logic_vector(31 downto 0);

    impure function Rfile(filename : in string) return rom_type is
        file romfile                   : text open read_mode is filename;
        variable romfileline           : line;
        variable rom                   : rom_type;
    begin
        for i in rom_type'range loop
            readline(romfile, romfileline);
            hread(romfileline, rom(i));
        end loop;
        return rom;
    end function;

    signal memory                 : rom_type := Rfile(FILENAME);
    attribute ram_style           : string;
    attribute ram_style of memory : signal is "distributed";

    signal do_buf: std_logic_vector(31 downto 0);

begin

    process (clk)
    begin
        if rising_edge(clk) then
            do_buf <= memory(to_integer(unsigned(addr)));
        end if;
    end process;
    do <= do_buf(29 downto 0);

end architecture RTL;