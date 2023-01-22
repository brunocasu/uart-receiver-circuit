library IEEE;
  use IEEE.std_logic_1164.all;

-- testbench file
entity tb_rx_buff is
end entity;

architecture bhv of tb_rx_buff is

  constant SYS_CLK    : time    := 100 ns;
  constant RESET_TIME : time    := 200 ns;
  constant WORD_SIZE : natural := 7;

  signal   clk_tb       : std_logic := '0';
  signal   rst_tb       : std_logic := '0';
  signal   en_tb        : std_logic := '1';
  signal   data_in_tb       : std_logic_vector(7 downto 0) := (others => '0'); -- fixed for W=7
  signal   data_ready_tb    : std_logic := '0';
  signal   clear_buff_tb    : std_logic := '0';
  signal   end_sim      : std_logic := '1';

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
        data_buffer_out     : out std_logic_vector(WORD_SIZE-1 downto 0);
        parity_error_out    : out std_logic

    );
  end component;

begin
  clk_tb <= (not(clk_tb) and end_sim) after SYS_CLK / 2;
  rst_tb <= '1' after RESET_TIME;

  rx_buff_DUT: rx_buff
    -- generic map ()
    port map (
      clk       => clk_tb,
      rst       => rst_tb,
      en        => en_tb,
      data_in           => data_in_tb,
      data_ready_in     => data_ready_tb,
      buff_clear_in     => clear_buff_tb

    );

  stimuli: process(clk_tb, rst_tb)
    variable test_counter : integer := 0;

  begin
    if (rst_tb = '0') then
      data_in_tb <= (others => '0');
      data_ready_tb <= '0';
      clear_buff_tb <= '0';
      test_counter := 0;
    elsif (rising_edge(clk_tb)) then

      case(test_counter) is
        when 5  => data_in_tb  <= "01010101";
        when 6  => data_ready_tb <= '1';
        when 7  => data_ready_tb <= '0';
        when 10 => data_ready_tb <= '0'; clear_buff_tb <= '1';
        when 12 => clear_buff_tb <= '0';

        when 15 => data_in_tb  <= "00010000"; -- parity error
        when 16 => data_ready_tb <= '1';
        when 17  => data_ready_tb <= '0';
        when 23 => data_ready_tb <= '0';
        when 27 => clear_buff_tb <= '1';
        when 28 => clear_buff_tb <= '0';

        when 35  => data_in_tb  <= "11000011";
        when 36  => data_ready_tb <= '1';
        when 37  => data_ready_tb <= '0';
        when 40 => data_ready_tb <= '0';
        when 50 => clear_buff_tb <= '1';
        when 51 => clear_buff_tb <= '0';

        when 55 => end_sim  <= '0';
        when others => null;
      end case;

    test_counter := test_counter + 1;
    end if;
  end process;

end architecture;




