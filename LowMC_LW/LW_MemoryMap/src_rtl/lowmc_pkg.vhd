package lowmc_pkg is
	constant NUM_ROUNDS :integer := 21;

	function log2ceil(num : natural) return natural;
	function log2(val : natural) return natural;
	function max(L, R : INTEGER) return INTEGER;
	function min(L, R : INTEGER) return INTEGER;
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
