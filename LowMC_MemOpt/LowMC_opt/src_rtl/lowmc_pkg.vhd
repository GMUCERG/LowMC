library ieee;
use ieee.std_logic_1164.all;

package lowmc_pkg is
	constant U: integer := 16; --! 1, 2, 4, 8, 16

	function log2ceil(num : natural) return natural;
	function log2(val : natural) return natural;
	function max(L, R : INTEGER) return INTEGER;
	function min(L, R : INTEGER) return INTEGER;

	
	--                              K0            Ki                        Zi                     Ri                 Zr   C0+Ci
    constant ROM_DEPTH : integer := 128/U + ((30 + U - 1)/U) * 20 + ((30 + U - 1)/U) * 19 + ((30 + U - 1)/U) * 19 + 128/U  + 21;
	constant wr: integer := log2ceil(ROM_DEPTH);

	constant NUM_ROUNDS :integer := 20;
	-- constant C0: std_logic_vector(127 downto 0) := x"000000016ee016559278ab60a47f1a8e";

	type INT_ARRAY is array(integer range <>) of integer;
	type R_C_ARRAY is array(0 to 3) of integer;
    type R_ARRAY is array(0 to NUM_ROUNDS - 2) of R_C_ARRAY;

	-- number of columns to swap per matrix
	constant R_CC : INT_ARRAY(0 to NUM_ROUNDS - 2) := (
		4,
		3,
		1,
		1,
		0,
		4,
		0,
		1,
		0,
		1,
		0,
		0,
		1,
		0,
		1,
		0,
		1,
		0,
		3
	);

	-- columns to swap per matrix
	constant R_C : R_ARRAY := (
		(
		94, 97, 99, 100
		),
		(
		96, 97, 98, 0
		),
		(
		97, 0, 0, 0
		),
		(
		95, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		94, 98, 99, 100
		),
		(
		0, 0, 0, 0
		),
		(
		97, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		94, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		97, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		97, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		97, 0, 0, 0
		),
		(
		0, 0, 0, 0
		),
		(
		95, 96, 98, 0
		)
	);


	
end package lowmc_pkg;

package body lowmc_pkg is
	function log2ceil(num : natural) return natural is
		variable i : natural;
	begin
		i := 0;
		while (2**i < num) loop
			i := i + 1;
		end loop;
		return i;
	end function;

	function log2(val : natural) return natural is
		variable res : natural;
	begin
		for i in 30 downto 0 loop
			if (val >= (2**i)) then
				res := i;
				exit;
			end if;
		end loop;
		return res;
	end function log2;

	function max(L, R : INTEGER) return INTEGER is
	begin
		if L > R then
			return L;
		else
			return R;
		end if;
	end max;

	function min(L, R : INTEGER) return INTEGER is
	begin
		if L < R then
			return L;
		else
			return R;
		end if;
	end min;
end package body lowmc_pkg;
