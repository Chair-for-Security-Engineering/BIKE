----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    04/05/2020
-- LAST CHANGES:            04/05/2020
-- MODULE NAME:			    BIKE_HASH_MC
--
-- REVISION:				1.00 - File created.
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or	if you have questions regarding the code
--							please contact Tim Güneysu (tim.gueneysu@rub.de) and
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
    USE IEEE.MATH_REAL.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_HASH_MC IS
	PORT (  
        CLK                 : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET               : IN  STD_LOGIC;
        HASH_EN             : IN  STD_LOGIC;
        -- DATA ------------------------
        MESSAGE             : IN  WORD_ARRAY(7 DOWNTO 0);
        C1                  : IN  WORD_ARRAY(7 DOWNTO 0);
        C0_RDEN             : OUT STD_LOGIC;
        C0_ADDR             : OUT STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        C0                  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- HASH ------------------------
        HASH_M              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        HASH_VALID          : OUT STD_LOGIC;
        HASH_RDY            : IN  STD_LOGIC
    );
END BIKE_HASH_MC;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE_HASH_MC IS
 


-- CONSTANTS
----------------------------------------------------------------------------------
CONSTANT OVERHANG        : INTEGER := R_BITS - 32*(R_BLOCKS-1);
CONSTANT NUM_LOWER_BYTES : INTEGER := CEIL(OVERHANG,8); 



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_M, S_C0_INIT, S_C0, S_C1_INIT, S_C1, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- SIGNALS
----------------------------------------------------------------------------------
-- Counter
SIGNAL CNT_REG_EN, CNT_REG_RST      : STD_LOGIC;
SIGNAL CNT_REG_EN_GATED             : STD_LOGIC;
SIGNAL CNT_REG_OUT                  : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0);

SIGNAL CNT_BRAM_EN, CNT_BRAM_RST    : STD_LOGIC;
SIGNAL CNT_BRAM_EN_GATED            : STD_LOGIC;
SIGNAL CNT_BRAM_OUT                 : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

-- Controlling
SIGNAL SEL_HASH_INPUT               : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL INITIAL_C1                   : STD_LOGIC;
SIGNAL HASH_VALID_INT               : STD_LOGIC;

-- Data
SIGNAL C0_REORDERED                 : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL C1_INIT, C1_REGULAR, C1_COMP : STD_LOGIC_VECTOR(31 DOWNTO 0);



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

    -- REORDERING AND COMPOSITION ------------------------------------------------
    C0_REORDERED    <= C0(7 DOWNTO 0) & C0(15 DOWNTO 8) & C0(23 DOWNTO 16) & C0(31 DOWNTO 24);
    
    C1_INIT         <= C0_REORDERED(31 DOWNTO 8*(4-NUM_LOWER_BYTES)) & C1(0)(31 DOWNTO 8*NUM_LOWER_BYTES);
    C1_REGULAR      <= C1(TO_INTEGER(UNSIGNED(CNT_REG_OUT)))(NUM_LOWER_BYTES*8-1 DOWNTO 0) & C1(TO_INTEGER(UNSIGNED(CNT_REG_OUT)+1))(31 DOWNTO NUM_LOWER_BYTES*8);
    C1_COMP         <= C1_INIT WHEN INITIAL_C1 = '1' ELSE C1_REGULAR;
    
    WITH SEL_HASH_INPUT SELECT HASH_M <=
        MESSAGE(TO_INTEGER(UNSIGNED(CNT_REG_OUT)))  WHEN "001",
        C0_REORDERED                                WHEN "010",
        C1_COMP                                     WHEN "100",
        (OTHERS => '0')                             WHEN OTHERS;
        
    REG_M_VALID : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            HASH_VALID_INT <= HASH_RDY;
        END IF;
    END PROCESS;
    
    HASH_VALID <= HASH_VALID_INT;
    ------------------------------------------------------------------------------
    
    
    -- COUNTER -------------------------------------------------------------------
    CNT_REG_EN_GATED <= CNT_REG_EN AND HASH_VALID_INT;
    REG_CNT : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(CEIL(L,32)), MAX_VALUE => CEIL(L,32))
    PORT MAP(CLK => CLK, EN => CNT_REG_EN_GATED, RST => CNT_REG_RST, CNT_OUT => CNT_REG_OUT);
    
    CNT_BRAM_EN_GATED <= CNT_BRAM_EN AND HASH_RDY;
    BRAM_CNT : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(R_BLOCKS), MAX_VALUE => R_BLOCKS)
    PORT MAP(CLK => CLK, EN => CNT_BRAM_EN_GATED, RST => CNT_BRAM_RST, CNT_OUT => CNT_BRAM_OUT);
    C0_ADDR <= CNT_BRAM_OUT;
    ------------------------------------------------------------------------------
    
    
    -- FINITE STATE MACHINE ------------------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET        =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "000";
                    C0_RDEN         <= '0';
                    INITIAL_C1      <= '0';     
                    
                    -- COUNTER ---------
                    CNT_REG_RST     <= '1';
                    CNT_REG_EN      <= '0';
                                 
                    CNT_BRAM_RST    <= '1';
                    CNT_BRAM_EN     <= '0';       
                                        
                    -- TRANSITION ------
                    IF (HASH_EN = '1') THEN
                        STATE       <= S_M;
                    ELSE
                        STATE       <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_M =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "001";
                    C0_RDEN         <= '0';
                    INITIAL_C1      <= '0';                 
                    
                    -- COUNTER ---------
                    CNT_REG_RST     <= '0';
                    CNT_REG_EN      <= '1';
                                 
                    CNT_BRAM_RST    <= '1';
                    CNT_BRAM_EN     <= '0';
                                                                      
                    -- TRANSITION ------
                    IF (CNT_REG_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(CEIL(L,32)-3 ,LOG2(CEIL(L,32))))) THEN
                        STATE       <= S_C0_INIT;
                    ELSE
                        STATE       <= S_M;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_C0_INIT =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "001";
                    C0_RDEN         <= '1';
                    INITIAL_C1      <= '0';
                                     
                    -- COUNTER ---------
                    CNT_REG_RST     <= '0';
                    CNT_REG_EN      <= '1';
                                 
                    CNT_BRAM_RST    <= '0';
                    CNT_BRAM_EN     <= '1';
                                                                
                    -- TRANSITION ------
                    STATE           <= S_C0;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_C0 =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "010";
                    C0_RDEN         <= '1';
                    INITIAL_C1      <= '0';

                    -- COUNTER ---------
                    CNT_REG_RST     <= '1';
                    CNT_REG_EN      <= '0';
                                 
                    CNT_BRAM_RST    <= '0';
                    CNT_BRAM_EN     <= '1';
                                                        
                    -- TRANSITION ------
                    IF (CNT_BRAM_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(R_BLOCKS-2 ,LOG2(R_BLOCKS)))) THEN
                        STATE       <= S_C1_INIT;
                    ELSE
                        STATE       <= S_C0;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_C1_INIT =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "100";
                    C0_RDEN         <= '1';
                    INITIAL_C1      <= '1';
                    
                    -- COUNTER ---------
                    CNT_REG_RST     <= '1';
                    CNT_REG_EN      <= '0';
                                 
                    CNT_BRAM_RST    <= '1';
                    CNT_BRAM_EN     <= '0';

                                                                                
                    -- TRANSITION ------
                    STATE           <= S_C1;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_C1 =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "100";
                    C0_RDEN         <= '0';
                    INITIAL_C1      <= '0';

                    -- COUNTER ---------
                    CNT_REG_RST     <= '0';
                    CNT_REG_EN      <= '1';
                                 
                    CNT_BRAM_RST    <= '1';
                    CNT_BRAM_EN     <= '0';

                                                                                
                    -- TRANSITION ------
                    IF (CNT_REG_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(CEIL(L,32)-2 ,LOG2(CEIL(L,32))))) THEN
                        STATE       <= S_DONE;
                    ELSE
                        STATE       <= S_C1;
                    END IF;
                ----------------------------------------------                 
                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- CONTROLLING -----
                    SEL_HASH_INPUT  <= "000";
                    C0_RDEN         <= '0';
                    INITIAL_C1      <= '0';
                         
                    -- COUNTER ---------
                    CNT_REG_RST     <= '1';
                    CNT_REG_EN      <= '0';
                                 
                    CNT_BRAM_RST    <= '1';
                    CNT_BRAM_EN     <= '0';
                                                    
                    -- TRANSITION ------
                    IF (RESET = '1') THEN
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
