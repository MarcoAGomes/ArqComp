--------------------------------------------------------------------------------
-- Somador/Subtrator Vetorial AVX (4, 8, 16 ou 32 bits)
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity SomadorVetorialAVX is
  port (
    A_i: in std_logic_vector(31 downto 0);
    B_i: in std_logic_vector(31 downto 0);
    mode_i: in std_logic;
    vecSize_i: in std_logic_vector(1 downto 0);
    S_o: out std_logic_vector(31 downto 0));
end SomadorVetorialAVX;

architecture structural of SomadorVetorialAVX is
  component ALU4bits is
    port (
      X: in std_logic_vector(3 downto 0);
      Y: in std_logic_vector(3 downto 0);
      op_selector: in std_logic;
      Cin: in std_logic;
      carry_in_enable: in std_logic;
      resultado: out std_logic_vector (3 downto 0);
      Cout: out std_logic);
  end component;

  signal carry_in_enable: std_logic_vector (7 downto 0);
  signal carry: std_logic_vector (8 downto 0);

begin
  carry_in_enable(0) <= '0';
  carry(0) <= '0';

  -- Habilita carry entre blocos para 8, 16 ou 32 bits
  carry_in_enable(1) <= vecSize_i(1) OR vecSize_i(0);
  carry_in_enable(3) <= carry_in_enable(1);
  carry_in_enable(5) <= carry_in_enable(3);
  carry_in_enable(7) <= carry_in_enable(5); 

  -- Habilita carry adicional para 16 ou 32 bits
  carry_in_enable(2) <= vecSize_i(1);
  carry_in_enable(6) <= carry_in_enable(2);

  -- Habilita carry para 32 bits
  carry_in_enable(4) <= vecSize_i(1) AND vecSize_i(0);

  alu_gen: for i in 0 to 7 generate
    alu_inst: ALU4bits port map(
      A_i(i*4+3 downto i*4),
      B_i(i*4+3 downto i*4),
      mode_i,
      carry(i),
      carry_in_enable(i),
      S_o(i*4+3 downto i*4),
      carry(i+1));
  end generate alu_gen;
end structural;

--------------------------------------------------------------------------------
-- ALU4bits: 4 bits ALU para soma/subtração com carry chain controlado
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity ALU4bits is
  port (
    X: in std_logic_vector (3 downto 0);
    Y: in std_logic_vector (3 downto 0);
    op_selector: in std_logic;
    Cin: in std_logic;
    carry_in_enable: in std_logic;
    resultado: out std_logic_vector (3 downto 0); 
    Cout: out std_logic);
end ALU4bits;

architecture structural of ALU4bits is
  component Somador4Bit is
    port (
      X: in std_logic_vector (3 downto 0);
      Y: in std_logic_vector (3 downto 0);
      Cin: in std_logic;
      S: out std_logic_vector (3 downto 0);
      Cout: out std_logic);
  end component;
  component MUX21_4Bits is
    port (
      X: in std_logic_vector (3 downto 0);
      Y: in std_logic_vector (3 downto 0);
      op_selector:  in std_logic;
      saida:   out std_logic_vector (3 downto 0));
  end component;
  signal operando_2: std_logic_vector (3 downto 0);
  signal cin_somador: std_logic;

begin
  -- Subtrai: operando_2 = NOT Y se op_selector = 1
  MUX_21: MUX21_4Bits port map(Y, NOT Y, op_selector, operando_2);

  -- Define o carry-in: inicia com '1' em subtração isolada, propaga carry se permitido
  cin_somador <= (NOT (carry_in_enable) AND op_selector) OR (carry_in_enable AND Cin);

  -- Executa soma/sub com carry
  ALU_4BIT: Somador4Bit port map (X, operando_2, cin_somador, resultado, Cout); 	
end structural;

--------------------------------------------------------------------------------
-- Somador4Bit: Somador de 4 bits com carry in/out
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity Somador4Bit is
  port (
    X:  in std_logic_vector (3 downto 0);
    Y: in std_logic_vector (3 downto 0);
    Cin: in std_logic;
    S: out std_logic_vector (3 downto 0);
    Cout: out std_logic);
end Somador4Bit;

architecture structural of Somador4Bit is
  component FullAdder1bit is
    port (
    A: in std_logic;
    B: in std_logic;
    Cin: in std_logic;
    S: out std_logic;
    Cout: out std_logic);
  end component;
  
  signal c1: std_logic;
  signal c2: std_logic;
  signal c3: std_logic;
begin
  fa1: FullAdder1bit port map (X(0), Y(0), Cin, S(0), c1);
  fa2: FullAdder1bit port map (X(1), Y(1), c1, S(1), c2);
  fa3: FullAdder1bit port map (X(2), Y(2), c2, S(2), c3);
  fa4: FullAdder1bit port map (X(3), Y(3), c3, S(3), Cout);
end structural;

--------------------------------------------------------------------------------
-- MUX21_4Bits: Multiplexador 2:1 de 4 bits
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity MUX21_4Bits is
  port (
    X: in std_logic_vector (3 downto 0);
    Y: in std_logic_vector (3 downto 0);
    op_selector: in std_logic;
    saida:  out std_logic_vector (3 downto 0));
end MUX21_4Bits;

architecture behavioral of MUX21_4Bits is
begin
  saida <= (X AND NOT (op_selector & op_selector & op_selector & op_selector)) OR
           (Y AND (op_selector & op_selector & op_selector & op_selector));
end behavioral;

--------------------------------------------------------------------------------
-- FullAdder1bit: Somador completo de 1 bit
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity FullAdder1bit is
  port (
    A: in std_logic;
    B: in std_logic;
    Cin: in std_logic;
    S: out std_logic;
    Cout: out std_logic);
end FullAdder1bit;

architecture dataflow of FullAdder1bit is
begin
  S <= A XOR B XOR Cin;
  Cout <= (A AND B) OR (B AND Cin) OR (A AND Cin);
end dataflow;
