library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity LowMC_top_synth is
	port(
		clk   : in  std_logic;
		rst   : in  std_logic;
		pt    : in  std_logic;
		en_pt : in  std_logic;
		k     : in  std_logic;
		en_k  : in  std_logic;
		go    : in  std_logic;
		ready : out std_logic;
		en_ct : in  std_logic;
		ct    : out std_logic
	);
end entity LowMC_top_synth;

architecture RTL of LowMC_top_synth is
	signal plaintext, key, ciphertext : std_logic_vector(128 - 1 downto 0);
	signal ct_piso                    : std_logic_vector(128 - 1 downto 0);
	signal ready_sig                  : std_logic;
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if en_pt = '1' then
				plaintext <= plaintext(127 - 1 downto 0) & pt;
			end if;

			if en_k = '1' then
				key <= key(127 - 1 downto 0) & k;
			end if;

			if ready_sig = '1' then
				ct_piso <= ciphertext;
			elsif en_ct = '1' then
				ct_piso <= ct_piso(127 - 1 downto 0) & '0';
			end if;
		end if;
	end process;
	ct <= ct_piso(127);
	ready <= ready_sig;

    LowMC_top_inst : entity work.LowMC_top
    port map (
        clk => clk,
        rst => rst,
        pt => plaintext,
        k => key,
        go => go,
        done => ready_sig,
        ciphertext => ciphertext
    );


end architecture RTL;
