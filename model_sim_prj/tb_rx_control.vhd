library IEEE;
  use IEEE.std_logic_1164.all;

-- testbench file
entity tb_rx_control is
end entity;

architecture bhv of tb_rx_control is

  constant SYS_CLK    : time    := 100 ns;
  constant RESET_TIME : time    := 200 ns;
  constant WORD_SIZE : natural := 7;

  signal   clk_tb       : std_logic := '0';
  signal   rst_tb       : std_logic := '0';
  signal   rx_tb        : std_logic := '1';
  signal   frame_start_tb    : std_logic := '0';
  signal   frame_stop_tb     : std_logic := '0';
  signal   frame_error_tb    : std_logic := '0';
  signal   break_tb          : std_logic := '0';
  signal   parity_error_tb   : std_logic := '0';
  signal   end_sim      : std_logic := '1';

  component rx_control is
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
  end component;

begin
  clk_tb <= (not(clk_tb) and end_sim) after SYS_CLK / 2;
  rst_tb <= '1' after RESET_TIME;

  rx_control_DUT: rx_control
    -- generic map ()
    port map (
      clk       => clk_tb,
      rst       => rst_tb,
      rx        => rx_tb,
      frame_start      => frame_start_tb,
      frame_stop       => frame_stop_tb,
      frame_error      => frame_error_tb,
      break            => break_tb,
      parity_error     => parity_error_tb
    );

  stimuli: process(clk_tb, rst_tb)
    variable test_counter : integer := 0;

  begin
    if (rst_tb = '0') then
      frame_start_tb  <= '0';
      frame_stop_tb   <= '0';
      frame_error_tb  <= '0';
      break_tb        <= '0';
      parity_error_tb <= '0';
      test_counter := 0;

    elsif (rising_edge(clk_tb)) then

      case(test_counter) is
        when 5  => frame_start_tb  <= '1';
        when 6  => frame_start_tb  <= '0';
        when 20  => frame_stop_tb  <= '1';
        when 21  => frame_stop_tb  <= '0';

        when 25  => frame_start_tb  <= '1';
        when 26  => frame_start_tb  <= '0';
        when 36  => parity_error_tb <= '1';
        when 40  => frame_stop_tb  <= '1';
        when 41  => frame_stop_tb  <= '0';
        when 43  => parity_error_tb <= '0';

        when 55  => frame_start_tb  <= '1';
        when 56  => frame_start_tb  <= '0';
        when 60  => frame_error_tb  <= '1';
        when 61  => frame_error_tb  <= '0';


        when 85  => frame_start_tb  <= '1';
        when 86  => frame_start_tb  <= '0';
        when 89  => rx_tb <= '0';
        when 90  => frame_error_tb  <= '1';
        when 91  => frame_error_tb  <= '0';
        when 95  => break_tb        <= '1';
        when 100 => rx_tb  <= '1'; break_tb        <= '0';

        when 120 => end_sim  <= '0';
        when others => null;
      end case;

    test_counter := test_counter + 1;
    end if;
  end process;

end architecture;





