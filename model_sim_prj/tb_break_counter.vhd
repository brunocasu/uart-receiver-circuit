library IEEE;
  use IEEE.std_logic_1164.all;

-- testbench file
entity tb_break_counter is
end entity;

architecture bhv of tb_break_counter is

  constant SYS_CLK    : time    := 100 ns;
  constant RESET_TIME : time    := 100 ns;
  constant BREAK      : natural := 11;

  signal clk_tb       : std_logic := '0';
  signal rst_tb       : std_logic := '0';
  signal rx_tb        : std_logic := '1';
  signal out_tb       : std_logic := '0';
  signal end_sim      : std_logic := '1';

  component break_counter is
    generic(
        OS_RATE     : natural := 8; -- clock over sampling rate (UART bit rate B = 115200)
        BREAK_COUNT : natural := 11 -- number of consecutive '0's to detect a BREAK
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;
        rx    : in std_logic;
        status  : out std_logic
    );
  end component;

begin
  clk_tb <= (not(clk_tb) and end_sim) after SYS_CLK / 2;
  rst_tb <= '1' after RESET_TIME;

  break_counter_DUT: break_counter
    generic map (BREAK_COUNT => BREAK)
    port map (
      clk       => clk_tb,
      rst       => rst_tb,
      rx        => rx_tb,
      status    => out_tb
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
        when 9  => rx_tb  <= '0'; -- w0
        when 17 => rx_tb  <= '0'; -- w1
        when 25 => rx_tb  <= '0'; -- w2
        when 33 => rx_tb  <= '0'; -- w3
        when 41 => rx_tb  <= '0'; -- w4
        when 49 => rx_tb  <= '0'; -- w5
        when 57 => rx_tb  <= '0'; -- w6
        when 65 => rx_tb  <= '0'; -- parity bit
        when 73 => rx_tb  <= '0'; -- stop 1
        when 81 => rx_tb  <= '0'; -- stop 2

        when 89  => rx_tb   <= '1'; -- start bit
        when 97  => rx_tb   <= '1';-- w0
        when 105 => rx_tb   <= '1';-- w1
        when 113 => rx_tb   <= '1';-- w2
        when 121 => rx_tb   <= '1';-- w3
        when 129 => rx_tb   <= '1';-- w4
        when 137 => rx_tb   <= '1';-- w5
        when 145 => rx_tb   <= '1';-- w6
        when 153 => rx_tb   <= '1';-- parity bit
        when 161 => rx_tb   <= '0';-- stop 1
        when 169 => rx_tb   <= '0';-- stop 2

        when 177 => rx_tb    <= '1';
        when 180 => end_sim  <= '0';
        when others => null;
      end case;

      test_counter := test_counter + 1;

    end if;
  end process;

end architecture;


