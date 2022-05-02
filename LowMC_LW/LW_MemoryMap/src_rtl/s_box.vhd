library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity s_box is
	Port(a  : in  std_logic;
	     b  : in  std_logic;
	     c  : in  std_logic;
	     o1 : out std_logic;
	     o2 : out std_logic;
	     o3 : out std_logic);
end entity s_box;

architecture RTL of s_box is
	signal ab            : std_logic;
	signal ac            : std_logic;
	signal bc            : std_logic;
	signal a_xor_b       : std_logic;
	signal a_xor_b_xor_c : std_logic;
begin
	ab            <= a and b;
	ac            <= a and c;
	bc            <= b and c;
	a_xor_b       <= a xor b;
	a_xor_b_xor_c <= a_xor_b xor c;

	o1 <= bc xor a;
	o2 <= ac xor a_xor_b;
	o3 <= ab xor a_xor_b_xor_c;
end architecture RTL;
