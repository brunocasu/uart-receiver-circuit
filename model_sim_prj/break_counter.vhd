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
    signal bit_count    : integer range 0 to BREAK_COUNT := 0;

begin
    p_break_counter : process(clk, rst)
    begin
        if rst = '0' then -- reset active low
            status       <= '0';
            clk_count    <= 0;
            bit_count    <= 0;

        elsif rising_edge(clk) then
            if (rx = '0' and clk_count = 0 and bit_count = 0) then
                clk_count <= clk_count + 1;
            end if;
            -- UART start synchronization
            if clk_count > 0 and bit_count = 0 then
                clk_count <= clk_count + 1;
                -- first zero check
                if clk_count = (OS_RATE/2)-1 then
                    clk_count <= 0;
                    if rx = '0' then
                        bit_count <= 1;
                    end if;
                end if;
            end if;
            -- rx sampling
            if bit_count > 0  then
                clk_count <=  clk_count + 1;
                if clk_count = OS_RATE - 1 then
                    clk_count <= 0;
                    bit_count <= bit_count + 1;
                    if rx = '0' then
                       if  bit_count = BREAK_COUNT - 1 then
                            -- status <= '1'; -- BREAK ERROR
                            bit_count <= 0;
                       end if;
                    else
                        bit_count <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;



