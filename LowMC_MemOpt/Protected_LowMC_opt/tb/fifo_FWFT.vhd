-------------------------------------------------------------------------------
--! @file       fifo.vhd
--! @brief      Single-port Synchronous FIFO
--!
--! @author     Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic (
        G_LOG2DEPTH         : integer := 9;         --! LOG(2) of depth
        G_W                 : integer := 64;        --! Width of I/O (bits)
        G_ODELAY            : boolean := False      --! Output delay
    );
    port (
        clk                 : in  std_logic;
        rstn                : in  std_logic;
        write               : in  std_logic;
        read                : in  std_logic;
        di_data             : in  std_logic_vector(G_W          -1 downto 0);
        do_data             : out std_logic_vector(G_W          -1 downto 0);
        almost_full         : out std_logic;
        almost_empty        : out std_logic;
        full                : out std_logic;
        empty               : out std_logic
    );
end fifo;

architecture structure of fifo is
    signal readpointer      : std_logic_vector(G_LOG2DEPTH      -1 downto 0);
    signal writepointer     : std_logic_vector(G_LOG2DEPTH      -1 downto 0);
    signal bytecounter      : std_logic_vector(G_LOG2DEPTH+1    -1 downto 0);
    signal write_s          : std_logic;
    signal full_s           : std_logic;
    signal empty_s          : std_logic;

    type    mem is array (2**G_LOG2DEPTH-1 downto 0) of
        std_logic_vector(G_W-1 downto 0);
    signal  memory          : mem;
begin
    p_fifo_ram:
    process(clk)
    begin
        if rising_edge(clk) then
            if (write_s = '1') then
                memory(to_integer(unsigned(writepointer))) <= di_data;
            end if;
        end if;
    end process;
    
    g_outd0:
    if (G_ODELAY = False) generate
        do_data <= memory(to_integer(unsigned(readpointer)));
    end generate;
    g_outd1:
    if (G_ODELAY = True) generate
        process(clk)
        begin
            if rising_edge(clk) then
                if (read = '1') then
                    do_data <= memory(to_integer(unsigned(readpointer)));
                end if;
            end if;
        end process;
    end generate;


    p_fifo_ptr:
    process(clk)
    begin
        if rstn = '0' then
            readpointer  <= (others => '0');
            writepointer <= (others => '0');
            --! differences (write pointer - read pointer)
            bytecounter  <= (others => '0');
        elsif rising_edge( clk ) then
            if (write = '1' and full_s = '0' and read = '0') then
                writepointer <= std_logic_vector(unsigned(writepointer)
                                + natural(1));
                bytecounter  <= std_logic_vector(unsigned(bytecounter)
                                + natural(1));
            elsif (read = '1' and empty_s = '0' and write = '0') then
                readpointer  <= std_logic_vector(unsigned(readpointer)
                                + natural(1));
                bytecounter  <= std_logic_vector(unsigned(bytecounter)
                                - natural(1));
            elsif (read = '1' and empty_s = '0'
                and write = '1' and full_s = '0')
            then
                readpointer <= std_logic_vector(unsigned(readpointer)
                                + natural(1));
                writepointer <= std_logic_vector(unsigned(writepointer)
                                + natural(1));
            elsif (read = '1' and empty_s = '0'
                and write = '1' and full_s = '1')
            then --! cant write
                readpointer <= std_logic_vector(unsigned(readpointer)
                                + natural(1));
                bytecounter <= std_logic_vector(unsigned(bytecounter)
                                - natural(1));
            elsif (read = '1' and empty_s = '1'
                and write = '1' and full_s = '0')
            then --! cant read
                writepointer <= std_logic_vector(unsigned(writepointer)
                                + natural(1));
                bytecounter <= std_logic_vector(unsigned(bytecounter)
                                + natural(1));
            end if;
        end if;
    end process;

    empty_s         <= '1'  when (unsigned(bytecounter) = 0) else  '0';
    full_s          <= bytecounter(G_LOG2DEPTH);
    almost_full     <= '1'  when (unsigned(bytecounter) >= 2**G_LOG2DEPTH-1)
                            else '0';
    full            <= full_s;
    empty           <= empty_s;
    almost_empty    <= '1'  when (unsigned(bytecounter) = 1 and write = '0')
                            else '0';

    write_s <= '1' when ( write = '1' and full_s = '0') else '0';
end structure;
