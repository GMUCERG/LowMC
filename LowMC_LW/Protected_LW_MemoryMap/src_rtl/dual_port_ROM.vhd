library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use work.lowmc_pkg.all;
use std.textio.all;

entity dual_port_ROM is
	generic(
		FILENAME: string;
		ROM_DEPTH : integer := 0
	);
	port(
		clk        : in  std_logic;
		--		ena, enb   : in  std_logic;
		adda, addb : in  std_logic_vector(log2ceil(ROM_DEPTH) - 1 downto 0);
		doa, dob   : out std_logic_vector(127 downto 0)
	);
end entity dual_port_ROM;

architecture RTL of dual_port_ROM is
  
	type rom_type is array (0 to ROM_DEPTH) of std_logic_vector(127 downto 0);

	impure function Rfile(filename : in string) return rom_type is
		file romfile         : text open read_mode is filename;
		variable romfileline : line;
		variable rom         : rom_type;
	begin
		for i in rom_type'range loop
			readline(romfile, romfileline);
			hread(romfileline, rom(i));
			--read(romfileline,rom(i));
		end loop;
		return rom;
	end function;

	signal memory       : rom_type := Rfile(FILENAME);
	attribute ram_style : string;
	attribute ram_style of memory : signal is "block";

begin

	process(clk)
	begin
		if rising_edge(clk) then
			--			if ena = '1' then
			doa <= memory(to_integer(unsigned(adda)));
			--			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			--			if enb = '1' then
			dob <= memory(to_integer(unsigned(addb)));
			--			end if;
		end if;
	end process;

end architecture RTL;
