----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       17/04/2020
-- LAST CHANGES:      17/04/2020
-- MODULE NAME:       BIKE_SQUARING_ARBITRARY
--
-- REVISION:          1.00 - File was created.
--
-- LICENCE:           Please look at licence.txt
-- USAGE INFORMATION: Please look at readme.txt. If licence.txt or readme.txt
--                    are missing or if you have questions regarding the code
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

LIBRARY UNISIM;
    USE UNISIM.vcomponents.ALL;
LIBRARY UNIMACRO;
    USE unimacro.Vcomponents.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_SQUARING_ARBITRARY IS
  PORT (  
    -- CONTROL PORTS ----------------
    CLK             : IN  STD_LOGIC; 	
    RESET           : IN  STD_LOGIC;
    ENABLE          : IN  STD_LOGIC;
    DONE            : OUT STD_LOGIC;
    -- MODULUS ---------------------
    INCREMENT_MOD   : IN  STD_LOGIC_VECTOR(LOG2(R_BITS) DOWNTO 0);
    -- INPUT POL -------------------
    REN_IN          : OUT STD_LOGIC;
    ADDR_IN         : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
    DIN_IN          : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
    -- OUTPUT POL ------------------
    WEN_OUT         : OUT STD_LOGIC;
    ADDR_OUT        : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
    DOUT_OUT        : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0)
  );
END BIKE_SQUARING_ARBITRARY;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_SQUARING_ARBITRARY IS


-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_EN_OUT, CNT_RST_OUT          : STD_LOGIC;
SIGNAL CNT_DONE_OUT                     : STD_LOGIC;
SIGNAL CNT_OUT_OUT                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);

SIGNAL CNT_EN_BIT, CNT_RST_BIT          : STD_LOGIC;
SIGNAL CNT_DONE_BIT                     : STD_LOGIC;
SIGNAL CNT_DONE_BIT_NORMAL              : STD_LOGIC;
SIGNAL CNT_DONE_BIT_LAST                : STD_LOGIC;
SIGNAL CNT_OUT_BIT                      : STD_LOGIC_VECTOR(LOG2(B_WIDTH)-1 DOWNTO 0);

-- ADDRESS COMPUTATION
SIGNAL NEW_BIT_POS_PRE                  : STD_LOGIC_VECTOR(LOG2(R_BITS) DOWNTO 0);
SIGNAL NEW_BIT_POS_RED                  : STD_LOGIC_VECTOR(LOG2(R_BITS) DOWNTO 0);
SIGNAL NEW_BIT_POS                      : STD_LOGIC_VECTOR(LOG2(R_BITS) DOWNTO 0);
SIGNAL NEW_BIT_POS_D                    : STD_LOGIC_VECTOR(LOG2(R_BITS) DOWNTO 0);

SIGNAL EN_NEW_BIT                       : STD_LOGIC;

SIGNAL BIT_SEL, BIT_SEL_D               : STD_LOGIC_VECTOR(LOG2(B_WIDTH)-1 DOWNTO 0);
SIGNAL CURRENT_BIT                      : STD_LOGIC;

SIGNAL SHIFT_WORDS                      : STD_LOGIC_VECTOR(B_WIDTH*(LOG2(B_WIDTH)+1)-1 DOWNTO 0);

SIGNAL OUTPUT_REG_EN                    : STD_LOGIC;
SIGNAL OUTPUT_REG_RST                   : STD_LOGIC;
SIGNAL OUTPUT_REG, OUTPUT_REG_IN        : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_INIT, S_SQU, S_INC_ADDR, S_DONE);
SIGNAL STATE : STATES := S_RESET;


-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN


    -- COUNTER -------------------------------------------------------------------
    CNT_DONE_OUT <= '0' WHEN CNT_OUT_OUT < STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) ELSE '1';    
    CNT_OUT : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP(CLK => CLK, EN => CNT_EN_OUT, RST => CNT_RST_OUT, CNT_OUT => CNT_OUT_OUT);
    
    CNT_DONE_BIT_NORMAL <= '1' WHEN CNT_OUT_BIT = STD_LOGIC_VECTOR(TO_UNSIGNED(B_WIDTH-3, LOG2(B_WIDTH))) ELSE '0';
    CNT_DONE_BIT_LAST   <= '1' WHEN CNT_OUT_BIT = STD_LOGIC_VECTOR(TO_UNSIGNED(OVERHANG-3, LOG2(B_WIDTH))) ELSE '0';
    CNT_DONE_BIT <= CNT_DONE_BIT_LAST WHEN CNT_DONE_OUT = '1' ELSE CNT_DONE_BIT_NORMAL;
    CNT_BIT : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(B_WIDTH), MAX_VALUE => B_WIDTH)
    PORT MAP(CLK => CLK, EN => CNT_EN_BIT, RST => CNT_RST_BIT, CNT_OUT => CNT_OUT_BIT);
    ------------------------------------------------------------------------------

    -- ADDRESS INPUT POLYNOMIAL --------------------------------------------------
    -- compute new bit position
    NEW_BIT_POS_PRE <= STD_LOGIC_VECTOR(UNSIGNED(NEW_BIT_POS_D) + UNSIGNED(INCREMENT_MOD));
    NEW_BIT_POS_RED <= STD_LOGIC_VECTOR(UNSIGNED(NEW_BIT_POS_PRE) - TO_UNSIGNED(R_BITS, LOG2(R_BITS)+1));
    NEW_BIT_POS <= NEW_BIT_POS_PRE WHEN NEW_BIT_POS_RED(LOG2(R_BITS)) = '1' ELSE NEW_BIT_POS_RED;
    
    BIT_POS_REG : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                NEW_BIT_POS_D <= (OTHERS => '0');
            ELSE
                IF  EN_NEW_BIT = '1' THEN
                    NEW_BIT_POS_D <= NEW_BIT_POS;
                ELSE    
                    NEW_BIT_POS_D <= NEW_BIT_POS_D;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- new address
    ADDR_IN <= NEW_BIT_POS_D(LOG2(R_BITS)-1 DOWNTO LOG2(B_WIDTH));
    
    -- current bit position in word
    BIT_SEL <= NEW_BIT_POS_D(LOG2(B_WIDTH)-1 DOWNTO 0);
    
    BIT_SEL_REG : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                BIT_SEL_D <= (OTHERS => '0');
            ELSE
                IF  ENABLE = '1' THEN
                    BIT_SEL_D <= BIT_SEL;
                ELSE    
                    BIT_SEL_D <= BIT_SEL_D;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- extract correct bit from input polynomial
    BIT_SELECTION : PROCESS(BIT_SEL_D, DIN_IN)
    BEGIN
        FOR W IN 0 TO B_WIDTH-1 LOOP
            IF BIT_SEL_D = STD_LOGIC_VECTOR( TO_UNSIGNED( W, LOG2(B_WIDTH))) THEN
                CURRENT_BIT <= DIN_IN(W);
            END IF; 
        END LOOP;
    END PROCESS;
    
    -- shift bit to correct position
    SHIFT_WORDS(B_WIDTH-1 DOWNTO 0) <= (B_WIDTH-1 DOWNTO 1 => '0') & CURRENT_BIT;    
    SHIFTER_C : FOR M IN 0 TO LOG2(B_WIDTH)-1 GENERATE
        SHIFT_WORDS(B_WIDTH*(M+2)-1 DOWNTO  B_WIDTH*(M+1)) <= SHIFT_WORDS(B_WIDTH*(M+1)-1-2**(LOG2(B_WIDTH)-1-M) DOWNTO B_WIDTH*M) & (2**(LOG2(B_WIDTH)-1-M)-1 DOWNTO 0 => '0') WHEN CNT_OUT_BIT(LOG2(B_WIDTH)-1-M) = '1' ELSE SHIFT_WORDS(B_WIDTH*(M+1)-1 DOWNTO B_WIDTH*M);
    END GENERATE;
    
    -- new output
    OUT_REG : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF OUTPUT_REG_RST = '1' THEN
                OUTPUT_REG <= (OTHERS => '0');
            ELSE
                IF  OUTPUT_REG_EN = '1' THEN
                    OUTPUT_REG <= OUTPUT_REG_IN;
                ELSE    
                    OUTPUT_REG <= OUTPUT_REG;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    OUTPUT_REG_IN <= OUTPUT_REG XOR SHIFT_WORDS(B_WIDTH*(LOG2(B_WIDTH)+1)-1 DOWNTO B_WIDTH*(LOG2(B_WIDTH)));
       
    DOUT_OUT <= OUTPUT_REG_IN; 
    
    
    -- address output polynomial
    ADDR_OUT <= CNT_OUT_OUT;
    ------------------------------------------------------------------------------



    -- FSM -----------------------------------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET                =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';
                    
                    CNT_EN_BIT              <= '0';
                    CNT_RST_BIT             <= '1';
                    
                    -- CONTROL ---------
                    EN_NEW_BIT              <= '0';
                    OUTPUT_REG_RST          <= '1';
                    OUTPUT_REG_EN           <= '0';
                    
                    -- BRAM ------------
                    REN_IN                  <= '0';
                    WEN_OUT                 <= '0';
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN                     
                        STATE               <= S_INIT;
                    ELSE
                        STATE               <= S_RESET;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_INIT                 =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';

                    CNT_EN_BIT              <= '0';
                    CNT_RST_BIT             <= '0';
                    
                    -- CONTROL ---------  
                    EN_NEW_BIT              <= '1';
                    OUTPUT_REG_RST          <= '1';  
                    OUTPUT_REG_EN           <= '0';            
                    
                    -- BRAM ------------
                    REN_IN                  <= '1';
                    WEN_OUT                 <= '0';
                                      
                    -- TRANSITION ------
                    STATE                   <= S_SQU;
                ----------------------------------------------    

                ----------------------------------------------
                WHEN S_SQU                  =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '0';
    
                    CNT_EN_BIT              <= '1';
                    CNT_RST_BIT             <= '0';
                    
                    -- CONTROL ---------                
                    EN_NEW_BIT              <= '1'; 
                    OUTPUT_REG_RST          <= '0';
                    OUTPUT_REG_EN           <= '1';
                    
                    -- BRAM ------------
                    REN_IN                  <= '1';
                    WEN_OUT                 <= '0';
                                      
                    -- TRANSITION ------
                    IF (CNT_DONE_BIT = '1') THEN
                        STATE           <= S_INC_ADDR;
                    ELSE
                        STATE           <= S_SQU;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_INC_ADDR             =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '1';
                    CNT_RST_OUT             <= '0';
    
                    CNT_EN_BIT              <= '1';
                    CNT_RST_BIT             <= '0';
                    
                    -- CONTROL ---------                
                    EN_NEW_BIT              <= '1'; 
                    OUTPUT_REG_RST          <= '1';
                    OUTPUT_REG_EN           <= '1';
                    
                    -- BRAM ------------
                    REN_IN                  <= '1';
                    WEN_OUT                 <= '1';
                                      
                    -- TRANSITION ------
                    IF CNT_DONE_OUT = '1' THEN
                        STATE               <= S_DONE;
                    ELSE
                        STATE               <= S_SQU;
                    END IF;
                ----------------------------------------------
                                                                
                ----------------------------------------------
                WHEN S_DONE                 =>
                    -- GLOBAL ----------
                    DONE                    <= '1';           
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';
                    
                    CNT_EN_BIT              <= '0';
                    CNT_RST_BIT             <= '1';
                    OUTPUT_REG_EN           <= '0';
                    
                    -- CONTROL ---------
                    EN_NEW_BIT              <= '0'; 
                    
                    -- BRAM ------------
                    REN_IN                  <= '0';
                    WEN_OUT                 <= '0';
                                        
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

END Behavioral;
