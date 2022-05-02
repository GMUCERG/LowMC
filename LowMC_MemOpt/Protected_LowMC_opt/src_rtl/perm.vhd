library work;
use work.lowmc_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity perm is
  generic(
      constant R: integer := NUM_ROUNDS;
      constant N: integer := 128;
      constant S: integer := 30
  );
  port(
    -- Input signals
    signal State_DI : in std_logic_vector(N - 1 downto 0);
    signal Round_DI : in integer range 0 to R;
    -- Output signals
    signal State_DO : out std_logic_vector(N - 1 downto 0)
  );
end entity;

architecture behavorial of perm is
  type T_NR_MATRIX is array(0 to R - 2) of std_logic_vector(N - 1 downto 0);
  signal State_Perm_out : T_NR_MATRIX;

begin

  PERM_GEN : for i in 0 to R - 2 generate
    STATE_PERM : entity work.state_perm
    generic map(
      Round_DI => i
    )
    port map(
      State_DI => State_DI,
      State_DO => State_Perm_out(i)
    );
  end generate PERM_GEN;

  State_DO <= State_Perm_out(Round_DI);

end behavorial;