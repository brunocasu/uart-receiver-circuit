library ieee;
    use ieee.std_logic_1164.all;

entity rx_control is
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        rx    : in std_logic;
        frame_start    : in std_logic;
        frame_stop     : in std_logic;
        frame_error    : in std_logic;
        break          : in std_logic;
        parity_error   : in std_logic;
        y_valid_out       : out std_logic;
        synch_enable_out  : out std_logic;
        synch_reset_out   : out std_logic;
        buff_enable_out   : out std_logic;
        buff_reset_out    : out std_logic;
        buff_clear_out    : out std_logic
    );
end entity;

architecture struct of rx_control is

    type rx_control_fsm_state_t is
    (
        RESET_S,
        UART_RESET_S,
        IDLE_S,
        FRAME_DETECTION_S,
        VALIDATION_S,
        DATA_VALID_S,
        PARITY_ERROR_S,
        FRAME_ERROR_S,
        BREAK_ERROR_S

    );
    signal rx_control_fsm_state : rx_control_fsm_state_t := RESET_S;

    begin

        p_rx_control_fsm : process(clk, rst)
        begin
            if rst = '0' then -- reset active low
                rx_control_fsm_state <= RESET_S;
                y_valid_out      <= '0';
                synch_enable_out <= '0';
                synch_reset_out  <= '0';
                buff_enable_out  <= '0';
                buff_reset_out   <= '0';
                buff_clear_out   <= '0';

            elsif rising_edge(clk) then
                case rx_control_fsm_state is
                    when RESET_S =>
                        y_valid_out      <= '0';
                        synch_enable_out <= '0';
                        synch_reset_out  <= '0';
                        buff_enable_out  <= '0';
                        buff_reset_out   <= '0';
                        buff_clear_out   <= '0';
                        if rx = '1' then
                            rx_control_fsm_state <= IDLE_S;
                        end if;
                    when UART_RESET_S =>
                        y_valid_out      <= '0';
                        synch_reset_out  <= '0';
                        buff_reset_out   <= '0';
                        buff_clear_out   <= '0';
                        if rx = '1' then
                            rx_control_fsm_state <= IDLE_S;
                        elsif break = '1' then
                            rx_control_fsm_state <= BREAK_ERROR_S;
                        end if;

                    when IDLE_S =>
                        y_valid_out      <= '0';
                        synch_enable_out <= '1';
                        synch_reset_out  <= '1';
                        buff_enable_out  <= '1';
                        buff_reset_out   <= '1';
                        buff_clear_out   <= '0';
                        if frame_start = '1' then
                            rx_control_fsm_state <= FRAME_DETECTION_S;
                        end if;

                    when FRAME_DETECTION_S =>
                        if frame_stop = '1' then
                            rx_control_fsm_state <= VALIDATION_S;
                        elsif frame_error = '1' then
                            rx_control_fsm_state <= FRAME_ERROR_S;
                        end if;

                    when VALIDATION_S =>
                        if parity_error = '0' then -- parity is OK: data is valid
                            rx_control_fsm_state <= DATA_VALID_S;
                        else
                            rx_control_fsm_state <= PARITY_ERROR_S;
                        end if;

                    when DATA_VALID_S =>
                        y_valid_out      <= '1';
                        buff_clear_out   <= '1';
                        rx_control_fsm_state <= IDLE_S;

                    when PARITY_ERROR_S =>
                        y_valid_out      <= '0';
                        buff_clear_out   <= '1';
                        rx_control_fsm_state <= IDLE_S;

                    when FRAME_ERROR_S =>
                        rx_control_fsm_state <= UART_RESET_S;

                    when BREAK_ERROR_S =>
                        if rx = '1' then
                            rx_control_fsm_state <= IDLE_S;
                        end if;

                    when others => null;
                end case;

            end if;
        end process;
end architecture;

