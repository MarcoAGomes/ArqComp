--------------------------------------------------------------------------------
-- Somador/Subtrator Vetorial AVX (4, 8, 16 ou 32 bits)
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY SomadorVetorialAVX IS
  PORT (
    A_i       : IN  std_logic_vector(31 DOWNTO 0);
    B_i       : IN  std_logic_vector(31 DOWNTO 0);
    mode_i    : IN  std_logic;  -- '0' para soma, '1' para subtração
    vecSize_i : IN  std_logic_vector(1 DOWNTO 0); -- 00=4 bits, 01=8 bits, 10=16 bits, 11=32 bits
    S_o       : OUT std_logic_vector(31 DOWNTO 0)
  );
END SomadorVetorialAVX;

ARCHITECTURE structural OF SomadorVetorialAVX IS

  COMPONENT ALU4bits IS
    PORT(
      X, Y            : IN  std_logic_vector(3 DOWNTO 0);
      seletor         : IN  std_logic;
      Cin             : IN  std_logic;
      carry_in_enable : IN  std_logic;
      resultado       : OUT std_logic_vector(3 DOWNTO 0);
      Cout            : OUT std_logic
    );
  END COMPONENT;

  SIGNAL carry_chain_enable : std_logic_vector(7 DOWNTO 0);
  SIGNAL carry             : std_logic_vector(8 DOWNTO 0);

BEGIN
  carry(0) <= '0';

  -- Define quais ALUs são conectadas em cadeia para formar o vetor do tamanho desejado
  WITH vecSize_i SELECT
    carry_chain_enable <=
      "00000000" WHEN "00", -- 4 bits (todos independentes)
      "01010101" WHEN "01", -- 8 bits (pares conectados)
      "00110011" WHEN "10", -- 16 bits (blocos de 4 conectados)
      "00001111" WHEN OTHERS; -- 32 bits (todos conectados)

  ALU_GEN: FOR i IN 0 TO 7 GENERATE
    ALU_INST : ALU4bits PORT MAP(
      X               => A_i((i*4)+3 DOWNTO i*4),
      Y               => B_i((i*4)+3 DOWNTO i*4),
      seletor         => mode_i,
      Cin             => carry(i),
      carry_in_enable => carry_chain_enable(i),
      resultado       => S_o((i*4)+3 DOWNTO i*4),
      Cout            => carry(i+1)
    );
  END GENERATE ALU_GEN;

END structural;

--------------------------------------------------------------------------------
-- ALU4bits: 4 bits ALU para soma/subtração com carry chain controlado
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY ALU4bits IS
  PORT (
    X, Y            : IN  std_logic_vector(3 DOWNTO 0);
    seletor         : IN  std_logic;  -- '0' soma, '1' subtração
    Cin             : IN  std_logic;
    carry_in_enable : IN  std_logic;  -- Controla se carry anterior é considerado
    resultado       : OUT std_logic_vector(3 DOWNTO 0);
    Cout            : OUT std_logic
  );
END ALU4bits;

ARCHITECTURE structural OF ALU4bits IS

  COMPONENT Somador4Bit IS
    PORT(
      X, Y : IN  std_logic_vector(3 DOWNTO 0);
      Cin  : IN  std_logic;
      S    : OUT std_logic_vector(3 DOWNTO 0);
      Cout : OUT std_logic
    );
  END COMPONENT;

  COMPONENT MUX21_4Bits IS
    PORT(
      X, Y    : IN  std_logic_vector(3 DOWNTO 0);
      seletor : IN  std_logic;
      saida   : OUT std_logic_vector(3 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL operando_2 : std_logic_vector(3 DOWNTO 0);
  SIGNAL cin_somador : std_logic;

BEGIN
  -- Inverte Y para subtração
  MUX_21: MUX21_4Bits PORT MAP(Y, NOT Y, seletor, operando_2);

  -- Lógica de carry-in considerando carry_in_enable e seletor (Add/Sub)
  cin_somador <= (NOT carry_in_enable AND seletor) OR (carry_in_enable AND Cin);

  ALU_4BIT: Somador4Bit PORT MAP(X, operando_2, cin_somador, resultado, Cout);

END structural;

--------------------------------------------------------------------------------
-- Somador4Bit: Somador de 4 bits com carry in/out
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Somador4Bit IS
  PORT (
    X, Y : IN std_logic_vector(3 DOWNTO 0);
    Cin  : IN std_logic;
    S    : OUT std_logic_vector(3 DOWNTO 0);
    Cout : OUT std_logic
  );
END Somador4Bit;

ARCHITECTURE structural OF Somador4Bit IS

  COMPONENT FullAdder1bit IS
    PORT(
      A, B, Cin : IN std_logic;
      S, Cout   : OUT std_logic
    );
  END COMPONENT;

  SIGNAL c1, c2, c3 : std_logic;

BEGIN
  FA1: FullAdder1bit PORT MAP(X(0), Y(0), Cin, S(0), c1);
  FA2: FullAdder1bit PORT MAP(X(1), Y(1), c1, S(1), c2);
  FA3: FullAdder1bit PORT MAP(X(2), Y(2), c2, S(2), c3);
  FA4: FullAdder1bit PORT MAP(X(3), Y(3), c3, S(3), Cout);

END structural;

--------------------------------------------------------------------------------
-- MUX21_4Bits: Multiplexador 2:1 de 4 bits
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY MUX21_4Bits IS
  PORT (
    X, Y    : IN std_logic_vector(3 DOWNTO 0);
    seletor : IN std_logic;
    saida   : OUT std_logic_vector(3 DOWNTO 0)
  );
END MUX21_4Bits;

ARCHITECTURE structural OF MUX21_4Bits IS
BEGIN
  saida(0) <= (NOT seletor AND X(0)) OR (seletor AND Y(0));
  saida(1) <= (NOT seletor AND X(1)) OR (seletor AND Y(1));
  saida(2) <= (NOT seletor AND X(2)) OR (seletor AND Y(2));
  saida(3) <= (NOT seletor AND X(3)) OR (seletor AND Y(3));
END structural;

--------------------------------------------------------------------------------
-- FullAdder1bit: Somador completo de 1 bit
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY FullAdder1bit IS
  PORT (
    A, B, Cin : IN std_logic;
    S, Cout   : OUT std_logic
  );
END FullAdder1bit;

ARCHITECTURE dataflow OF FullAdder1bit IS
BEGIN
  S <= Cin XOR (A XOR B);
  Cout <= (A AND Cin) OR (B AND Cin) OR (A AND B);
END dataflow;
