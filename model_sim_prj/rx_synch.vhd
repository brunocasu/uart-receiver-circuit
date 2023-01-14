library ieee;
    use ieee.std_logic_1164.all;

entity rx_synch is
    generic(
        OS_RATE     : natural := 8; -- clock over sampling rate (UART bit rate B = 115200)
        WORD_SIZE   : natural := 7; -- UART word size (W = 7) - does not count the parity bit
        STOP_BITS   : natural := 2 -- number of expected stop bits (S = 2)
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        rx    : in std_logic;
        sampled_rx    : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
        synch_status  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture struct of rx_synch is

    signal clk_count    : integer range 0 to OS_RATE := 0;
    signal bit_count    : integer range 0 to WORD_SIZE + STOP_BITS + 2 := 0;

begin
    p_rx_synch : process(clk, rst)
    begin
        if rst = '0' then -- reset active low
            sampled_rx <= (others => '0');
            synch_status <= (others => '0');
            clk_count    <= 0;
            bit_count    <= 0;

        elsif rising_edge(clk) then
            -- UART line goes down from idle
            if (rx = '0' and clk_count = 0 and bit_count = 0) then
                clk_count <= clk_count + 1;
            end if;
            -- UART start synchronization
            if clk_count > 0 and bit_count = 0 then
                clk_count <= clk_count + 1;
                -- start bit check
                if clk_count = (OS_RATE/2)-1 then
                    clk_count <= 0;
                    if rx = '0' then
                        bit_count <= 1;
                    else
                        synch_status(1) <= '1'; -- FRAME ERROR
                    end if;
                end if;
            end if;
            -- rx sampling
            if bit_count > 0  then
                clk_count <=  clk_count + 1;
                if clk_count = OS_RATE - 1 then
                    clk_count <= 0;
                    bit_count <= bit_count + 1;
                    if bit_count <= WORD_SIZE + 2 then
                        sampled_rx(bit_count-2) <= rx;
                        if bit_count = WORD_SIZE + 2 then
                            synch_status(0) <= '1'; -- WORD RECEIVED
                        end if;
                    -- check stop bits
                    elsif bit_count > WORD_SIZE + 2  then
                        synch_status(0) <= '0';
                        if rx = '1' then
                            if bit_count = WORD_SIZE + STOP_BITS + 2 then  -- end of transmission
                                bit_count <= 0;
                            end if;
                        else
                            synch_status(1) <= '1'; -- FRAME ERROR
                            bit_count <= 0;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;



