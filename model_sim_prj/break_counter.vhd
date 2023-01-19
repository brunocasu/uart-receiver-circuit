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
        en    : in std_logic;
        rx    : in std_logic;
        break_error_out  : out std_logic
    );
end entity;

architecture struct of break_counter is

    type break_counter_fsm_state_t is
    (
        RESET_S,
        AUTO_RESET_S,
        IDLE_S,
        START_DETECT_S,
        RECEIVE_DATA_S,
        BREAK_ERROR_S
    );
    signal break_counter_fsm_state : break_counter_fsm_state_t := RESET_S;
    signal bit_count    : integer range 0 to BREAK_COUNT := 0;

    begin

        p_break_counter : process(clk, rst)
        variable count : integer := 0;
        begin
            if rst = '0' then -- reset active low
                break_error_out       <= '0';
                break_counter_fsm_state  <= RESET_S;
                bit_count   <= 0;
                count       := 0;

            elsif rising_edge(clk) then
                if en = '1' then
                    case break_counter_fsm_state is
                        when RESET_S =>
                            break_error_out       <= '0';
                            break_counter_fsm_state  <= RESET_S;
                            bit_count   <= 0;
                            count       := 0;
                            if rx = '1' then
                                break_counter_fsm_state <= IDLE_S;
                            end if;
                        when AUTO_RESET_S =>
                                if rx = '1' then
                                    break_counter_fsm_state <= IDLE_S;
                                end if;
                        when IDLE_S =>
                            break_error_out <= '0';
                            if rx = '0' then
                                break_counter_fsm_state <= START_DETECT_S;
                                count := 1;
                            end if;
                        when START_DETECT_S =>
                            if count = (OS_RATE/2) - 1 then
                                if rx = '0' then
                                    break_counter_fsm_state <= RECEIVE_DATA_S;
                                    bit_count <= 1; -- start bit is counted
                                    count := 0;
                                else
                                    break_counter_fsm_state <= IDLE_S;
                                end if;
                            else
                                count := count + 1;
                            end if;
                        when RECEIVE_DATA_S =>
                            if count = OS_RATE - 1 then
                                count := 0;
                                if rx = '0' then
                                    if bit_count = BREAK_COUNT - 2 then
                                        bit_count <= 0;
                                        break_counter_fsm_state <= BREAK_ERROR_S;
                                    else
                                        bit_count <= bit_count + 1;
                                    end if;
                                else
                                    bit_count <= 0;
                                    break_counter_fsm_state <= IDLE_S;
                                end if;
                            else
                                count := count + 1;
                            end if;
                        when BREAK_ERROR_S =>
                            break_error_out <= '1';
                            break_counter_fsm_state <= AUTO_RESET_S; -- auto reset
                        when others => null;
                    end case;
                end if;
            end if;
        end process;
end architecture;



