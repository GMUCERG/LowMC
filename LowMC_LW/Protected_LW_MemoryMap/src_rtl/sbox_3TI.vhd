library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sbox_3TI is
	Port(a_1, a_2 : in  std_logic;
		 b_1, b_2 : in std_logic;
		 c_1, c_2 : in std_logic;
		 m: in std_logic_vector(9-1 downto 0);
		 o1_1, o1_2: out std_logic;
		 o2_1, o2_2: out std_logic;
	     o3_1, o3_2 : out std_logic);
end sbox_3TI;

architecture arch of sbox_3TI is
	signal ab_1, ab_2 : std_logic;
	signal ac_1, ac_2: std_logic;
	signal bc_1, bc_2: std_logic;
	signal a1_xor_b1, a2_xor_b2: std_logic;
	signal a1_xor_b1_xor_c1, a2_xor_b2_xor_c2: std_logic;
begin
	and_3TI_1: entity work.and_3TI
		port map(
			xa => a_1,
			xb => a_2,
			ya => b_1,
			yb => b_2,
			m  => m(2 downto 0),
			o1 => ab_1,
			o2 => ab_2
		);
	and_3TI_2: entity work.and_3TI
		port map(
			xa => a_1,
			xb => a_2,
			ya => c_1,
			yb => c_2,
			m  => m(5 downto 3),
			o1 => ac_1,
			o2 => ac_2
		);
	and_3TI_3: entity work.and_3TI
		port map(
			xa => b_1,
			xb => b_2,
			ya => c_1,
			yb => c_2,
			m  => m(8 downto 6),
			o1 => bc_1,
			o2 => bc_2
		);
	
	a1_xor_b1 <= a_1 xor b_1;
	a2_xor_b2 <= a_2 xor b_2;
	
	a1_xor_b1_xor_c1 <= a1_xor_b1 xor c_1;
	a2_xor_b2_xor_c2 <= a2_xor_b2 xor c_2;
	
	o1_1 <= bc_1 xor a_1;
	o2_1 <= ac_1 xor a1_xor_b1;
	o3_1 <= ab_1 xor a1_xor_b1_xor_c1;
	
	o1_2 <= bc_2 xor a_2;
	o2_2 <= ac_2 xor a2_xor_b2;
	o3_2 <= ab_2 xor a2_xor_b2_xor_c2;

end arch;
