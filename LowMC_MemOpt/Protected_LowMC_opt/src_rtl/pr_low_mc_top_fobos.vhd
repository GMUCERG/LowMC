library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lowmc_pkg.all;

entity pr_LowMC_top_FOBOS is
    port (
        clk       : in std_logic;
        rst       : in std_logic;
        pdi_data  : in std_logic_vector(128 - 1 downto 0);
        pdi_valid : in std_logic;
        pdi_ready : out std_logic;
        sdi_data  : in std_logic_vector(128 - 1 downto 0);
        sdi_valid : in std_logic;
        sdi_ready : out std_logic;
        rdi_data  : in std_logic_vector(128 - 1 downto 0);
        rdi_valid : in std_logic;
        rdi_ready : out std_logic;
        do_data   : out std_logic_vector(128 - 1 downto 0);
        do_valid  : out std_logic;
        do_ready  : in std_logic
    );
end entity pr_LowMC_top_FOBOS;

architecture RTL of pr_LowMC_top_FOBOS is
    signal plaintext_a, key_a       : std_logic_vector(128 - 1 downto 0);
    signal plaintext_b, key_b       : std_logic_vector(128 - 1 downto 0);
    signal en_plaintext_a, en_key_a : std_logic;
    signal en_plaintext_b, en_key_b : std_logic;

    signal ct_a, ct_b                 : std_logic_vector(128 - 1 downto 0);
    signal ciphertext_a, ciphertext_b : std_logic_vector(128 - 1 downto 0);
    signal sel_ciphertext             : std_logic;

    type state is (IDLE, RUN, DONE);
    signal current_state : state;
    signal next_state    : state;
    signal i, i_next     : unsigned(0 downto 0);
    signal go            : std_logic;
    signal ready         : std_logic;
    signal reseed        : std_logic;
begin
    ctrl : process (clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                current_state <= IDLE;
                i             <= (others => '0');
            else
                current_state <= next_state;
                i             <= i_next;
            end if;
        end if;
    end process;

    comb : process (current_state, pdi_valid, sdi_valid, do_ready, go, ready, i, rdi_valid)
    begin
        -- defaults
        pdi_ready      <= '0';
        sdi_ready      <= '0';
        rdi_ready      <= '0';
        do_valid       <= '0';
        go             <= '0';
        next_state     <= current_state;
        i_next         <= i;
        en_key_a       <= '0';
        en_key_b       <= '0';
        en_plaintext_a <= '0';
        en_plaintext_b <= '0';
        reseed         <= '0';
        sel_ciphertext <= '0';
        case current_state is
            when IDLE =>
                if pdi_valid = '1' and sdi_valid = '1' then
                    if i = 1 then
                        en_key_b       <= '1';
                        en_plaintext_b <= '1';
                        next_state     <= RUN;
                        go             <= '1';
                        pdi_ready      <= '1';
                        sdi_ready      <= '1';
                        i_next         <= (others => '0');
                    else -- i == 0
                        if rdi_valid = '1' then
                            en_key_a       <= '1';
                            en_plaintext_a <= '1';
                            reseed         <= '1';
                            pdi_ready      <= '1';
                            sdi_ready      <= '1';
                            rdi_ready      <= '1';
                            i_next         <= i + 1;
                        else
                            next_state <= IDLE;
                        end if;
                    end if;
                else
                    next_state <= IDLE;
                end if;

            when RUN =>
                if ready = '1' then
                    next_state <= DONE;
                else
                    next_state <= RUN;
                end if;
            when others => --DONE
                sel_ciphertext <= i(0);
                if do_ready = '1' then
                    do_valid <= '1';
                    i_next   <= i + 1;
                    if i = 1 then
                        next_state <= IDLE;
                        i_next     <= (others => '0');
                    end if;
                end if;
        end case;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if en_plaintext_a = '1' then
                plaintext_a <= pdi_data;
            end if;

            if en_plaintext_b = '1' then
                plaintext_b <= pdi_data;
            end if;

            if en_key_a = '1' then
                key_a <= sdi_data;
            end if;

            if en_key_b = '1' then
                key_b <= sdi_data;
            end if;

            if ready = '1' then
                ciphertext_a <= ct_a;
                ciphertext_b <= ct_b;
            end if;
        end if;
    end process;

    do_data <= ciphertext_a when sel_ciphertext = '0' else ciphertext_b;

    pr_lowmc_top_inst : entity work.pr_lowmc_top
        port map(
            clk          => clk,
            rst          => rst,
            seed         => rdi_data,
            reseed       => reseed,
            pt_a         => plaintext_a,
            pt_b         => plaintext_b,
            k_a          => key_a,
            k_b          => key_b,
            go           => go,
            done         => ready,
            ciphertext_a => ct_a,
            ciphertext_b => ct_b
        );

end architecture RTL;