library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use work.lowmc_pkg.all;
use std.textio.all;

entity single_port_ROM is
    generic (
        ROM_NUM : integer := 0
    );
    port (
        clk : in std_logic;
        addr : in std_logic_vector(wr - 1 downto 0);
        do : out std_logic_vector(127 downto 0)
    );
end entity single_port_ROM;

architecture RTL of single_port_ROM is
    constant FILENAME  : string  := "ROM_contents/KZR_U" & integer'image(U) & "_" & integer'image(ROM_NUM) & ".txt";
    type rom_type is array (0 to ROM_DEPTH) of std_logic_vector(127 downto 0);

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
    attribute ram_style of memory : signal is "block";

begin

    process (clk)
    begin
        if rising_edge(clk) then
            do <= memory(to_integer(unsigned(addr)));
        end if;
    end process;

end architecture RTL;