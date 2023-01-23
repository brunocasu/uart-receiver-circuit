library ieee;
  use ieee.std_logic_1164.all;

entity xor_8_b is
  port (
    A     : in std_logic_vector(7 downto 0);
    X     : out std_logic
  );
end entity;

architecture behavioral of xor_8_b is
begin
X <= A(0) xor
     A(1) xor
     A(2) xor
     A(3) xor
     A(4) xor
     A(5) xor
     A(6) xor
     A(7);

end behavioral;



