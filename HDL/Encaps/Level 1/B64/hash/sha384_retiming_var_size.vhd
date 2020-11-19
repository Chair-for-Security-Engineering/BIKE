----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    27/04/2020
-- LAST CHANGES:            29/04/2020
-- MODULE NAME:			    SHA384_RETIMING
--
-- REVISION:				1.10 - Added variable input size.
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or	if you have questions regarding the code
--							please contact Tim Gueneysu (tim.gueneysu@rub.de) and
--                          Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
-- KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
----------------------------------------------------------------------------------



-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.SHA_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY SHA384_RETIMING_VAR_SIZE IS
	PORT (  
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        DONE            : OUT STD_LOGIC;
        -- SIZE ------------------------
        SIZE            : IN  STD_LOGIC_VECTOR(19 DOWNTO 0);
        -- MESSAGE ---------------------
        M               : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        M_VALID         : IN  STD_LOGIC;
        M_RDY           : OUT STD_LOGIC;
        -- HASH ------------------------
        HASH            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        HASH_ADDR       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        HASH_VALID      : OUT STD_LOGIC
    );
END SHA384_RETIMING_VAR_SIZE;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF SHA384_RETIMING_VAR_SIZE IS



-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_RND_ENABLE, CNT_RND_RESET    : STD_LOGIC;
SIGNAL CNT_RND_DONE                     : STD_LOGIC;
SIGNAL CNT_RND_OUT                      : STD_LOGIC_VECTOR(LOG2(NUM_OF_ROUNDS)-1 DOWNTO 0);

SIGNAL CNT_WORDS_ENABLE, CNT_WORDS_RESET    : STD_LOGIC;
SIGNAL CNT_WORDS_DONE                     : STD_LOGIC;
SIGNAL CNT_WORDS_OUT                      : STD_LOGIC_VECTOR(14 DOWNTO 0);

SIGNAL CNT_OUT_ENABLE, CNT_OUT_RESET    : STD_LOGIC;
SIGNAL CNT_OUT_DONE                     : STD_LOGIC;
SIGNAL CNT_OUT_OUT                      : STD_LOGIC_VECTOR(3 DOWNTO 0);

SIGNAL CNT_M_ENABLE, CNT_M_RESET        : STD_LOGIC;
SIGNAL CNT_M_DONE                       : STD_LOGIC;
SIGNAL CNT_M_OUT                        : STD_LOGIC_VECTOR(4 DOWNTO 0);

SIGNAL CNT_OFFSET_ENABLE                : STD_LOGIC;
SIGNAL CNT_OFFSET_RESET                 : STD_LOGIC;
SIGNAL CNT_O15_OUT                      : STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL CNT_O2_OUT                       : STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL CNT_O16_OUT                      : STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL CNT_O7_OUT                       : STD_LOGIC_VECTOR(3 DOWNTO 0);

-- CONTROLLING
SIGNAL RECEIVE_M, M_COMPLETE            : STD_LOGIC;
SIGNAL M_IN, PADDING, M_PLUS_ONE        : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL M_LENGTH_STD                     : STD_LOGIC_VECTOR(127 DOWNTO 0);

SIGNAL S1, CH, TEMP1, S0, MAJ, TEMP2    : STD_LOGIC_VECTOR(63 DOWNTO 0);

SIGNAL W0, W1                           : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL W0_INT, W1_INT, W2_INT, W3_INT   : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL CURRENT_W_COM, CURRENT_W         : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL ADD1, ADD2                       : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL TEMP1_U0, TEMP1_U1, TEMP1_U2     : STD_LOGIC_VECTOR(64 DOWNTO 0);

-- ADDER
SIGNAL ADD_H_W_DINA, ADD_REG4_IN        : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL CH_IN0, CH_IN1, CH_IN2           : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL MA_IN0, MA_IN1, MA_IN2           : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL INT1, INT2, INT3, INT4           : STD_LOGIC_VECTOR(63 DOWNTO 0);

SIGNAL TEMP1_0, TEMP1_1, TEMP1_2        : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL CURRENT_K                        : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL CURRENT_W_U0, CURRENT_W_U1       : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL CURRENT_W_U, TEMP1_U             : STD_LOGIC_VECTOR(65 DOWNTO 0);

SIGNAL W_REG_RST                        : STD_LOGIC;
SIGNAL W_REG_EN_M                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL W_REG_EN_W                       : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL W_REG_EN                         : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL W_IN, W_OUT                      : WORD_ARRAY(0 TO 15);
SIGNAL WORKING_REG_IN, WORKING_REG_OUT  : WORD_ARRAY(0 TO 7);
SIGNAL COMPRESSION_IN                   : WORD_ARRAY(0 TO 7);

SIGNAL H_ENABLE, H_ENABLE1, H_ENABLE2   : STD_LOGIC;
SIGNAL H_OUT, H_IN, H_UPDATE            : WORD_ARRAY(0 TO 7);

SIGNAL HASH_OUT                         : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL NUM_OF_CHUNKS_VAR                : STD_LOGIC_VECTOR( 9 DOWNTO 0);
SIGNAL ADJUST_SIZE                      : STD_LOGIC_VECTOR(19 DOWNTO 0);
SIGNAL NUM_OF_WORDS                     : STD_LOGIC_VECTOR(14 DOWNTO 0);
SIGNAL M_BITS_LAST                      : STD_LOGIC_VECTOR( 4 DOWNTO 0);

-- K constants
SIGNAL K : WORD_ARRAY(0 TO 79) := (X"428a2f98d728ae22", X"7137449123ef65cd", X"b5c0fbcfec4d3b2f", X"e9b5dba58189dbbc", X"3956c25bf348b538", X"59f111f1b605d019", X"923f82a4af194f9b", X"ab1c5ed5da6d8118", X"d807aa98a3030242", X"12835b0145706fbe", X"243185be4ee4b28c", X"550c7dc3d5ffb4e2", X"72be5d74f27b896f", X"80deb1fe3b1696b1", X"9bdc06a725c71235", X"c19bf174cf692694", X"e49b69c19ef14ad2", X"efbe4786384f25e3", X"0fc19dc68b8cd5b5", X"240ca1cc77ac9c65", X"2de92c6f592b0275", X"4a7484aa6ea6e483", X"5cb0a9dcbd41fbd4", X"76f988da831153b5", X"983e5152ee66dfab", X"a831c66d2db43210", X"b00327c898fb213f", X"bf597fc7beef0ee4", X"c6e00bf33da88fc2", X"d5a79147930aa725", X"06ca6351e003826f", X"142929670a0e6e70", X"27b70a8546d22ffc", X"2e1b21385c26c926", X"4d2c6dfc5ac42aed", X"53380d139d95b3df", X"650a73548baf63de", X"766a0abb3c77b2a8", X"81c2c92e47edaee6", X"92722c851482353b", X"a2bfe8a14cf10364", X"a81a664bbc423001", X"c24b8b70d0f89791", X"c76c51a30654be30", X"d192e819d6ef5218", X"d69906245565a910", X"f40e35855771202a", X"106aa07032bbd1b8", X"19a4c116b8d2d0c8", X"1e376c085141ab53", X"2748774cdf8eeb99", X"34b0bcb5e19b48a8", X"391c0cb3c5c95a63", X"4ed8aa4ae3418acb", X"5b9cca4f7763e373", X"682e6ff3d6b2b8a3", X"748f82ee5defb2fc", X"78a5636f43172f60", X"84c87814a1f0ab72", X"8cc702081a6439ec", X"90befffa23631e28", X"a4506cebde82bde9", X"bef9a3f7b2c67915", X"c67178f2e372532b", X"ca273eceea26619c", X"d186b8c721c0c207", X"eada7dd6cde0eb1e", X"f57d4f7fee6ed178", X"06f067aa72176fba", X"0a637dc5a2c898a6", X"113f9804bef90dae", X"1b710b35131c471b", X"28db77f523047d84", X"32caab7b40c72493", X"3c9ebe0a15c9bebc", X"431d67c49c100d4c", X"4cc5d4becb3e42b6", X"597f299cfc657e2a", X"5fcb6fab3ad6faec", X"6c44198c4a475817" );



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_M, S_HASH, S_SAMPLE_H, S_OUTPUT0, S_OUTPUT1, S_OUTPUT, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- Behavioral
----------------------------------------------------------------------------------
BEGIN

    -- SIZE STUFF ----------------------------------------------------------------
    ADJUST_SIZE         <= STD_LOGIC_VECTOR(UNSIGNED(SIZE)+129);
    NUM_OF_CHUNKS_VAR   <= STD_LOGIC_VECTOR(UNSIGNED(ADJUST_SIZE(19 DOWNTO 10)) + 1);
    NUM_OF_WORDS        <= NUM_OF_CHUNKS_VAR & (4 DOWNTO 0 => '0');
    M_BITS_LAST         <= SIZE(4 DOWNTO 0);
    ------------------------------------------------------------------------------
    

    -- PADDING & INPUT REGISTER --------------------------------------------------
    -- padding and input
    M_LENGTH_STD <= (127 DOWNTO 20 => '0') & SIZE; 
    
    -- padding need to be handled in this way as otherwise the synthesizer throws errors
    WITH M_BITS_LAST SELECT M_PLUS_ONE <=
        '1' & (30 DOWNTO 0 => '0') WHEN "00000",
        M(31 DOWNTO 31) & '1' & (29 DOWNTO 0 => '0') WHEN "00001",
        M(31 DOWNTO 30) & '1' & (28 DOWNTO 0 => '0') WHEN "00010",
        M(31 DOWNTO 29) & '1' & (27 DOWNTO 0 => '0') WHEN "00011",
        M(31 DOWNTO 28) & '1' & (26 DOWNTO 0 => '0') WHEN "00100",
        M(31 DOWNTO 27) & '1' & (25 DOWNTO 0 => '0') WHEN "00101",
        M(31 DOWNTO 26) & '1' & (24 DOWNTO 0 => '0') WHEN "00110",
        M(31 DOWNTO 25) & '1' & (23 DOWNTO 0 => '0') WHEN "00111",
        M(31 DOWNTO 24) & '1' & (22 DOWNTO 0 => '0') WHEN "01000",
        M(31 DOWNTO 23) & '1' & (21 DOWNTO 0 => '0') WHEN "01001",
        M(31 DOWNTO 22) & '1' & (20 DOWNTO 0 => '0') WHEN "01010",
        M(31 DOWNTO 21) & '1' & (19 DOWNTO 0 => '0') WHEN "01011",
        M(31 DOWNTO 20) & '1' & (18 DOWNTO 0 => '0') WHEN "01100",
        M(31 DOWNTO 19) & '1' & (17 DOWNTO 0 => '0') WHEN "01101",
        M(31 DOWNTO 18) & '1' & (16 DOWNTO 0 => '0') WHEN "01110",
        M(31 DOWNTO 17) & '1' & (15 DOWNTO 0 => '0') WHEN "01111",
        M(31 DOWNTO 16) & '1' & (14 DOWNTO 0 => '0') WHEN "10000",
        M(31 DOWNTO 15) & '1' & (13 DOWNTO 0 => '0') WHEN "10001",
        M(31 DOWNTO 14) & '1' & (12 DOWNTO 0 => '0') WHEN "10010",
        M(31 DOWNTO 13) & '1' & (11 DOWNTO 0 => '0') WHEN "10011",
        M(31 DOWNTO 12) & '1' & (10 DOWNTO 0 => '0') WHEN "10100",
        M(31 DOWNTO 11) & '1' & (9 DOWNTO 0 => '0') WHEN "10101",
        M(31 DOWNTO 10) & '1' & (8 DOWNTO 0 => '0') WHEN "10110",
        M(31 DOWNTO 9) & '1' & (7 DOWNTO 0 => '0') WHEN "10111",
        M(31 DOWNTO 8) & '1' & (6 DOWNTO 0 => '0') WHEN "11000",
        M(31 DOWNTO 7) & '1' & (5 DOWNTO 0 => '0') WHEN "11001",
        M(31 DOWNTO 6) & '1' & (4 DOWNTO 0 => '0') WHEN "11010",
        M(31 DOWNTO 5) & '1' & (3 DOWNTO 0 => '0') WHEN "11011",
        M(31 DOWNTO 4) & '1' & (2 DOWNTO 0 => '0') WHEN "11100",
        M(31 DOWNTO 3) & '1' & (1 DOWNTO 0 => '0') WHEN "11101",
        M(31 DOWNTO 2) & '1' & (0 DOWNTO 0 => '0') WHEN "11110",
        M(31 DOWNTO 1) & '1' WHEN "11111",
        (OTHERS => '0') WHEN OTHERS;
   
    -- handle padding
    -- in this case a process is required as select-commands need static selection signals...
    PROCESS_PAD : PROCESS (CNT_WORDS_OUT, NUM_OF_WORDS, M, M_LENGTH_STD, SIZE, M_PLUS_ONE)
    BEGIN
        IF CNT_WORDS_OUT = SIZE(19 DOWNTO 5) THEN
            PADDING <= M_PLUS_ONE;
        ELSIF CNT_WORDS_OUT = STD_LOGIC_VECTOR(UNSIGNED(NUM_OF_WORDS) - 4) THEN
            PADDING <= M_LENGTH_STD(127 DOWNTO 96);
        ELSIF CNT_WORDS_OUT = STD_LOGIC_VECTOR(UNSIGNED(NUM_OF_WORDS) - 3) THEN
            PADDING <= M_LENGTH_STD( 95 DOWNTO 64);
        ELSIF CNT_WORDS_OUT = STD_LOGIC_VECTOR(UNSIGNED(NUM_OF_WORDS) - 2) THEN
            PADDING <= M_LENGTH_STD( 63 DOWNTO 32);  
        ELSIF CNT_WORDS_OUT = STD_LOGIC_VECTOR(UNSIGNED(NUM_OF_WORDS) - 1) THEN
            PADDING <= M_LENGTH_STD( 31 DOWNTO  0); 
        ELSE
            PADDING <= (OTHERS => '0');
        END IF;
    END PROCESS;


    -- either use the input (M) or the padding
    M_IN <= M WHEN CNT_WORDS_OUT < SIZE(19 DOWNTO 5) ELSE PADDING;
    
    -- decide wether an input is written to W or an update W
    L0 : FOR I IN 0 TO 15 GENERATE
        W_IN(I) <= M_IN & M_IN WHEN RECEIVE_M = '1' ELSE CURRENT_W_COM WHEN CNT_OFFSET_ENABLE = '1' ELSE (OTHERS => '0');
    END GENERATE;
    
    -- input register
    W_REG: FOR I IN 0 TO 15 GENERATE
        W_REG_EN_M(2*I) <= '1' WHEN CNT_M_OUT(4 DOWNTO 0) = STD_LOGIC_VECTOR(TO_UNSIGNED(2*I+1, 5)) AND RECEIVE_M = '1' ELSE '0';
        W_REG_EN_M(2*I+1) <= '1' WHEN CNT_M_OUT(4 DOWNTO 0) = STD_LOGIC_VECTOR(TO_UNSIGNED(2*I, 5)) AND RECEIVE_M = '1' ELSE '0';
        
        W_REG_EN_W(MY_MOD(I+1, 16)) <= '1' WHEN CNT_RND_OUT(3 DOWNTO 0) = STD_LOGIC_VECTOR(TO_UNSIGNED(I, 4)) AND CNT_OFFSET_ENABLE = '1' ELSE '0';
        
        W_REG_EN(2*I) <= W_REG_EN_M(2*I) OR W_REG_EN_W(I);
        W_REG_EN(2*I+1) <= W_REG_EN_M(2*I+1) OR W_REG_EN_W(I);
        
        REG_L : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => 32)
        PORT MAP (
            Q       => W_OUT(I)(31 DOWNTO 0), 
            D       => W_IN(I)(31 DOWNTO 0), 
            CLK     => CLK, 
            EN      => W_REG_EN(2*I), 
            RST     => W_REG_RST
        );

        REG_H : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => 32)
        PORT MAP (
            Q       => W_OUT(I)(63 DOWNTO 32), 
            D       => W_IN(I)(63 DOWNTO 32), 
            CLK     => CLK, 
            EN      => W_REG_EN(2*I+1), 
            RST     => W_REG_RST
        );
    END GENERATE;
    ------------------------------------------------------------------------------

    -- COMPRESSION ---------------------------------------------------------------        
    -- select and generate new W 
    W0_INT <= W_OUT(TO_INTEGER(UNSIGNED(CNT_O15_OUT)));
    W0 <= (W0_INT(0) & W0_INT(63 DOWNTO 1)) XOR (W0_INT(7 DOWNTO 0) & W0_INT(63 DOWNTO 8)) XOR ((63 DOWNTO 57 => '0') & W0_INT(63 DOWNTO 7));
     
    W1_INT <= W_OUT(TO_INTEGER(UNSIGNED(CNT_O2_OUT)));
    W1 <= (W1_INT(18 DOWNTO 0) & W1_INT(63 DOWNTO 19)) XOR (W1_INT(60 DOWNTO 0) & W1_INT(63 DOWNTO 61)) XOR ((63 DOWNTO 58 => '0') & W1_INT(63 DOWNTO 6));
    
    W2_INT <= W_OUT(TO_INTEGER(UNSIGNED(CNT_O16_OUT)));
    W3_INT <= W_OUT(TO_INTEGER(UNSIGNED(CNT_O7_OUT)));
    
    ADD_W_W0 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => W2_INT, DINB => W0, DOUT => CURRENT_W_U0);
    
    ADD_W_W1 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => W3_INT, DINB => W1, DOUT => CURRENT_W_U1);
    
    ADD_U0_U1 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => CURRENT_W_U0, DINB => CURRENT_W_U1, DOUT => CURRENT_W_COM);
    
    CURRENT_W <= W_OUT(TO_INTEGER(UNSIGNED(CNT_RND_OUT(3 DOWNTO 0))));
    CURRENT_K <= K(TO_INTEGER(UNSIGNED(CNT_RND_OUT)));
   
    
    -- compute intermediate results
    -- UPDATE REG 6
    ADD_H_W_DINA <= H_OUT(7) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(NUM_OF_ROUNDS))) ELSE H_OUT(6) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(5);
    
    ADD_H_W : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => ADD_H_W_DINA, DINB => CURRENT_W, DOUT => INT1);
    
    ADD_INT1_K : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => INT1, DINB => CURRENT_K, DOUT => WORKING_REG_IN(6)); 
    
    -- UPDATE REG 4
    ADD_REG4_IN <= H_OUT(3) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(3);
    
    ADD_7_D : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(7), DINB => ADD_REG4_IN, DOUT => INT2); 
    
    --WORKING_REG_IN(4) <= INT2;
    WORKING_REG_IN(4) <= H_OUT(4) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NUM_OF_ROUNDS))) ELSE INT2;
     
    -- UPDATE REG 7
    CH_IN0 <= H_OUT(6) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(5);
    CH_IN1 <= H_OUT(5) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(4);
    CH_IN2 <= H_OUT(4) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NUM_OF_ROUNDS))) ELSE INT2;
    
    S1 <= (CH_IN2(13 DOWNTO 0) & CH_IN2(63 DOWNTO 14)) XOR (CH_IN2(17 DOWNTO 0) & CH_IN2(63 DOWNTO 18)) XOR (CH_IN2(40 DOWNTO 0) & CH_IN2(63 DOWNTO 41));
    CH <= (CH_IN2 AND CH_IN1) XOR ((NOT CH_IN2) AND CH_IN0);
    
    ADD_CH_6 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => CH, DINB => WORKING_REG_OUT(6), DOUT => INT3);    

    ADD_S2_INT3 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => INT3, DINB => S1, DOUT => WORKING_REG_IN(7));    
    
    -- UPDATE REG 5
    WORKING_REG_IN(5) <= H_OUT(5) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(4);
    
    -- UPDATE REG 3   
    WORKING_REG_IN(3) <= H_OUT(2) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(2);

    -- UPDATE REG 2 
    WORKING_REG_IN(2) <= H_OUT(1) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(1);
     
    -- UPDATE REG 1 
    WORKING_REG_IN(1) <= H_OUT(0) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(0);
    
    -- UPDATE REG 0
    MA_IN0 <= H_OUT(0) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(0);
    MA_IN1 <= H_OUT(1) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(1);
    MA_IN2 <= H_OUT(2) WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NUM_OF_ROUNDS))) ELSE WORKING_REG_OUT(2);
    
    S0      <= (MA_IN0(27 DOWNTO 0) & MA_IN0(63 DOWNTO 28)) XOR (MA_IN0(33 DOWNTO 0) & MA_IN0(63 DOWNTO 34)) XOR (MA_IN0(38 DOWNTO 0) & MA_IN0(63 DOWNTO 39));
    MAJ     <= (MA_IN0 AND MA_IN1) XOR (MA_IN0 AND MA_IN2) XOR (MA_IN1 AND MA_IN2);    
    
    ADD_MA_7 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => MAJ, DINB => WORKING_REG_OUT(7), DOUT => INT4);    
    
    ADD_S0_INT4 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => S0, DINB => INT4, DOUT => WORKING_REG_IN(0));       

    -- register for working variables
    WORKING_REG : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                WORKING_REG_OUT <= (OTHERS => (OTHERS => '0'));
            ELSE
                WORKING_REG_OUT <= WORKING_REG_IN;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------
    
    
    -- OUTPUT --------------------------------------------------------------------
    -- compressed chunk is added to current hash
    ADDER_H0 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(0), DINB => H_OUT(0), DOUT => H_IN(0));    

    ADDER_H1 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(1), DINB => H_OUT(1), DOUT => H_IN(1)); 

    ADDER_H2 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(2), DINB => H_OUT(2), DOUT => H_IN(2)); 

    ADDER_H3 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(3), DINB => H_OUT(3), DOUT => H_IN(3)); 
                
    ADDER_H4 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => INT2, DINB => H_OUT(4), DOUT => H_IN(4));
    
    ADDER_H5 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(4), DINB => H_OUT(5), DOUT => H_IN(5));

    ADDER_H6 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(5), DINB => H_OUT(6), DOUT => H_IN(6));

    ADDER_H7 : ENTITY work.SHA_MOD_ADDER GENERIC MAP(SIZE => 64)
    PORT MAP(DINA => WORKING_REG_OUT(5), DINB => H_OUT(7), DOUT => H_IN(7));
    
    REG_H : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                H_OUT <= (x"cbbb9d5dc1059ed8", x"629a292a367cd507", x"9159015a3070dd17", x"152fecd8f70e5939", x"67332667ffc00b31", x"8eb44a8768581511", x"db0c2e0d64f98fa7", x"47b5481dbefa4fa4");
            ELSE
                IF H_ENABLE = '1' THEN
                    H_OUT(7) <= H_IN(7);
                ELSE
                    H_OUT(7) <= H_OUT(7);
                END IF;
                
                IF H_ENABLE1 = '1' THEN
                    H_OUT(4 TO 6) <= H_IN(4 TO 6);
                ELSE
                    H_OUT(4 TO 6) <= H_OUT(4 TO 6);
                END IF;
                
                IF H_ENABLE2 = '1' THEN
                    H_OUT(0 TO 3) <= H_IN(0 TO 3);
                ELSE
                    H_OUT(0 TO 3) <= H_OUT(0 TO 3);
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- as we applied retiming, we have three different points in time where results are finished
    EN1 : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            H_ENABLE1 <= H_ENABLE;
        END IF;
    END PROCESS;

    EN2 : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            H_ENABLE2 <= H_ENABLE1;
        END IF;
    END PROCESS;
    
    -- output
    HASH_OUT    <= H_OUT(TO_INTEGER(UNSIGNED(CNT_OUT_OUT(3 DOWNTO 1))))(31 DOWNTO 0) WHEN CNT_OUT_OUT(0) = '1' ELSE H_OUT(TO_INTEGER(UNSIGNED(CNT_OUT_OUT(3 DOWNTO 1))))(63 DOWNTO 32);
    HASH        <= HASH_OUT WHEN CNT_OUT_ENABLE = '1' ELSE (OTHERS => '0');
    HASH_ADDR   <= CNT_OUT_OUT(2 DOWNTO 0);
    ------------------------------------------------------------------------------  


    -- COUNTER -------------------------------------------------------------------
    -- CNT_ROUND: counts the compression's main loop
    CNT_RND_DONE <= '1' WHEN CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_OF_ROUNDS-2, LOG2(NUM_OF_ROUNDS))) ELSE '0';
    CNT_ROUND : ENTITY work.COUNTER_INC GENERIC MAP(SIZE => LOG2(NUM_OF_ROUNDS), MAX_VALUE => NUM_OF_ROUNDS-1)
    PORT MAP(CLK => CLK, EN => CNT_RND_ENABLE, RST => CNT_RND_RESET, CNT_OUT => CNT_RND_OUT);
    
    -- CNT_WORDS: counts the total number of words (32 bit) that need to be processed (padded message)
    CNT_WORDS_ENABLE <= ENABLE AND RECEIVE_M AND (M_VALID OR M_COMPLETE);
    CNT_WORDS_DONE <= '1' WHEN CNT_WORDS_OUT >= STD_LOGIC_VECTOR(UNSIGNED(NUM_OF_WORDS) - 1) ELSE '0';
    CNT_WORDS : ENTITY work.COUNTER_INC GENERIC MAP(SIZE => 15, MAX_VALUE => 2**15-1)
    PORT MAP(CLK => CLK, EN => CNT_WORDS_ENABLE, RST => CNT_WORDS_RESET, CNT_OUT => CNT_WORDS_OUT); 
    
    -- CNT_OUT: counter is used to output the final hash
    -- NOTE: it is currently adapted to BIKE as only the 256 LSBs are returned (6, 7)
    CNT_OUT_DONE <= '1' WHEN CNT_OUT_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(6, 4)) ELSE '0';
    CNT_OUT : ENTITY work.COUNTER_INC GENERIC MAP(SIZE => 4, MAX_VALUE => 7)
    PORT MAP(CLK => CLK, EN => CNT_OUT_ENABLE, RST => CNT_OUT_RESET, CNT_OUT => CNT_OUT_OUT);
    
    -- CNT_M: counts the number of words per chunk    
    CNT_M_DONE <= '1' WHEN CNT_M_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(30, 5)) ELSE '0';
    M_COMPLETE <= '0' WHEN CNT_WORDS_OUT < SIZE(19 DOWNTO 5) ELSE '1';  -- identifies when the message needs to be padded with '0'
    CNT_M_ENABLE <= ENABLE AND RECEIVE_M AND (M_VALID OR M_COMPLETE);   -- only count when M_VALID (not entirely tested right now)
    CNT_M : ENTITY work.COUNTER_INC GENERIC MAP(SIZE => 5, MAX_VALUE => 32)
    PORT MAP(CLK => CLK, EN => CNT_M_ENABLE, RST => CNT_M_RESET, CNT_OUT => CNT_M_OUT);
    
    -- these counters are needed to compute the new w's on the fly (less registers are required)
    CNT_OFFSET_ENABLE <= '1' WHEN CNT_RND_OUT >= STD_LOGIC_VECTOR(TO_UNSIGNED(15, LOG2(NUM_OF_ROUNDS))) ELSE '0';
    CNT_O15_INT : ENTITY work.COUNTER_INC_INIT_BARREL GENERIC MAP(SIZE => 4, MAX_VALUE => 16, INITIAL => 1)
    PORT MAP(CLK => CLK, EN => CNT_OFFSET_ENABLE, RST => CNT_OFFSET_RESET, CNT_OUT => CNT_O15_OUT);
    
    CNT_O2_INT : ENTITY work.COUNTER_INC_INIT_BARREL GENERIC MAP(SIZE => 4, MAX_VALUE => 16, INITIAL => 14)
    PORT MAP(CLK => CLK, EN => CNT_OFFSET_ENABLE, RST => CNT_OFFSET_RESET, CNT_OUT => CNT_O2_OUT);
    
    CNT_O16_INT : ENTITY work.COUNTER_INC_INIT_BARREL GENERIC MAP(SIZE => 4, MAX_VALUE => 16, INITIAL => 0)
    PORT MAP(CLK => CLK, EN => CNT_OFFSET_ENABLE, RST => CNT_OFFSET_RESET, CNT_OUT => CNT_O16_OUT);
    
    CNT_O7_INT : ENTITY work.COUNTER_INC_INIT_BARREL GENERIC MAP(SIZE => 4, MAX_VALUE => 16, INITIAL => 9)
    PORT MAP(CLK => CLK, EN => CNT_OFFSET_ENABLE, RST => CNT_OFFSET_RESET, CNT_OUT => CNT_O7_OUT);
    ------------------------------------------------------------------------------  


    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET            =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    M_RDY               <= '0';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '1';
                    
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                    
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '1';
                    
                    RECEIVE_M           <= '0';
                    
                    H_ENABLE            <= '0';
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN
                        STATE       <= S_M;
                    ELSE
                        STATE       <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_M                =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    --M_RDY               <= '1';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '0';                   

                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                                        
                    CNT_M_RESET         <= '0';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '1';
                    
                    H_ENABLE            <= '0';

                    
                    -- TRANSITION ------
                    IF (CNT_M_DONE = '1') THEN
                        M_RDY       <= '0';
                        STATE       <= S_HASH;
                    ELSE
                        M_RDY       <= '1';
                        STATE       <= S_M;
                    END IF;
                ----------------------------------------------
                 
                ----------------------------------------------
                WHEN S_HASH  =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    M_RDY               <= '0';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '0';
                    CNT_RND_ENABLE      <= '1';
                    
                    CNT_WORDS_RESET     <= '0';   
                    
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                                        
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '0';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '0';
                    
                    H_ENABLE            <= '0';
    
                    
                    -- TRANSITION ------
                    IF (CNT_RND_DONE = '1') THEN
                        STATE       <= S_SAMPLE_H;
                    ELSE
                        STATE       <= S_HASH;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_SAMPLE_H         =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    M_RDY               <= '0';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '0';   
                    
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                                        
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '0';
                    
                    H_ENABLE            <= '1';

                
                    -- TRANSITION ------
                    IF CNT_WORDS_DONE = '1' THEN
                        STATE               <= S_OUTPUT0;
                    ELSE
                        STATE               <= S_M;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_OUTPUT0         =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    M_RDY               <= '0';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '0';   
                    
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                                        
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '0';
                    
                    H_ENABLE            <= '0';

                
                    -- TRANSITION ------
                    STATE               <= S_OUTPUT1;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_OUTPUT1         =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    M_RDY               <= '0';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '0';   
                    
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                                        
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '0';
                    
                    H_ENABLE            <= '0';

                
                    -- TRANSITION ------
                    STATE               <= S_OUTPUT;
                ----------------------------------------------
                                
                ----------------------------------------------
                WHEN S_OUTPUT         =>
                    -- GLOBAL ----------
                    DONE                <= '0';
                    M_RDY               <= '0';
                    HASH_VALID          <= '1';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '0';   
                    
                    CNT_OUT_RESET       <= '0';
                    CNT_OUT_ENABLE      <= '1';
                                        
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '0';
                    
                    H_ENABLE            <= '0';

                
                    -- TRANSITION ------
                    IF CNT_OUT_DONE = '1' THEN
                        STATE           <= S_DONE;
                    ELSE
                        STATE           <= S_OUTPUT;
                    END IF;
                ----------------------------------------------
                                                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- GLOBAL ----------
                    DONE                <= '1';
                    M_RDY               <= '0';
                    HASH_VALID          <= '0';
                    
                    -- COUNTER ---------
                    CNT_RND_RESET       <= '1';
                    CNT_RND_ENABLE      <= '0';
                    
                    CNT_WORDS_RESET     <= '1';   
                    
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_ENABLE      <= '0';
                                        
                    CNT_M_RESET         <= '1';
                    
                    CNT_OFFSET_RESET    <= '1';
                    
                    W_REG_RST           <= '0';
                    
                    RECEIVE_M           <= '0';

                
                    -- TRANSITION ------
                    IF RESET = '1' THEN
                        STATE           <= S_RESET;
                    ELSE 
                        STATE           <= S_DONE;
                    END IF;
                ----------------------------------------------
                                
            END CASE;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------

END Behavioral;
