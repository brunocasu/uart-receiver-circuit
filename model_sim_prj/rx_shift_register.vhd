library ieee;
    use ieee.std_logic_1164.all;

entity rx_shift_register is
    generic(
        OS_RATE     : natural := 8; -- clock over sampling rate is 8 times the UART bit rate (B = 115200)
        WORD_SIZE   : natural := 7; -- UART word size (W=7) - does not count the parity bit
        STOP_BITS   : natural := 2; -- number of expected stop bits (S=2)
        BREAK       : natural := 11 -- BREAK character counter size
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        rx    : in std_logic;
        sampled_rx    : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
        synch_status  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture struct of rx_shift_register is
begin
    signal clk_count    : natural range 0 to (OS_RATE - 1) := 0;
    signal frame_count  : natural range 0 to WORD_SIZE + STOP_BITS + 1 := 0;
    signal break_count  : natural range 0 to BREAK;

    p_rx_shift_register : process(clk, rst)
    begin
        if rst = '0' then -- reset active low
            sampled_rx <= (others => '0');
            synch_status <= (others => '0');
        elsif rising_edge(clk) then
            if (rx = '0' and frame_count = 0) then -- UART line goes down from idle
                clk_count <= clk_count+1;
            elsif (clk_count = (OS_RATE/2)-1 and frame_count = 0) then -- start bit check
                clock_count <= 0;
                if (rx = '0') then
                    frame_count <= frame_count +1;
                else then
                    synch_status(1) <= '1'; -- FRAME ERROR
                    frame_count <= 0;
                end if;
            elsif frame_count > 0 and clk_count = OS_RATE - 1 then -- sample trigger inside a frame reception
                clk_count <= 0;
                if frame_count > WORD_SIZE + 1 then  -- stop bit check
                    if rx = '1';
                        synch_status(0) <= '1'; -- frame received
                        frame_count <= frame_count + 1;
                        if frame_count = WORD_SIZE + STOP_BITS + 1 then -- final stop bit detected
                            frame_count <= 0;
                    else
                        synch_status(1) <= '1'; -- FRAME ERROR
                        frame_count <= 0;
                    end if;
                else
                    sampled_rx(frame_count-1) <= rx; -- sample rx value
                    frame_count <= frame_count + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;



