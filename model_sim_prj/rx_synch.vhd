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
        en    : in std_logic;
        rx    : in std_logic;
        sampled_rx    : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
        synch_status  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture struct of rx_synch is

    signal clk_count    : integer range 0 to OS_RATE := 0;
    signal bit_count    : integer range 0 to WORD_SIZE + STOP_BITS + 2 + 1 := 0;
    signal start_count  : integer range 0 to OS_RATE/2 := 0;
    signal idle_flag    : std_logic := '1';
    -- signal frame_error_flag : std_logic := '0';

begin
    p_rx_synch : process(clk, rst)
    begin
        if rst = '0' then -- reset active low
            sampled_rx <= (others => '0');
            synch_status <= (others => '0');
            clk_count    <= 0;
            bit_count    <= 0;
        elsif rising_edge(clk) then
            if en = '1' then

                -- rx sampling
                if bit_count > 0  then
                    clk_count <=  clk_count + 1;
                    if clk_count = OS_RATE - 1 then
                        clk_count <= 0;
                        if bit_count <= WORD_SIZE + 1 then
                            sampled_rx(bit_count-1) <= rx; -- sample input to vector
                            bit_count <= bit_count + 1;
                        else -- check stop bits
                            synch_status(0) <= '0';
                            if rx = '1' then
                                bit_count <= bit_count + 1;
                            else
                                bit_count <= 0;
                                synch_status(2) <= '1'; -- frame error
                            end if;
                        end if;
                    end if;
                end if;

                -- end of word (include parity bit)
                if bit_count = WORD_SIZE + 2 then
                    synch_status(0) <= '1';
                end if;

                -- end of frame detection
                if bit_count = WORD_SIZE + STOP_BITS + 2 and rx = '1' then
                    bit_count <= 0;
                    synch_status(1) <= '1';
                    idle_flag <= '1';
                    sampled_rx <= (others => '0');
                end if;

                -- UART start synchronization
                if (rx = '0' and start_count = 0 and idle_flag = '1') then
                    start_count <= start_count + 1;
                    synch_status(1) <= '0';
                    -- synch_status(2) <= '0';
                    -- frame_error_flag <= '0';
                end if;

                -- UART start bit detection
                if (start_count > 0 and idle_flag = '1') then
                    start_count <= start_count + 1;
                    -- first zero check
                    if start_count = (OS_RATE/2)-1 then
                        start_count <= 0;
                        if rx = '0' then
                            bit_count <= 1;
                            idle_flag <= '0'; -- exited idle state
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;
