
----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       2020-05-27
-- LAST CHANGES:      2020-05-27
-- MODULE NAME:       BIKE_INVERSION
--
-- REVISION:          1.00 - File was automatically created by a Sage script for r=12323.
--
-- LICENCE:           Please look at licence.txt
-- USAGE INFORMATION: Please look at readme.txt. If licence.txt or readme.txt
--                    are missing or	if you have questions regarding the code
--                    please contact Tim Güneysu (tim.gueneysu@rub.de) and
--                    Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
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
    USE IEEE.MATH_REAL.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_INVERSION IS
    PORT (  
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------    
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        DONE            : OUT STD_LOGIC;
        -- INPUT POLYNOMIAL ------------
        POL_IN_REN      : OUT STD_LOGIC;
        POL_IN_ADDR     : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        POL_IN_DIN      : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- INPUT H1 - FINAL MUL --------
        H1_IN_REN       : OUT STD_LOGIC;
        H1_IN_ADDR      : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        H1_IN_DIN       : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- OUTPUT ----------------------
        DONE_OUT        : OUT STD_LOGIC;
        DOUT            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)  
    );
END BIKE_INVERSION;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE_INVERSION IS
  
-- SIGNALS
----------------------------------------------------------------------------------
-- Counter
SIGNAL CNT_ROUND_EN, CNT_ROUND_RST      : STD_LOGIC;
SIGNAL CNT_ROUND_DONE                   : STD_LOGIC;
SIGNAL CNT_ROUND_OUT                    : STD_LOGIC_VECTOR(3 DOWNTO 0);

SIGNAL CNT_SQU_EN, CNT_SQU_RST          : STD_LOGIC;
SIGNAL CNT_SQU_OUT                      : STD_LOGIC_VECTOR(LOG2(6161)-1 DOWNTO 0);
SIGNAL CNT_SQU_MAX                      : STD_LOGIC_VECTOR(LOG2(6161)-1 DOWNTO 0);

SIGNAL CNT_OUTPUT_DONE                  : STD_LOGIC;
SIGNAL CNT_OUTPUT_OUT                   : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);                       

-- Squaring
SIGNAL SQU_ENABLE, SQU_RESET, SQU_DONE  : STD_LOGIC;
SIGNAL SQU_REN_IN, SQU_WEN_OUT          : STD_LOGIC;
SIGNAL SQU_ADDR_IN, SQU_ADDR_OUT        : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SQU_DIN_IN, SQU_DOUT_OUT         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

-- Multiplier
SIGNAL MUL_RESET, MUL_ENABLE, MUL_DONE  : STD_LOGIC;
SIGNAL MUL_RESULT_RDEN, MUL_RESULT_WREN : STD_LOGIC;
SIGNAL MUL_RESULT_ADDR                  : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL MUL_RESULT_DOUT, MUL_RESULT_DIN  : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL MUL_MATRIX_RDEN, MUL_MATRIX_WREN : STD_LOGIC;
SIGNAL MUL_MATRIX_ADDR                  : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL MUL_MATRIX_DOUT, MUL_MATRIX_DIN  : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL MUL_VECTOR_RDEN                  : STD_LOGIC;
SIGNAL MUL_VECTOR_ADDR                  : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL MUL_VECTOR_DIN                   : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL MUL_VECTOR_DIN_BRAM              : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

-- Memory
SIGNAL SK_REN                           : STD_LOGIC;
SIGNAL SK_ADDR                          : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SK_DOUT0, SK_DOUT1               : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SK_DIN0, SK_DIN1                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

SIGNAL B_REN, B_WEN                     : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL B_REN_INT, B_REN_INT2            : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL B0_ADDR, B1_ADDR, B2_ADDR        : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL B0_ADDR_INT                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL B1_ADDR_INT                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL B2_ADDR_INT                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL B0_DOUT0, B0_DOUT1               : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL B1_DOUT0, B1_DOUT1               : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL B2_DOUT0, B2_DOUT1               : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL B0_DIN0, B0_DIN1                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL B1_DIN0, B1_DIN1                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL B2_DIN0, B2_DIN1                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
  
-- Inversion
SIGNAL NUMBER_OF_SQUARINGS              : STD_LOGIC_VECTOR(12 DOWNTO 0);
SIGNAL ADDITIONAL_COMP                  : STD_LOGIC;
SIGNAL ROUND_INIT                       : STD_LOGIC;
SIGNAL ROUND_MUL_INIT                   : STD_LOGIC;
SIGNAL SQU_ADDITIONAL                   : STD_LOGIC;
SIGNAL MUL_ADDITIONAL                   : STD_LOGIC;
SIGNAL EVENODD                          : STD_LOGIC;
SIGNAL SEL_BRAM                         : STATES_BRAM_SEL; 

SIGNAL SQU_CHAIN_DONE                   : STD_LOGIC;
SIGNAL SQU_ADDR0, SQU_ADDR1             : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SQU_DIN_IN0, SQU_DIN_IN1         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SQU_WREN0, SQU_WREN1             : STD_LOGIC;
SIGNAL SQU_RDEN0, SQU_RDEN1             : STD_LOGIC;
SIGNAL FIRST_SQUARING_IN_CHAIN          : STD_LOGIC;
SIGNAL FIRST_SQUARING_IN_CHAIN_DOUT     : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL LAST_STATE_SEL_BREM              : STATES_BRAM_SEL;

-- Last multiplication
SIGNAL LAST_MUL                         : STD_LOGIC;

-- Output
SIGNAL INV_DOUT                         : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL INV_DOUT_0                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL INV_DOUT_1                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL INV_DOUT_2                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL DONE_INT, DOUT_RDEN              : STD_LOGIC;
  
-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_SQU_INIT, S_MUL_INIT, S_SQUARING0, S_SQUARING1, S_SQUARING_ADD, S_MUL, S_MUL_ADD, S_MUL_LAST, S_OUTPUT, S_DONE);
SIGNAL STATE : STATES := S_RESET;
  
-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

    -- INVERSION -----------------------------------------------------------------  
    -- switching brams for squaring chains --
    SQU_ADDR0 <= SQU_ADDR_IN WHEN CNT_SQU_OUT(0) = '0' ELSE SQU_ADDR_OUT;
    SQU_ADDR1 <= SQU_ADDR_OUT WHEN CNT_SQU_OUT(0) = '0' ELSE SQU_ADDR_IN;
    
    SQU_WREN0 <= SQU_WEN_OUT WHEN CNT_SQU_OUT(0) = '1' ELSE '0';
    SQU_WREN1 <= SQU_WEN_OUT WHEN CNT_SQU_OUT(0) = '0' ELSE '0';

    SQU_RDEN0 <= SQU_REN_IN WHEN CNT_SQU_OUT(0) = '0' ELSE '0';
    SQU_RDEN1 <= SQU_REN_IN WHEN CNT_SQU_OUT(0) = '1' ELSE '0';
    
    SQU_DIN_IN <= SK_DOUT0 WHEN ROUND_INIT = '1' ELSE FIRST_SQUARING_IN_CHAIN_DOUT WHEN FIRST_SQUARING_IN_CHAIN = '1' ELSE SQU_DIN_IN0 WHEN CNT_SQU_OUT(0) = '0' ELSE SQU_DIN_IN1;  
    
    -- for the first squaring in a squaring chain we have to read from the BRAM where the prior multiplication result was written --
    FIRST_SQUARING_IN_CHAIN <= '1' WHEN (CNT_SQU_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0,LOG2(6161))) AND SQU_ENABLE = '1' AND ROUND_INIT = '0') OR SQU_ADDITIONAL = '1' ELSE '0'; 
    
    -- select the correct address of the multiplication results 
    B0_ADDR <= SQU_ADDR_IN WHEN (LAST_STATE_SEL_BREM = S_MVR OR LAST_STATE_SEL_BREM = S_VMR) AND FIRST_SQUARING_IN_CHAIN = '1' ELSE B0_ADDR_INT;
    B1_ADDR <= SQU_ADDR_IN WHEN (LAST_STATE_SEL_BREM = S_MRV OR LAST_STATE_SEL_BREM = S_VRM) AND FIRST_SQUARING_IN_CHAIN = '1' ELSE B1_ADDR_INT;
    B2_ADDR <= SQU_ADDR_IN WHEN (LAST_STATE_SEL_BREM = S_RMV OR LAST_STATE_SEL_BREM = S_RVM) AND FIRST_SQUARING_IN_CHAIN = '1' ELSE B2_ADDR_INT;
    
    -- we can only write to an address if the RDEN signal is activated
    B_REN_INT2 <= B_REN_INT OR B_WEN;
    
    B_REN(0) <= SQU_REN_IN WHEN FIRST_SQUARING_IN_CHAIN = '1' ELSE B_REN_INT2(0);
    B_REN(1) <= SQU_REN_IN WHEN FIRST_SQUARING_IN_CHAIN = '1' ELSE B_REN_INT2(1);
    B_REN(2) <= SQU_REN_IN WHEN FIRST_SQUARING_IN_CHAIN = '1' ELSE B_REN_INT2(2);
    
    WITH LAST_STATE_SEL_BREM SELECT FIRST_SQUARING_IN_CHAIN_DOUT <=
        B0_DOUT0 WHEN S_MVR,
        B0_DOUT0 WHEN S_VMR,
        B1_DOUT0 WHEN S_MRV,
        B1_DOUT0 WHEN S_VRM,
        B2_DOUT0 WHEN S_RMV,
        B2_DOUT0 WHEN S_RVM,
        (OTHERS => '0') WHEN OTHERS;
    
    -- to select the correct bram, we have to store the previous state of  the SEL_BRAM signal
    D_SEL_BRAM : PROCESS(CLK, SEL_BRAM)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF MUL_DONE = '1' THEN
                LAST_STATE_SEL_BREM <= SEL_BRAM;
            ELSE
                LAST_STATE_SEL_BREM <= LAST_STATE_SEL_BREM;
            END IF;
        END IF;
    END PROCESS;
  
    -- BRAM I/Os - the following block assigns the inputs and outputs of the multiplier and squaring module to the correct brams --
    -- ADDR    
    ASSIGN_ADDR : ENTITY work.BIKE_INVERSION_BRAM_ASSIGNMENT
    GENERIC MAP(OUTPUT_SIZE => LOG2(WORDS))
    PORT MAP(
        SEL_BRAM    => SEL_BRAM, 
        INPUT0      => SQU_ADDR1, 
        INPUT1      => SQU_ADDR0, 
        INPUT2      => MUL_VECTOR_ADDR,
        INPUT3      => MUL_MATRIX_ADDR,
        INPUT4      => MUL_RESULT_ADDR,
        B0          => B0_ADDR_INT,
        B1          => B1_ADDR_INT,
        B2          => B2_ADDR_INT
    );

    -- DIN
    ASSIGN_DIN : ENTITY work.BIKE_INVERSION_BRAM_ASSIGNMENT
    GENERIC MAP(OUTPUT_SIZE => B_WIDTH)
    PORT MAP(
        SEL_BRAM    => SEL_BRAM, 
        INPUT0      => SQU_DOUT_OUT, 
        INPUT1      => SQU_DOUT_OUT, 
        INPUT2      => (OTHERS => '0'),
        INPUT3      => MUL_MATRIX_DOUT,
        INPUT4      => MUL_RESULT_DOUT,
        B0          => B0_DIN0,
        B1          => B1_DIN0,
        B2          => B2_DIN0
    );

    -- WEN
    ASSIGN_WEN : ENTITY work.BIKE_INVERSION_BRAM_ASSIGNMENT
    GENERIC MAP(OUTPUT_SIZE => 1)
    PORT MAP(
        SEL_BRAM    => SEL_BRAM, 
        INPUT0(0)   => SQU_WREN1, 
        INPUT1(0)   => SQU_WREN0, 
        INPUT2      => (OTHERS => '0'),
        INPUT3(0)   => MUL_MATRIX_WREN,
        INPUT4(0)   => MUL_RESULT_WREN,
        B0(0)       => B_WEN(0),
        B1(0)       => B_WEN(1),
        B2(0)       => B_WEN(2)
    );     

    -- REN   
    ASSIGN_REN : ENTITY work.BIKE_INVERSION_BRAM_ASSIGNMENT
    GENERIC MAP(OUTPUT_SIZE => 1)
    PORT MAP(
        SEL_BRAM    => SEL_BRAM, 
        INPUT0(0)   => SQU_RDEN1, 
        INPUT1(0)   => SQU_RDEN0, 
        INPUT2(0)   => MUL_VECTOR_RDEN,
        INPUT3(0)   => MUL_MATRIX_RDEN,
        INPUT4(0)   => MUL_RESULT_RDEN,
        B0(0)       => B_REN_INT(0),
        B1(0)       => B_REN_INT(1),
        B2(0)       => B_REN_INT(2)
    );   
    
    -- DOUT
    WITH SEL_BRAM SELECT SQU_DIN_IN0 <=
        B0_DOUT0 WHEN S_SQU_1,
        B1_DOUT0 WHEN S_SQU_2,
        B2_DOUT0 WHEN S_SQU_0,
        (OTHERS => '0') WHEN OTHERS; 
    
    WITH SEL_BRAM SELECT SQU_DIN_IN1 <=
        B0_DOUT0 WHEN S_SQU_2,
        B1_DOUT0 WHEN S_SQU_0,
        B2_DOUT0 WHEN S_SQU_1,
        (OTHERS => '0') WHEN OTHERS; 
    
    MUL_VECTOR_DIN <=  SK_DOUT0 WHEN MUL_ADDITIONAL = '1' OR ROUND_MUL_INIT = '1' ELSE MUL_VECTOR_DIN_BRAM WHEN LAST_MUL = '0' ELSE H1_IN_DIN;
    
    WITH SEL_BRAM SELECT MUL_VECTOR_DIN_BRAM <= 
        B0_DOUT0 WHEN S_RMV,
        B0_DOUT0 WHEN S_MRV,
        B1_DOUT0 WHEN S_RVM,
        B1_DOUT0 WHEN S_MVR,
        B2_DOUT0 WHEN S_VMR,
        B2_DOUT0 WHEN S_VRM,
        (OTHERS => '0') WHEN OTHERS;
    
    WITH SEL_BRAM SELECT MUL_MATRIX_DIN <= 
        B0_DOUT0 WHEN S_RVM,
        B0_DOUT0 WHEN S_VRM,
        B1_DOUT0 WHEN S_RMV,
        B1_DOUT0 WHEN S_VMR,
        B2_DOUT0 WHEN S_MRV,
        B2_DOUT0 WHEN S_MVR,
        (OTHERS => '0') WHEN OTHERS;        
    
    WITH SEL_BRAM SELECT MUL_RESULT_DIN <= 
        B0_DOUT0 WHEN S_MVR,
        B0_DOUT0 WHEN S_VMR,
        B1_DOUT0 WHEN S_MRV,
        B1_DOUT0 WHEN S_VRM,
        B2_DOUT0 WHEN S_RMV,
        B2_DOUT0 WHEN S_RVM,
        (OTHERS => '0') WHEN OTHERS;
        
                
    -- state machine to determine the correct selection signal controlling the BRAMs --
    -- EVENODD determins if we have to perform an odd or even number of squarings within a squarin chain
    -- (inversion of LSB is neccessary as we store number of required squarings - 1)
    EVENODD <= '1' WHEN SQU_ADDITIONAL = '1' OR ROUND_INIT = '1' ELSE NOT NUMBER_OF_SQUARINGS(0);
    
    SEL_BRAM_FSM : ENTITY work.BIKE_INVERSION_FSM_BRAM
    PORT MAP(
        CLK         => CLK, 
        RESET       => RESET, 
        EVENODD     => EVENODD, 
        SQU_DONE    => SQU_CHAIN_DONE, 
        MUL_DONE    => MUL_DONE, 
        STATE_OUT   => SEL_BRAM
    );
  
    -- squaring counter (counts number of squarings within a squaring chain)
    SQU_CHAIN_DONE  <= SQU_DONE WHEN (ROUND_INIT = '1' OR SQU_ADDITIONAL = '1' OR ROUND_MUL_INIT = '1' OR MUL_ADDITIONAL = '1') ELSE '1' WHEN CNT_SQU_OUT = NUMBER_OF_SQUARINGS AND SQU_DONE = '1' ELSE '0';
    
    CNT_SQU : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(6161), MAX_VALUE => 6160)
    PORT MAP(CLK => CLK, EN => CNT_SQU_EN, RST => CNT_SQU_RST, CNT_OUT => CNT_SQU_OUT);    
    
    -- round counter (for-loop)
    CNT_ROUND_DONE <= '1' WHEN CNT_ROUND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(13, LOG2(14))) ELSE '0';
    CNT_ROUND : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(14), MAX_VALUE => 13)
    PORT MAP(CLK => CLK, EN => CNT_ROUND_EN, RST => CNT_ROUND_RST, CNT_OUT => CNT_ROUND_OUT);
  
    -- indicates the supports of r-2
    ADD_COMP : PROCESS(CNT_ROUND_OUT)
    BEGIN
      CASE CNT_ROUND_OUT IS
        WHEN "0000"  => ADDITIONAL_COMP <= '1';
        WHEN "0001"  => ADDITIONAL_COMP <= '0';
        WHEN "0010"  => ADDITIONAL_COMP <= '0';
        WHEN "0011"  => ADDITIONAL_COMP <= '0';
        WHEN "0100"  => ADDITIONAL_COMP <= '0';
        WHEN "0101"  => ADDITIONAL_COMP <= '0';
        WHEN "0110"  => ADDITIONAL_COMP <= '0';
        WHEN "0111"  => ADDITIONAL_COMP <= '1';
        WHEN "1000"  => ADDITIONAL_COMP <= '0';
        WHEN "1001"  => ADDITIONAL_COMP <= '0';
        WHEN "1010"  => ADDITIONAL_COMP <= '0';
        WHEN "1011"  => ADDITIONAL_COMP <= '0';
        WHEN "1100"  => ADDITIONAL_COMP <= '1';
        WHEN OTHERS  => ADDITIONAL_COMP <= '0';
      END CASE;
    END PROCESS;  
      
    -- determines number of required squarings in a current round minus one
    NUM_OF_SQU : PROCESS(CNT_ROUND_OUT)
    BEGIN
      CASE CNT_ROUND_OUT IS
        WHEN "0000"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(0, 13));
        WHEN "0001"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(2, 13));
        WHEN "0010"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(5, 13));
        WHEN "0011"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(11, 13));
        WHEN "0100"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(23, 13));
        WHEN "0101"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(47, 13));
        WHEN "0110"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(95, 13));
        WHEN "0111"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(191, 13));
        WHEN "1000"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(384, 13));
        WHEN "1001"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(769, 13));
        WHEN "1010"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(1539, 13));
        WHEN "1011"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(3079, 13));
        WHEN "1100"  => NUMBER_OF_SQUARINGS <= STD_LOGIC_VECTOR(TO_UNSIGNED(6159, 13));
        WHEN OTHERS  => NUMBER_OF_SQUARINGS <= (OTHERS => '0');
      END CASE;
    END PROCESS;
    ------------------------------------------------------------------------------
      
    -- SQUARING MODULE -----------------------------------------------------------
    SQU : ENTITY work.BIKE_SQUARING_K1_GENERIC
    PORT MAP ( 
      -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => SQU_RESET,
        ENABLE          => SQU_ENABLE,
        DONE            => SQU_DONE,
        -- INPUT POL -------------------
        REN_IN          => SQU_REN_IN,
        ADDR_IN         => SQU_ADDR_IN,
        DIN_IN          => SQU_DIN_IN,
        -- OUTPUT POL ------------------
        WEN_OUT         => SQU_WEN_OUT,
        ADDR_OUT        => SQU_ADDR_OUT,
        DOUT_OUT        => SQU_DOUT_OUT
    );
    ------------------------------------------------------------------------------
      
    -- Multiplier ----------------------------------------------------------------
    SK_REN <= SQU_REN_IN WHEN ROUND_INIT = '1' ELSE MUL_VECTOR_RDEN WHEN MUL_ADDITIONAL = '1' OR ROUND_MUL_INIT = '1' ELSE '0';
    SK_ADDR <= SQU_ADDR_IN WHEN ROUND_INIT = '1' ELSE MUL_VECTOR_ADDR;
    
    H1_IN_REN   <= MUL_VECTOR_RDEN WHEN LAST_MUL = '1' ELSE '0';
    H1_IN_ADDR  <= MUL_VECTOR_ADDR WHEN LAST_MUL = '1' ELSE (OTHERS => '0');
    
    MUL : ENTITY work.BIKE_MULTIPLIER
    PORT MAP ( 
        CLK                 => CLK,
        -- CONTROL PORTS ---------------   
        RESET               => MUL_RESET,
        ENABLE              => MUL_ENABLE,
        DONE                => MUL_DONE,
        -- RESULT ----------------------
        RESULT_RDEN         => MUL_RESULT_RDEN, 
        RESULT_WREN         => MUL_RESULT_WREN,
        RESULT_ADDR         => MUL_RESULT_ADDR,
        RESULT_DOUT_0       => MUL_RESULT_DOUT,
        RESULT_DIN_0        => MUL_RESULT_DIN,
        -- Matrix ----------------------
        K_RDEN              => MUL_MATRIX_RDEN,
        K_WREN              => MUL_MATRIX_WREN,
        K_ADDR              => MUL_MATRIX_ADDR,
        K_DOUT_0            => MUL_MATRIX_DOUT,
        K_DIN_0             => MUL_MATRIX_DIN,
        -- Vector ----------------------
        M_RDEN              => MUL_VECTOR_RDEN,
        M_ADDR              => MUL_VECTOR_ADDR,
        M_DIN               => MUL_VECTOR_DIN    
    );    
    ------------------------------------------------------------------------------
      
    -- BRAM - SECRET KEY ---------------------------------------------------------
    -- can be replaced by an BRAM for testing
    POL_IN_REN  <= SK_REN;
    POL_IN_ADDR <= SK_ADDR;
    SK_DOUT0    <= POL_IN_DIN;
    ------------------------------------------------------------------------------
        
    -- BRAM - INTERMEDIATE RESULTS -----------------------------------------------
    BRAM_0 : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 1)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => DOUT_RDEN,
        -- SAMPLING --------------------
        REN_SAMP        => DOUT_RDEN,
        WEN_SAMP        => '0',
        ADDR_SAMP       => CNT_OUTPUT_OUT,
        DOUT_SAMP       => INV_DOUT_0,
        DIN_SAMP        => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN             => B_WEN(0),
        REN             => B_REN(0),
        ADDR            => B0_ADDR,
        DOUT            => B0_DOUT0,
        DIN             => B0_DIN0
    );
    
    BRAM_1 : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 1)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => DOUT_RDEN,
        -- SAMPLING --------------------
        REN_SAMP        => DOUT_RDEN,
        WEN_SAMP        => '0',
        ADDR_SAMP       => CNT_OUTPUT_OUT,
        DOUT_SAMP       => INV_DOUT_1,
        DIN_SAMP        => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN             => B_WEN(1),
        REN             => B_REN(1),
        ADDR            => B1_ADDR,
        DOUT            => B1_DOUT0,
        DIN             => B1_DIN0
    );
    
    BRAM_2 : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 1)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => DOUT_RDEN,
        -- SAMPLING --------------------
        REN_SAMP        => DOUT_RDEN,
        WEN_SAMP        => '0',
        ADDR_SAMP       => CNT_OUTPUT_OUT,
        DOUT_SAMP       => INV_DOUT_2,
        DIN_SAMP        => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN             => B_WEN(2),
        REN             => B_REN(2),
        ADDR            => B2_ADDR,
        DOUT            => B2_DOUT0,
        DIN             => B2_DIN0
    );
    ------------------------------------------------------------------------------
      
    -- OUTPUT --------------------------------------------------------------------
    DONE_REG : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                DONE <= '0';
            ELSE
                DONE <= DONE_INT;
            END IF;
        END IF;
    END PROCESS;
    
    
    -- counter
    OUTPUT_COUNTER : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(R_BLOCKS), MAX_VALUE => R_BLOCKS)
    PORT MAP(CLK => CLK, EN => DONE_INT, RST => RESET, CNT_OUT => CNT_OUTPUT_OUT);
    
    -- select correct output data
    DOUT <= (OTHERS => '0') WHEN DONE_INT = '0' ELSE INV_DOUT;
    
    WITH LAST_STATE_SEL_BREM SELECT INV_DOUT <=
        INV_DOUT_0 WHEN S_VMR,
        INV_DOUT_0 WHEN S_MVR,
        INV_DOUT_1 WHEN S_MRV,
        INV_DOUT_1 WHEN S_VRM,
        INV_DOUT_2 WHEN S_RVM,
        INV_DOUT_2 WHEN S_RMV,
        (OTHERS => '0') WHEN OTHERS; 
        
    -- read enable
    DOUT_RDEN <= DONE_INT; 
    ------------------------------------------------------------------------------
      
    -- FSM -----------------------------------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET                =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '1';
                    
                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';

                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';
                    
                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN                   
                        STATE               <= S_SQU_INIT;
                    ELSE
                        STATE               <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_SQU_INIT             =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '0';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';
                    
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '1';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '0';
                    SQU_ENABLE              <= '1';

                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (SQU_DONE = '1') THEN
                        STATE               <= S_MUL_INIT;
                    ELSE
                        STATE               <= S_SQU_INIT;
                    END IF;
                ----------------------------------------------    

                ----------------------------------------------
                WHEN S_MUL_INIT             =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '0';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';                    
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '1';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';

                    MUL_RESET               <= '0';
                    MUL_ENABLE              <= '1';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (MUL_DONE = '1') THEN
                        IF ADDITIONAL_COMP = '1' THEN
                            CNT_ROUND_EN    <= '0';
                            STATE           <= S_SQUARING_ADD;
                        ELSE
                            CNT_ROUND_EN    <= '1';
                            STATE           <= S_SQUARING0;
                        END IF;
                    ELSE
                        CNT_ROUND_EN        <= '0';
                        STATE               <= S_MUL_INIT;
                    END IF;
                ---------------------------------------------- 
                
                ----------------------------------------------
                WHEN S_SQUARING0            =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '0';

                    CNT_SQU_RST             <= '0';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '0';
                    SQU_ENABLE              <= '1';

                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (SQU_CHAIN_DONE = '1') THEN
                        CNT_SQU_EN          <= '0';
                
                        SQU_RESET           <= '1';
                        SQU_ENABLE          <= '0';
                    
                        IF CNT_ROUND_DONE = '1' THEN
                            STATE           <= S_MUL_LAST;
                        ELSE
                            STATE           <= S_MUL;
                        END IF;
                    ELSE
                        IF (SQU_DONE = '1') THEN                            
                            CNT_SQU_EN      <= '1';
                        
                            SQU_RESET       <= '1';
                            SQU_ENABLE      <= '0';
                        
                            STATE           <= S_SQUARING1;
                        ELSE
                            CNT_SQU_EN      <= '0';
                            
                            SQU_RESET       <= '0';
                            SQU_ENABLE      <= '1';
                        
                            STATE           <= S_SQUARING0;
                        END IF;
                    END IF;
                ---------------------------------------------- 

                ----------------------------------------------
                WHEN S_SQUARING1            =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '0';
                    
                    CNT_SQU_RST             <= '0';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '0';
                    SQU_ENABLE              <= '1';

                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (SQU_CHAIN_DONE = '1') THEN
                        CNT_SQU_EN          <= '0';
                        
                        SQU_RESET           <= '1';
                        SQU_ENABLE          <= '0';
                        
                        STATE               <= S_MUL;
                    ELSE
                        IF (SQU_DONE = '1') THEN
                            CNT_SQU_EN      <= '1';
                        
                            SQU_RESET       <= '1';
                            SQU_ENABLE      <= '0';
                        
                            STATE           <= S_SQUARING0;
                        ELSE
                            CNT_SQU_EN      <= '0';
                            
                            SQU_RESET       <= '0';
                            SQU_ENABLE      <= '1';
                        
                            STATE           <= S_SQUARING1;
                        END IF;
                    END IF;
                ----------------------------------------------
                                
                ----------------------------------------------
                WHEN S_MUL                  =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_RST           <= '0';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';

                    MUL_RESET               <= '0';
                    MUL_ENABLE              <= '1';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (MUL_DONE = '1') THEN
                        IF ADDITIONAL_COMP = '1' THEN
                            CNT_ROUND_EN    <= '0';
                            
                            STATE           <= S_SQUARING_ADD;
                        ELSE
                            CNT_ROUND_EN    <= '1';
                            
                            STATE           <= S_SQUARING0;
                        END IF;
                    ELSE
                        CNT_ROUND_EN        <= '0';
                        STATE               <= S_MUL;
                    END IF;
                ---------------------------------------------- 

                ----------------------------------------------
                WHEN S_SQUARING_ADD         =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '0';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '0';
                    SQU_ENABLE              <= '1';

                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '1';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (SQU_DONE = '1') THEN
                        STATE               <= S_MUL_ADD;
                    ELSE
                        STATE               <= S_SQUARING_ADD;
                    END IF;
                ---------------------------------------------- 

                ----------------------------------------------
                WHEN S_MUL_ADD              =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_RST           <= '0';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';

                    MUL_RESET               <= '0';
                    MUL_ENABLE              <= '1';

                    MUL_ADDITIONAL          <= '1';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                                          
                    -- TRANSITION ------
                    IF (MUL_DONE = '1') THEN
                        CNT_ROUND_EN        <= '1';
                        
                        STATE               <= S_SQUARING0;
                    ELSE
                        CNT_ROUND_EN        <= '0';
                        
                        STATE               <= S_MUL_ADD;
                    END IF;
                ---------------------------------------------- 

                ----------------------------------------------
                WHEN S_MUL_LAST             =>
                    -- GLOBAL ----------
                    DONE_INT                <= '0';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_RST           <= '1';
                    CNT_ROUND_EN            <= '0';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';

                    MUL_RESET               <= '0';
                    MUL_ENABLE              <= '1';

                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '1';
                                                          
                    -- TRANSITION ------
                    IF (MUL_DONE = '1') THEN
                        STATE               <= S_OUTPUT;
                    ELSE      
                        STATE               <= S_MUL_LAST;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_OUTPUT               =>
                    -- GLOBAL ----------
                    DONE_INT                <= '1';
                    DONE_OUT                <= '0';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '1';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';    
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';
    
                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';
                    
                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                        
                    -- TRANSITION ------
                    IF CNT_OUTPUT_DONE = '1' THEN
                        STATE       <= S_DONE;
                    ELSE
                        STATE       <= S_OUTPUT;
                    END IF;
                ----------------------------------------------
                                                                                                                
                ----------------------------------------------
                WHEN S_DONE                 =>
                    -- GLOBAL ----------
                    DONE_INT                <= '1';
                    DONE_OUT                <= '1';
                
                    -- COUNTER ---------
                    CNT_ROUND_EN            <= '0';
                    CNT_ROUND_RST           <= '1';

                    CNT_SQU_EN              <= '0';
                    CNT_SQU_RST             <= '1';    
                    
                    -- CONTROL ---------
                    ROUND_INIT              <= '0';
                    ROUND_MUL_INIT          <= '0';
                    
                    SQU_RESET               <= '1';
                    SQU_ENABLE              <= '0';
    
                    MUL_RESET               <= '1';
                    MUL_ENABLE              <= '0';
                    
                    MUL_ADDITIONAL          <= '0';
                    SQU_ADDITIONAL          <= '0';
                    
                    LAST_MUL                <= '0';
                                        
                    -- TRANSITION ------
                    IF RESET = '1' THEN
                        STATE       <= S_RESET;
                    ELSE 
                        STATE       <= S_DONE;
                    END IF;
                ----------------------------------------------
                                
            END CASE;
        END IF;
    END PROCESS;    
    ------------------------------------------------------------------------------
        
END Structural;
