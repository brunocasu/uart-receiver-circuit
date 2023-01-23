library ieee;
  use ieee.std_logic_1164.all;

  -- Module from Electronics Systems Course Laboratory (UNIPI) 2022

entity dff_n is
  generic (
    N : natural := 8
  );
  port (
    clk   : in std_logic;
    arstn : in std_logic;
    en    : in std_logic;
    d     : in std_logic_vector(N - 1 downto 0);
    q     : out std_logic_vector(N - 1 downto 0)
  );
end entity;

architecture struct of dff_n is
begin

  p_dff_n : process(clk, arstn)
  begin
    if arstn = '0' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        q <= d;
      end if;
    end if;
  end process;

end architecture;


