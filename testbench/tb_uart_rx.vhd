library IEEE;
  use IEEE.std_logic_1164.all;

-- testbench file
entity tb_uart_rx is
end entity;

architecture bhv of tb_uart_rx is

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
  signal y_tb         : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0'); -- fixed for W=7
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
      y         => y_tb
    );

  stimuli: process(clk_tb, rst_tb)
    variable test_counter : integer := 0;

  begin
    if (rst_tb = '0') then
      rx_tb <= '1';
      test_counter := 0;
    elsif (rising_edge(clk_tb)) then

      case(test_counter) is
        -- regular word transmission
        when 9   => rx_tb  <= '0'; -- start bit (w = 0x55)
        when 17 => rx_tb  <= '1'; -- w0
        when 25 => rx_tb  <= '0'; -- w1
        when 33 => rx_tb  <= '1'; -- w2
        when 41 => rx_tb  <= '0'; -- w3
        when 49 => rx_tb  <= '1'; -- w4
        when 57 => rx_tb  <= '0'; -- w5
        when 65 => rx_tb  <= '1'; -- w6
        when 73 => rx_tb  <= '0'; -- parity bit
        when 81 => rx_tb  <= '1'; -- stop 1
        when 90 => rx_tb  <= '1'; -- stop 2
        -- sequenced TX
        when 98   => rx_tb  <= '0'; -- start bit (w = 0x2a)
        when 106 => rx_tb  <= '0'; -- w0
        when 114 => rx_tb  <= '1'; -- w1
        when 122 => rx_tb  <= '0'; -- w2
        when 130 => rx_tb  <= '1'; -- w3
        when 138 => rx_tb  <= '0'; -- w4
        when 146 => rx_tb  <= '1'; -- w5
        when 154 => rx_tb  <= '0'; -- w6
        when 162 => rx_tb  <= '1'; -- parity bit
        when 170 => rx_tb  <= '1'; -- stop 1
        when 178 => rx_tb  <= '1'; -- stop 2

        -- asynch TX
        when 199  => rx_tb  <= '0'; -- start bit (w = 0x5f)
        when 207  => rx_tb  <= '1';-- w0
        when 215 => rx_tb   <= '1';-- w1
        when 223 => rx_tb   <= '1';-- w2
        when 231 => rx_tb   <= '1';-- w3
        when 239 => rx_tb   <= '1';-- w4
        when 247 => rx_tb   <= '0';-- w5
        when 255 => rx_tb   <= '1';-- w6
        when 263 => rx_tb   <= '0';-- parity bit
        when 271 => rx_tb   <= '0';-- stop 1 - !!!FRAME ERROR!!!
        when 289 => rx_tb   <= '1';-- stop 2

        -- asynch TX
        when 301 => rx_tb  <= '0'; -- start bit (w = 0x55)
        when 309 => rx_tb  <= '1'; -- w0
        when 317 => rx_tb  <= '0'; -- w1
        when 325 => rx_tb  <= '1'; -- w2
        when 333 => rx_tb  <= '0'; -- w3
        when 341 => rx_tb  <= '1'; -- w4
        when 349 => rx_tb  <= '0'; -- w5
        when 357 => rx_tb  <= '1'; -- w6
        when 365 => rx_tb  <= '1'; -- parity bit - !!!PARITY ERROR!!!
        when 373 => rx_tb  <= '1'; -- stop 1
        when 381 => rx_tb  <= '1'; -- stop 2

        -- BREAK
        when 401 => rx_tb  <= '0'; -- start bit
        when 409 => rx_tb  <= '0'; -- w0
        when 417 => rx_tb  <= '0'; -- w1
        when 425 => rx_tb  <= '0'; -- w2
        when 433 => rx_tb  <= '0'; -- w3
        when 441 => rx_tb  <= '0'; -- w4
        when 449 => rx_tb  <= '0'; -- w5
        when 457 => rx_tb  <= '0'; -- w6
        when 465 => rx_tb  <= '0'; -- parity bit
        when 473 => rx_tb  <= '0'; -- stop 1
        when 481 => rx_tb  <= '0'; -- stop 2

        when 490 => rx_tb  <= '1'; -- line release

        -- TX at Wrong Frequency (Bit rate > B=115200)
        when 501 => rx_tb  <= '0'; -- start bit (w = 0x2c)
        when 507 => rx_tb  <= '0'; -- w0
        when 513 => rx_tb  <= '0'; -- w1
        when 519 => rx_tb  <= '1'; -- w2
        when 525 => rx_tb  <= '1'; -- w3
        when 531 => rx_tb  <= '0'; -- w4
        when 537 => rx_tb  <= '1'; -- w5
        when 543 => rx_tb  <= '0'; -- w6
        when 549 => rx_tb  <= '1'; -- parity bit
        when 555 => rx_tb  <= '1'; -- stop 1
        when 561 => rx_tb  <= '1'; -- stop 2
        -- sequence
        when 567 => rx_tb  <= '0'; -- start bit (w = 0x4d)
        when 573 => rx_tb  <= '1'; -- w0
        when 579 => rx_tb  <= '0'; -- w1
        when 585 => rx_tb  <= '1'; -- w2
        when 591 => rx_tb  <= '1'; -- w3
        when 597 => rx_tb  <= '0'; -- w4
        when 603 => rx_tb  <= '1'; -- w5
        when 609 => rx_tb  <= '0'; -- w6
        when 615 => rx_tb  <= '0'; -- parity bit
        when 621 => rx_tb  <= '1'; -- stop 1
        when 627 => rx_tb  <= '1'; -- stop 2

        -- asynch
        -- TX at Wrong Frequency (Bit rate < B=115200)
        when 680 => rx_tb  <= '0'; -- start bit (w = 0x7f)
        when 690 => rx_tb  <= '1'; -- w0
        when 700 => rx_tb  <= '1'; -- w1
        when 710 => rx_tb  <= '1'; -- w2
        when 720 => rx_tb  <= '1'; -- w3
        when 730 => rx_tb  <= '1'; -- w4
        when 740 => rx_tb  <= '1'; -- w5
        when 750 => rx_tb  <= '1'; -- w6
        when 760 => rx_tb  <= '1'; -- parity bit
        when 770 => rx_tb  <= '1'; -- stop 1
        when 780 => rx_tb  <= '1'; -- stop 2
        -- sequence
        when 790 => rx_tb  <= '0'; -- start bit (w = 0x3a)
        when 800 => rx_tb  <= '0'; -- w0
        when 810 => rx_tb  <= '1'; -- w1
        when 820 => rx_tb  <= '0'; -- w2
        when 830 => rx_tb  <= '1'; -- w3
        when 840 => rx_tb  <= '1'; -- w4
        when 850 => rx_tb  <= '1'; -- w5
        when 860 => rx_tb  <= '0'; -- w6
        when 870 => rx_tb  <= '0'; -- parity bit
        when 880 => rx_tb  <= '1'; -- stop 1
        when 890 => rx_tb  <= '1'; -- stop 2

        when 1000 => end_sim  <= '0';
        when others => null;
      end case;

    test_counter := test_counter + 1;
    end if;
  end process;

end architecture;




