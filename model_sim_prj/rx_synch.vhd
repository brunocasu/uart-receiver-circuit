library ieee;
    use ieee.std_logic_1164.all;

entity rx_synch is
    generic(
        OS_RATE     : natural := 8; -- clock over sampling rate (UART bit rate B = 115200)
        WORD_SIZE   : natural := 7; -- UART word size (W = 7) - does not count the parity bit
        STOP_BITS   : natural := 2; -- number of expected stop bits (S = 2)
        BREAK_COUNT : natural := 11 -- number of consecutive '0's to detect a BREAK
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        en    : in std_logic;
        rx    : in std_logic;
        clear : in std_logic;
        sampled_rx    : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
        break_status  : out std_logic;
        synch_status  : out std_logic_vector(3 downto 0)
        -- break_status    : break error flag
        -- synch status(2) : frame error flag
        -- synch status(1) : end of frame
        -- synch status(0) : word received flag

    );
end entity;

architecture struct of rx_synch is

    signal clk_count    : integer range 0 to OS_RATE := 0;
    signal bit_count    : integer range 0 to WORD_SIZE + STOP_BITS + 2 + 1 := 0;
    signal start_count  : integer range 0 to OS_RATE/2 := 0;
    signal idle_flag    : std_logic := '1'; -- 1 for idle
    signal break_out    : std_logic := '0';
    signal dff_out      : std_logic := '0';
    signal end_of_frame : std_logic := '0';

    component break_counter is
        generic(
            OS_RATE     : natural := 8; -- clock over sampling rate (UART bit rate B = 115200)
            BREAK_COUNT : natural := 11 -- number of consecutive '0's to detect a BREAK
        );
        port (
            clk     : in std_logic;
            rst     : in std_logic;
            rx      : in std_logic;
            status  : out std_logic
        );
    end component;

    --type rx_synch_fsm_state_t is
    --(
    --    RESET,
    --    IDLE,
    --    DETECT_START_BIT,
    --    RECEIVE_DATA,
    --    RECEIVE_PARITY,
    --    PUBLISH_RESULT,
    --    ERROR_FRAME
    --);
    --
    --signal rx_synch_fsm_state : rx_synch_fsm_state_t := IDLE;



begin


    --p_rx_synch_fsm : process(clk, rst)
    --begin
    --    if rst = '0' then -- reset active low
    --
    --    elsif rising_edge(clk) then
    --        case rx_synch_fsm_state is
    --            when IDLE =>
    --                if (blah = '1') then
    --                    rx_synch_fsm_state <= DETECT_START_BIT;
    --                end if;
    --        end case;
    --    end if;
    --end process;

    break_DUT: break_counter
        generic map(
            OS_RATE => OS_RATE,
            BREAK_COUNT => BREAK_COUNT
        )
        port map(
            clk => clk,
            rst => rst,
            rx  => rx,
            status => break_out
        );

    break_status <= break_out;
    synch_status(3) <= break_out;

    p_rx_synch : process(clk, rst)
    variable test : integer := 0;

    begin
        if rst = '0' then -- reset active low
            sampled_rx <= (others => '0');
            synch_status <= (others => '0');
            clk_count    <= 0;
            bit_count    <= 0;
            start_count  <= 0;
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
                else
                    if end_of_frame = '1' then -- clear end of frame
                        synch_status(1) <= '0';
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
                    end_of_frame <= '1';
                end if;

                -- -- after a frame error detection the Control block clear the synchronizer ot receive again
                if clear = '1' and idle_flag = '0' then
                    idle_flag <= '1';
                    synch_status(0) <= '0';
                    synch_status(2) <= '0';
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
                        else
                            synch_status(2) <= '1'; -- frame error
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;
