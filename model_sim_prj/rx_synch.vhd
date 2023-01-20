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
        shift_reg_out   : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
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
        DATA_READY_S,
        STOP_DETECT_S,
        FRAME_END_S,
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
                shift_reg_out <= (others => '0');
                data_ready_out   <= '0';
                frame_start_out  <= '0';
                frame_stop_out   <= '0';
                frame_error_out  <= '0';
                bit_count    <= 0;
                count        := 0;

            elsif rising_edge(clk) then
                case rx_synch_fsm_state is
                    when RESET_S =>
                        shift_reg_out <= (others => '0');
                        data_ready_out   <= '0';
                        frame_start_out  <= '0';
                        frame_stop_out   <= '0';
                        frame_error_out  <= '0';
                        bit_count    <= 0;
                        count        := 0;
                        if rx = '1' then
                            rx_synch_fsm_state <= IDLE_S;
                        end if;
                    when IDLE_S =>
                        -- data_ready_out <= '0';
                        frame_stop_out <= '0';
                        if rx = '0' then
                            rx_synch_fsm_state <= START_DETECT_S;
                            count := 1;
                        end if;
                    when START_DETECT_S =>
                        -- frame_stop_out <= '0';
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
                            if bit_count <= WORD_SIZE then
                                shift_reg_out(bit_count) <= rx;
                                if bit_count = WORD_SIZE then
                                    rx_synch_fsm_state <= DATA_READY_S;
                                end if;
                            end if;
                            bit_count <= bit_count + 1;
                        else
                            count := count + 1;
                        end if;
                    when DATA_READY_S =>
                        count := count + 1; -- must keep the counter updated (data is ready while the stop bit is being counted)
                        data_ready_out <= '1';
                        frame_start_out <= '0';
                        rx_synch_fsm_state <= STOP_DETECT_S;

                    when STOP_DETECT_S =>
                        count := count + 1;
                        data_ready_out <= '0';
                        if count = OS_RATE then
                            count := 0;
                            if rx = '1' then
                                if bit_count = WORD_SIZE + STOP_BITS then
                                    rx_synch_fsm_state <= FRAME_END_S;
                                    bit_count  <= 0;
                                    shift_reg_out <= (others => '0');
                                else
                                    bit_count <= bit_count + 1;
                                end if;
                            else
                                rx_synch_fsm_state <= FRAME_ERROR_S;
                            end if;
                        end if;
                    when FRAME_END_S =>
                        frame_stop_out <= '1';
                        rx_synch_fsm_state <= IDLE_S;
                    when FRAME_ERROR_S =>
                        data_ready_out <= '0';
                        frame_error_out <= '1';

                    when others => null;
                end case;
            end if;
        end process;
end architecture;
