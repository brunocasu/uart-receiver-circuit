library ieee;
    use ieee.std_logic_1164.all;

entity rx_synch is
    generic(
        OS_RATE     : natural := 8; -- clock over sampling rate (UART bit rate B = 115200)
        WORD_SIZE   : natural := 7; -- UART word size (W = 7) - does not count the parity bit
        STOP_BITS   : natural := 2 -- number of expected stop bits (S = 2)
        -- BREAK_COUNT : natural := 11 -- number of consecutive '0's to detect a BREAK
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        en    : in std_logic;
        rx    : in std_logic;
        data_out    : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
        data_ready_out  : out std_logic;
        frame_start_out : out std_logic;
        frame_stop_out  : out std_logic;
        frame_error_out : out std_logic

    );
end entity;

architecture struct of rx_synch is

    type rx_synch_fsm_state_t is
    (
        RESET_S,
        IDLE_S,
        START_DETECT_S,
        RECEIVE_DATA_S,
        STOP_DETECT_S,
        FRAME_ERROR_S
    );

    signal rx_synch_fsm_state : rx_synch_fsm_state_t := RESET_S;
    signal bit_count    : integer range 0 to WORD_SIZE + STOP_BITS + 2 + 1 := 0;

    begin

        p_rx_synch_fsm : process(clk, rst)
        variable count : integer := 0;
        begin
            if rst = '0' then -- reset active low
                rx_synch_fsm_state <= RESET_S;
                data_out <= (others => '0');
                data_ready_out   <= '0';
                frame_start_out  <= '0';
                frame_stop_out   <= '0';
                frame_error_out  <= '0';
                bit_count    <= 0;

            elsif rising_edge(clk) then
                case rx_synch_fsm_state is
                    when RESET_S =>
                        if rx = '1' then
                            rx_synch_fsm_state <= IDLE_S;
                        end if;
                    when IDLE_S =>
                        data_ready_out <= '0';
                        frame_stop_out <= '1';
                        if rx = '0' then
                            rx_synch_fsm_state <= START_DETECT_S;
                            count := 1;
                        end if;
                    when START_DETECT_S =>
                        frame_stop_out <= '0';
                        if count = (OS_RATE/2) - 1 then
                            if rx = '0' then
                                rx_synch_fsm_state <= RECEIVE_DATA_S;
                                count := 0;
                            else
                                rx_synch_fsm_state <= FRAME_ERROR_S;
                            end if;
                        else
                            count := count + 1;
                        end if;
                    when RECEIVE_DATA_S =>
                        frame_start_out <= '1';
                        if count = OS_RATE - 1 then
                            count := 0;
                            if bit_count < WORD_SIZE then
                                data_out(bit_count) <= rx;
                            end if;
                            bit_count <= bit_count + 1;
                            -- if bit_count-1 >= 0 and bit_count-1 <= WORD_SIZE + 1 then
                            -- end if;
                            if bit_count = WORD_SIZE then
                                rx_synch_fsm_state <= STOP_DETECT_S;
                            end if;
                        else
                            count := count + 1;
                        end if;
                    when STOP_DETECT_S =>
                        frame_start_out <= '0';
                        data_ready_out <= '1';
                        count := count + 1;
                        if count = OS_RATE then
                            count := 0;
                            if rx = '1' then
                                if bit_count = WORD_SIZE + STOP_BITS then
                                    rx_synch_fsm_state <= IDLE_S;
                                    bit_count  <= 0;
                                    data_out <= (others => '0');
                                else
                                    bit_count <= bit_count + 1;
                                end if;
                            else
                                rx_synch_fsm_state <= FRAME_ERROR_S;
                            end if;
                        end if;
                    when FRAME_ERROR_S =>
                        data_ready_out <= '0';
                        frame_error_out <= '1';

                    when others => null;
                end case;
            end if;
        end process;
end architecture;
    --p_rx_synch : process(clk, rst)
    --variable test : integer := 0;
    --
    --begin
    --    if rst = '0' then -- reset active low
    --        data_out <= (others => '0');
    --        synch_status <= (others => '0');
    --        clk_count    <= 0;
    --        bit_count    <= 0;
    --        start_count  <= 0;
    --    elsif rising_edge(clk) then
    --        if en = '1' then
    --            -- rx sampling
    --            if bit_count > 0  then
    --                clk_count <=  clk_count + 1;
    --                if clk_count = OS_RATE - 1 then
    --                    clk_count <= 0;
    --                    if bit_count <= WORD_SIZE + 1 then
    --                        data_out(bit_count-1) <= rx; -- sample input to vector
    --                        bit_count <= bit_count + 1;
    --                    else -- check stop bits
    --                        synch_status(0) <= '0';
    --                        if rx = '1' then
    --                            bit_count <= bit_count + 1;
    --                        else
    --                            bit_count <= 0;
    --                            synch_status(2) <= '1'; -- frame error
    --                        end if;
    --                    end if;
    --                end if;
    --            else
    --                if end_of_frame = '1' then -- clear end of frame
    --                    synch_status(1) <= '0';
    --                end if;
    --            end if;
    --
    --            -- end of word (include parity bit)
    --            if bit_count = WORD_SIZE + 2 then
    --                synch_status(0) <= '1';
    --            end if;
    --
    --            -- end of frame detection
    --            if bit_count = WORD_SIZE + STOP_BITS + 2 and rx = '1' then
    --                bit_count <= 0;
    --                synch_status(1) <= '1';
    --                IDLE_S_flag <= '1';
    --                data_out <= (others => '0');
    --                end_of_frame <= '1';
    --            end if;
    --
    --            -- -- after a frame error detection the Control block clear the synchronizer ot receive again
    --            if clear = '1' and IDLE_S_flag = '0' then
    --                IDLE_S_flag <= '1';
    --                synch_status(0) <= '0';
    --                synch_status(2) <= '0';
    --            end if;
    --
    --            -- UART start synchronization
    --            if (rx = '0' and start_count = 0 and IDLE_S_flag = '1') then
    --                start_count <= start_count + 1;
    --                synch_status(1) <= '0';
    --                -- synch_status(2) <= '0';
    --                -- frame_error_out_flag <= '0';
    --            end if;
    --
    --            -- UART start bit detection
    --            if (start_count > 0 and IDLE_S_flag = '1') then
    --                start_count <= start_count + 1;
    --                -- first zero check
    --                if start_count = (OS_RATE/2)-1 then
    --                    start_count <= 0;
    --                    if rx = '0' then
    --                        bit_count <= 1;
    --                        IDLE_S_flag <= '0'; -- exited IDLE_S state
    --                    else
    --                        synch_status(2) <= '1'; -- frame error
    --                    end if;
    --                end if;
    --            end if;
    --        end if;
    --    end if;
    --end process;


