library ieee;
  use ieee.std_logic_1164.all;

entity uart_rx is
  generic(
        WORD_SIZE   : natural := 7 -- UART word size (W = 7)
    );
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    rx    : in std_logic;
    y_valid     : out std_logic;
    y           : out std_logic_vector(WORD_SIZE - 1 downto 0)
  );
end entity;

architecture struct of uart_rx is

  component rx_control is
      port (
          clk   : in std_logic;
          rst   : in std_logic;
          rx    : in std_logic;
          frame_start    : in std_logic;
          frame_stop     : in std_logic;
          frame_error    : in std_logic;
          break_error    : in std_logic;
          parity_error   : in std_logic;
          y_valid_out       : out std_logic;
          synch_enable_out  : out std_logic;
          synch_reset_out   : out std_logic;
          buff_enable_out   : out std_logic;
          buff_reset_out    : out std_logic;
          buff_clear_out    : out std_logic
    );
  end component;

  component rx_synch is
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
  end component;

  component rx_buff is
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
  end component;

  component break_counter is
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
  end component;
  -- envelope signals
  signal env_clk : std_logic := '0';
  signal env_rst : std_logic := '0';
  signal env_rx : std_logic := '0';

  signal env_uart_synch_rst : std_logic := '0';
  signal env_frame_start    : std_logic := '0';
  signal env_frame_stop     : std_logic := '0';
  signal env_frame_error    : std_logic := '0';
  signal env_uart_data_ready : std_logic := '0';
  signal env_uart_data      : std_logic_vector(WORD_SIZE downto 0) := (others => '0');
  signal env_buff_clear     : std_logic := '0';
  signal env_uart_buff_rst  : std_logic := '0';
  signal env_parity_error   : std_logic := '0';
  signal env_break_error    : std_logic := '0';
  signal env_y_valid        : std_logic := '0';
  signal env_y              : std_logic_vector(WORD_SIZE - 1 downto 0) := (others => '0');

  begin
    -- Control Block: controls the states of the UART rx, and provides the data validation output
    -- The data is considred valid once the Stop signal indicates the end of a frame, and there is no parity error
    -- If a Frame error is detected the UART internal modules are RESET
    control_DUT: rx_control
      port map(
         clk              => env_clk,
         rst              => env_rst,
         rx               => env_rx,
         frame_start      => env_frame_start,
         frame_stop       => env_frame_stop,
         frame_error      => env_frame_error,
         break_error      => env_break_error,
         parity_error     => env_parity_error,
         y_valid_out      => env_y_valid,
         -- synch_enable_out =>
         synch_reset_out  => env_uart_synch_rst,
         -- buff_enable_out  =>
         buff_reset_out   => env_uart_buff_rst,
         buff_clear_out   => env_buff_clear

      );
    -- Synch Block: is a shift register for the UART rx input, detecting the start and end of the sent frames
    -- An internal counter is set to sample the UART rx input with a given Over Sampling Rate, coping the data to a parallel output
    -- Once the Word is received the block generates a data ready signal to the buffer
    -- If the start or stop conditons are violated, the block generates a frame error
    synch_DUT: rx_synch
      port map(
        clk             => env_clk,
        rst             => env_uart_synch_rst,
        en              => '1',
        rx              => env_rx,
        shift_reg_out   => env_uart_data,
        data_ready_out  => env_uart_data_ready,
        frame_start_out => env_frame_start,
        frame_stop_out  => env_frame_stop,
        frame_error_out => env_frame_error

      );

    -- Buff Block: is a Buffer that holds the received Word and check the data parity
    -- Once a data ready signal is received, the block will copiy the parallel input data from the synch block
    -- A parity error signal is raised if the xor operation of the bits from the parallel input do not match the UART configuration
    -- After the parity check the output (y) gets the word data from the buffer (if there is a parity error the output is set to '1111111')
    -- The buffer returns to Idle only when the control block raises a clear signal (the output is kept after the clear)
    buff_DUT: rx_buff
      port map(
        clk              => env_clk,
        rst              => env_uart_buff_rst,
        en               => '1',
        data_in          => env_uart_data,
        data_ready_in    => env_uart_data_ready,
        buff_clear_in    => env_buff_clear,
        y_out            => env_y,
        parity_error_out => env_parity_error

      );


    -- Break Block: independant bit counter  to detect when the UART rx input remains in the Space (0) state
    -- Once the 11 bit '0' is sampled, the Break condition is detected
    -- On the current implementation, the Break condition does not affect the behaivior of the internal blocks (only indicative)
    break_DUT: break_counter
      port map(
        clk              => env_clk,
        rst              => env_rst,
        en               => '1',
        rx               => env_rx,
        break_error_out  => env_break_error

      );

    env_clk <= clk;
    env_rst <= rst;
    env_rx  <= rx;
    y_valid <= env_y_valid;
    y       <= env_y;

end architecture;


