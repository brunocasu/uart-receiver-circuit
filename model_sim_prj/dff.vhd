library ieee;
  use ieee.std_logic_1164.all;

entity dff is
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    en    : in std_logic; -- enable signal
    d     : in std_logic;
    q     : out std_logic
  );
end entity;

architecture struct of dff is
begin

  p_dff_n : process(clk, rst)
  begin
    if rst = '0' then -- reset active low
      q <= '0';
    elsif rising_edge(clk) then
      if en = '1' then
        q <= d;
      end if;
    end if;
  end process;

end architecture;


