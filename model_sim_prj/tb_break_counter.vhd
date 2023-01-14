library IEEE;
  use IEEE.std_logic_1164.all;

entity tb_break_counter is  -- The testbench has no interface, so it is an empty entity (Be careful: the keyword "is" was missing in the code written in class).
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

  component break_counter is  -- be careful, it is only a component declaration. The component shall be instantiated after the keyword "begin" by linking the gates with the testbench signals for the test
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

  clk_tb <= (not(clk_tb) and end_sim) after SYS_CLK / 2;  -- The clock toggles after T_CLK / 2 when end_sim is high. When end_sim is forced low, the clock stops toggling and the simulation ends.
  rst_tb <= '1' after RESET_TIME;

  break_counter_DUT: break_counter
    generic map (BREAK_COUNT => BREAK)
    port map (
      clk       => clk_tb,
      rst       => rst_tb,
      rx        => rx_tb,
      status    => out_tb
    );

  stimuli: process(clk_tb, rst_tb)  -- process used to make the testbench signals change synchronously with the rising edge of the clock
    variable t : integer := 0;  -- variable used to count the clock cycle after the reset
  begin
    if (rst_tb = '0') then
      rx_tb <= '1';
      t := 0;
    elsif (rising_edge(clk_tb)) then

      case(t) is   -- specifying the input increment_tb and end_sim depending on the value of t ( and so on the number of the passed clock cycles).

        when 1  => rx_tb    <= '0'; -- start bit
        when 8  => rx_tb    <= '0'; -- w0
        when 16  => rx_tb   <= '0'; -- w1
        when 24 => rx_tb    <= '0'; -- w2
        when 32 => rx_tb    <= '0'; -- w3
        when 40  => rx_tb   <= '0'; -- w4
        when 48  => rx_tb   <= '0'; -- w5
        when 56  => rx_tb   <= '0'; -- w6
        when 64 => rx_tb    <= '0'; -- parity bit
        when 72 => rx_tb    <= '0'; -- stop 1
        when 80  => rx_tb   <= '0'; -- stop 2

        when 88  => rx_tb    <= '0'; -- start bit
        when 96  => rx_tb    <= '1';-- w0
        when 104 => rx_tb    <= '1';-- w1
        when 112  => rx_tb   <= '0';-- w2
        when 120 => rx_tb    <= '0';-- w3
        when 128 => rx_tb    <= '0';-- w4
        when 136  => rx_tb   <= '0';-- w5
        when 144  => rx_tb   <= '0';-- w6
        when 152  => rx_tb   <= '0';-- parity bit
        when 160 => rx_tb    <= '1';-- stop 1
        when 168 => rx_tb    <= '1';-- stop 2

        when 180 => end_sim <= '0';  -- This command stops the simulation
        when others => null;  -- Specifying that nothing happens in the other cases
      end case;

      t := t + 1;  -- the variable is updated exactly here (try to move this statement before the "case(t) is" one and watch the difference in the simulation)

    end if;
  end process;

end architecture;


