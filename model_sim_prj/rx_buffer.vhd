library ieee;
    use ieee.std_logic_1164.all;

entity rx_buff is
    generic(
        WORD_SIZE   : natural := 7; -- UART word size (W = 7) - does not count the parity bit
        PARITY_RESULT : std_logic := '0' -- UART parity result (P = even)
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        en    : in std_logic;
        data_in         : in std_logic_vector(WORD_SIZE downto 0);
        data_ready_in   : in std_logic;
        buff_clear_in   : in std_logic;
        y_out               : out std_logic_vector(WORD_SIZE-1 downto 0);
        parity_error_out    : out std_logic

    );
end entity;

architecture struct of rx_buff is

    type rx_buff_fsm_state_t is
    (
        RESET_S,
        WAIT_DATA_S,
        COPY_DATA_S,
        OUTPUT_S,
        WAIT_CLEAR_S
    );
    signal rx_buff_fsm_state    : rx_buff_fsm_state_t := RESET_S;
    signal data_buffer          : std_logic_vector(WORD_SIZE downto 0) := (others => '0');
    signal xor_in               : std_logic_vector(WORD_SIZE downto 0) := (others => '0');
    signal xor_out               : std_logic := '0';

    component xor_8_b is
        port (
            A     : in std_logic_vector(7 downto 0);
            X     : out std_logic
            );
    end component;

    begin

        xor_DUT: xor_8_b
            port map(
            A => xor_in,
            X => xor_out
            );

        xor_in <= data_in;

        p_rx_synch_fsm : process(clk, rst)
        begin
            if rst = '0' then -- reset active low
                rx_buff_fsm_state <= RESET_S;
                data_buffer <= (others => '0');
                y_out       <= (others => '0');
                parity_error_out  <= '0';
                xor_in <= (others => '0');

            elsif rising_edge(clk) then
                if en = '1' then
                    case rx_buff_fsm_state is
                        when RESET_S =>
                            if data_ready_in = '0' then
                                rx_buff_fsm_state <= WAIT_DATA_S;
                            end if;
                        when WAIT_DATA_S =>
                            parity_error_out <= '0';
                            if data_ready_in = '1' then
                                rx_buff_fsm_state <= COPY_DATA_S;
                            end if;
                        when COPY_DATA_S =>
                            data_buffer <= data_in;
                            rx_buff_fsm_state <= OUTPUT_S;

                        when OUTPUT_S =>
                            rx_buff_fsm_state <= WAIT_CLEAR_S;
                            if xor_out = PARITY_RESULT then
                                y_out <= data_buffer(WORD_SIZE-1 downto 0);
                            else
                                y_out <= (others => '1');
                                parity_error_out <= '1';
                            end if;

                        when WAIT_CLEAR_S =>
                            if buff_clear_in = '1' then
                                rx_buff_fsm_state <= WAIT_DATA_S;
                                data_buffer <= (others => '0');
                            end if;

                        when others => null;
                    end case;
                end if;
            end if;
        end process;
end architecture;
