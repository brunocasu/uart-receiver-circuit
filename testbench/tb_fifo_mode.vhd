library IEEE;
  use IEEE.std_logic_1164.all;

-- testbench file
entity tb_uart_fifo is
end entity;

architecture bhv of tb_uart_fifo is

  constant SYS_CLK    : time    := 1085 ns;
  constant RESET_TIME : time    := 2000 ns;
  constant BIT_RATE   : natural := 115200;
  constant OS_RATE    : natural := 8;
  constant WORD_SIZE  : natural := 7;
  constant FRAME_SIZE : natural := 11; -- fixed for W=7 and S=2

  signal clk_tb       : std_logic := '0';
  signal rst_tb       : std_logic := '0';
  signal rx_tb        : std_logic := '1';
  signal y_valid_tb   : std_logic := '0';
  signal fifo_in_tb   : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
  signal fifo_out_tb  : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
  signal end_sim      : std_logic := '1';

  component uart_rx is
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
  end component;

  component fifo is
    generic (
      DEPTH      : natural := 6;
      DATA_WIDTH : natural := 7
    );
    port(
      clk      : in std_logic;
      a_rst_n  : in std_logic;
      data_in  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;



begin
  clk_tb <= (not(clk_tb) and end_sim) after SYS_CLK / 2 ; -- sample clock
  rst_tb <= '1' after RESET_TIME;

  uart_rx_DUT: uart_rx
    generic map (
        WORD_SIZE => WORD_SIZE
    )
    port map (
      clk       => clk_tb,
      rst       => rst_tb,
      rx        => rx_tb,
      y_valid   => y_valid_tb,
      y         => fifo_in_tb
    );

  fifo_DUT: fifo
    port map(
      clk       => y_valid_tb, -- FIFO insertions are based on the data validation output
      a_rst_n   => rst_tb,
      data_in   => fifo_in_tb,
      data_out  => fifo_out_tb
    );

  stimuli: process(clk_tb, rst_tb)
    variable test_counter : integer := 0;
    variable sim_counter : integer := 0;

  begin
    if (rst_tb = '0') then
      rx_tb <= '1';
      test_counter := 0;
      sim_counter  := 0;
    elsif (rising_edge(clk_tb)) then

          case(test_counter) is
            -- regular word transmission
            when 8 => rx_tb  <= '0'; -- start bit (w = 0x1c  - 0011100)
            when 16 => rx_tb  <= '0'; -- w0
            when 24 => rx_tb  <= '0'; -- w1
            when 32 => rx_tb  <= '1'; -- w2
            when 40 => rx_tb  <= '1'; -- w3
            when 48 => rx_tb  <= '1'; -- w4
            when 56 => rx_tb  <= '0'; -- w5
            when 64 => rx_tb  <= '0'; -- w6
            when 72 => rx_tb  <= '1'; -- parity bit
            when 80 => rx_tb  <= '1'; -- stop 1
            when 88 => rx_tb  <= '1'; -- stop 2
            -- sequenced TX
            when 96  => rx_tb  <= '0'; -- start bit (w = 0x20 - 0100000)
            when 104 => rx_tb  <= '0'; -- w0
            when 112 => rx_tb  <= '0'; -- w1
            when 120 => rx_tb  <= '0'; -- w2
            when 128 => rx_tb  <= '0'; -- w3
            when 136 => rx_tb  <= '0'; -- w4
            when 144 => rx_tb  <= '1'; -- w5
            when 152 => rx_tb  <= '0'; -- w6
            when 160 => rx_tb  <= '1'; -- parity bit
            when 168 => rx_tb  <= '1'; -- stop 1
            when 176 => rx_tb  <= '1'; -- stop 2
            -- sequenced TX
            when 184  => rx_tb  <= '0'; -- start bit (w = 0x3f - 0111111)
            when 192 => rx_tb  <= '1'; -- w0
            when 200 => rx_tb  <= '1'; -- w1
            when 208 => rx_tb  <= '1'; -- w2
            when 216 => rx_tb  <= '1'; -- w3
            when 224 => rx_tb  <= '1'; -- w4
            when 232 => rx_tb  <= '1'; -- w5
            when 240 => rx_tb  <= '0'; -- w6
            when 248 => rx_tb  <= '0'; -- parity bit
            when 256 => rx_tb  <= '1'; -- stop 1
            when 264 => rx_tb  <= '1'; -- stop 2
            -- sequenced TX
            when 272  => rx_tb  <= '0'; -- start bit (w = 0x4f - 1001111)
            when 280 => rx_tb  <= '1'; -- w0
            when 288 => rx_tb  <= '1'; -- w1
            when 296 => rx_tb  <= '1'; -- w2
            when 304 => rx_tb  <= '1'; -- w3
            when 312 => rx_tb  <= '0'; -- w4
            when 320 => rx_tb  <= '0'; -- w5
            when 328 => rx_tb  <= '1'; -- w6
            when 336 => rx_tb  <= '1'; -- parity bit
            when 344 => rx_tb  <= '1'; -- stop 1
            when 352 => rx_tb  <= '1'; -- stop 2
            -- sequenced TX
            when 360  => rx_tb  <= '0'; -- start bit (w = 0x5e - 1011110)
            when 368 => rx_tb  <= '0'; -- w0
            when 376 => rx_tb  <= '1'; -- w1
            when 384 => rx_tb  <= '1'; -- w2
            when 392 => rx_tb  <= '1'; -- w3
            when 400 => rx_tb  <= '1'; -- w4
            when 408 => rx_tb  <= '0'; -- w5
            when 416 => rx_tb  <= '1'; -- w6
            when 424 => rx_tb  <= '1'; -- parity bit
            when 432 => rx_tb  <= '1'; -- stop 1
            when 440 => rx_tb  <= '1'; -- stop 2
            -- sequenced TX
            when 448  => rx_tb  <= '0'; -- start bit (w = 0x6e - 1101110)
            when 456 => rx_tb  <= '0'; -- w0
            when 464 => rx_tb  <= '1'; -- w1
            when 472 => rx_tb  <= '1'; -- w2
            when 480 => rx_tb  <= '1'; -- w3
            when 488 => rx_tb  <= '0'; -- w4
            when 496 => rx_tb  <= '1'; -- w5
            when 504 => rx_tb  <= '1'; -- w6
            when 512 => rx_tb  <= '1'; -- parity bit
            when 520 => rx_tb  <= '1'; -- stop 1
            when 528 => rx_tb  <= '1'; -- stop 2

            when 537 => test_counter  := 0; sim_counter := sim_counter + 1;
            when others => null;
          end case;
          test_counter := test_counter + 1;
          if sim_counter = 1 then
              end_sim  <= '0';
          end if;

    end if;
  end process;

end architecture;




