library ieee;
    use ieee.std_logic_1164.all;

entity break_counter is
    generic(
        OS_RATE     : natural := 8; -- clock over sampling rate (UART bit rate B = 115200)
        BREAK_COUNT : natural := 11 -- number of consecutive '0's to detect a BREAK
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        rx    : in std_logic;
        status  : out std_logic
    );
end entity;

architecture struct of break_counter is

    signal clk_count    : integer range 0 to OS_RATE := 0;
    signal start_count  : integer range 0 to OS_RATE/2 := 0;
    signal bit_count    : integer range 0 to BREAK_COUNT + 1 := 0;
    signal idle_flag    : std_logic := '1';

begin
    p_break_counter : process(clk, rst)
    begin
        if rst = '0' then -- reset active low
            status       <= '0';
            clk_count    <= 0;
            bit_count    <= 0;

        elsif rising_edge(clk) then
            -- rx sampling
            if bit_count > 0 and bit_count <= BREAK_COUNT + 1 then
                clk_count <= clk_count + 1;
                if clk_count = OS_RATE - 1 then
                    clk_count <= 0;
                    if rx = '0' then
                        if  bit_count = BREAK_COUNT then
                            -- bit_count <= 0;
                            bit_count <= bit_count + 1;
                        elsif bit_count = BREAK_COUNT + 1 then
                            bit_count <= 2; -- start bit received again
                            status <= '0';
                        else
                            bit_count <= bit_count + 1;
                        end if;
                    else
                        bit_count <= 0;
                        status <= '0';
                        idle_flag <= '1'; -- re entereed idle state
                    end if;
                end if;
            end if;

            -- UART start synchronization
            if (rx = '0' and start_count = 0 and idle_flag = '1') then
                start_count <= start_count + 1;
                status <= '0';
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

            -- BREAK detection
            if  bit_count = BREAK_COUNT then
                status <= '1';
            end if;
        end if;
    end process;

end architecture;



