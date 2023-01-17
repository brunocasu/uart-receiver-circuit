library IEEE;
  use IEEE.std_logic_1164.all;

-- testbench file
entity tb_rx_synch is
end entity;

architecture bhv of tb_rx_synch is

  constant SYS_CLK    : time    := 100 ns;
  constant RESET_TIME : time    := 200 ns;
  constant OS_RATE    : natural := 8;
  constant FRAME_SIZE : natural := 11; -- fixed for W=7 and S=2

  signal clk_tb       : std_logic := '0';
  signal rst_tb       : std_logic := '0';
  signal rx_tb        : std_logic := '1';
  signal en_tb        : std_logic := '1';
  signal data_out_tb : std_logic_vector(7 downto 0) := (others => '0'); -- fixed for W=7
  signal end_sim      : std_logic := '1';

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
        data_out    : out std_logic_vector(WORD_SIZE downto 0); -- parallel output includes parity bit
        data_ready_out  : out std_logic;
        frame_start_out : out std_logic;
        frame_stop_out  : out std_logic;
        frame_error_out : out std_logic
    );
  end component;

begin
  clk_tb <= (not(clk_tb) and end_sim) after SYS_CLK / 2;
  rst_tb <= '1' after RESET_TIME;

  rx_synch_DUT: rx_synch
    -- generic map ()
    port map (
      clk       => clk_tb,
      rst       => rst_tb,
      en        => en_tb,
      rx        => rx_tb,
      data_out      => data_out_tb
      --data_ready_out
      --frame_start_out
      --frame_stop_out
      --frame_error_out
    );

  stimuli: process(clk_tb, rst_tb)
    variable test_counter : integer := 0;

  begin
    if (rst_tb = '0') then
      rx_tb <= '1';
      test_counter := 0;
    elsif (rising_edge(clk_tb)) then

      case(test_counter) is
        when 1  => rx_tb  <= '0'; -- start bit
        when 9  => rx_tb  <= '1'; -- w0
        when 17 => rx_tb  <= '0'; -- w1
        when 25 => rx_tb  <= '1'; -- w2
        when 33 => rx_tb  <= '0'; -- w3
        when 41 => rx_tb  <= '1'; -- w4
        when 49 => rx_tb  <= '0'; -- w5
        when 57 => rx_tb  <= '1'; -- w6
        when 65 => rx_tb  <= '0'; -- parity bit
        when 73 => rx_tb  <= '1'; -- stop 1
        when 81 => rx_tb  <= '1'; -- stop 2
        -- asynch TX
        when 189  => rx_tb  <= '0'; -- start bit
        when 197  => rx_tb  <= '1';-- w0
        when 205 => rx_tb   <= '0';-- w1
        when 213 => rx_tb   <= '1';-- w2
        when 221 => rx_tb   <= '0';-- w3
        when 229 => rx_tb   <= '1';-- w4
        when 237 => rx_tb   <= '0';-- w5
        when 245 => rx_tb   <= '1';-- w6
        when 253 => rx_tb   <= '0';-- parity bit
        when 261 => rx_tb   <= '1';-- stop 1 !!!FRAME ERROR!!!
        when 269 => rx_tb   <= '0';-- stop 2

        -- when 277 => rx_tb    <= '1';

        when 301 => rx_tb  <= '0'; -- start bit
        when 309 => rx_tb  <= '1'; -- w0
        when 317 => rx_tb  <= '0'; -- w1
        when 325 => rx_tb  <= '1'; -- w2
        when 333 => rx_tb  <= '0'; -- w3
        when 341 => rx_tb  <= '1'; -- w4
        when 349 => rx_tb  <= '0'; -- w5
        when 357 => rx_tb  <= '1'; -- w6
        when 365 => rx_tb  <= '0'; -- parity bit
        when 373 => rx_tb  <= '1'; -- stop 1
        when 381 => rx_tb  <= '1'; -- stop 2

        when 400 => end_sim  <= '0';
        when others => null;
      end case;

    test_counter := test_counter + 1;
    end if;
  end process;

end architecture;



