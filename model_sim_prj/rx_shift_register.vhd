library ieee;
  use ieee.std_logic_1164.all;

entity rx_shift_register is
  generic (
    word_size : natural := 7; -- Number of bits (W)
    stop_bits : natural := 2 -- Number of stop bits (S)
  );
  port (
    clk    : in std_logic;
    rst    : in std_logic;
    en     : in std_logic;
    rx     : in std_logic;
    rx_parallel_out     : out std_logic_vector(word_size downto 0); -- parallel output (word + parity bit)
    rx_buff_register_en : out std_logic
end entity;

architecture struct of rx_shift_register is
begin

  p_rx_shift_register : process(clk, arstn)
  begin
    if rst = '0' then -- reset active low
      rx_parallel_out <= (others => '0');
      rx_buff_register_en <= '0';
    elsif rising_edge(clk) then
      if en = '1' then
        --
      end if;
    end if;
  end process;

end architecture;


