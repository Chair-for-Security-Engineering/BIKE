----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2019 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    05/03/2019
-- LAST CHANGES:            05/03/2019
-- MODULE NAME:			    BIKE_SAMPLER_UNIFORM
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

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_SAMPLER_UNIFORM IS
    GENERIC (
        SAMPLE_LENGTH   : INTEGER := 256
    );
	PORT (  
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        DONE            : OUT STD_LOGIC;
        -- RAND ------------------------
        NEW_RAND        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- MEMORY I/O ------------------
        RDEN            : OUT STD_LOGIC;
        WREN            : OUT STD_LOGIC;
        ADDR            : OUT STD_LOGIC_VECTOR(LOG2(CEIL(L, 32))-1 DOWNTO 0);
        DOUT            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END BIKE_SAMPLER_UNIFORM;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_SAMPLER_UNIFORM IS



-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_RESET, CNT_ENABLE, CNT_VALID : STD_LOGIC;
SIGNAL CNT_OUT                          : STD_LOGIC_VECTOR(LOG2(CEIL(SAMPLE_LENGTH, 32))-1 DOWNTO 0);

-- GLOBAL
SIGNAL LAST_BLOCK                       : STD_LOGIC;



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_SAMPLE, S_SAMPLE_LAST, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- Behavioral
----------------------------------------------------------------------------------
BEGIN

    -- WRITE RANDOMNESS TO BRAM --------------------------------------------------
    ADDR <= CNT_OUT;
    
    I0 : IF MY_MOD(SAMPLE_LENGTH,32) = 0 GENERATE
        DOUT <= NEW_RAND;
    END GENERATE;
    
    I1 : IF MY_MOD(SAMPLE_LENGTH,32) /= 0 GENERATE
        DOUT <= NEW_RAND WHEN LAST_BLOCK = '0' ELSE (31 DOWNTO SAMPLE_LENGTH-32*(CEIL(SAMPLE_LENGTH, 32)-1) => '0') & NEW_RAND(SAMPLE_LENGTH-32*(CEIL(SAMPLE_LENGTH, 32)-1)-1 DOWNTO 0);
    END GENERATE;
    ------------------------------------------------------------------------------
 

    -- COUNTER ------------------------------------------------------------------- 
    COUNTER : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(CEIL(SAMPLE_LENGTH, 32)), MAX_VALUE => CEIL(SAMPLE_LENGTH, 32))
    PORT MAP(CLK => CLK, EN => CNT_ENABLE, RST => CNT_RESET, CNT_OUT => CNT_OUT);
    ------------------------------------------------------------------------------
    

    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET        =>
                    -- GLOBAL ----------
                    DONE            <= '0';
                    LAST_BLOCK      <= '0';
                    
                    -- BRAM ------------
                    RDEN            <= '0';
                    WREN            <= '0';
                    
                    -- COUNTER ---------
                    CNT_RESET       <= '1';
                    CNT_ENABLE      <= '0';
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN
                        STATE       <= S_SAMPLE;                  
                    ELSE
                        STATE       <= S_RESET;
                    END IF;
                ----------------------------------------------
 
                ----------------------------------------------
                WHEN S_SAMPLE       =>
                    -- GLOBAL ----------
                    DONE            <= '0';
                    LAST_BLOCK      <= '0';

                    -- BRAM ------------
                    RDEN            <= '1';
                    WREN            <= '1';
                                        
                    -- COUNTER ---------
                    CNT_RESET       <= '0';
                    CNT_ENABLE      <= '1';
                    
                    -- TRANSITION ------
                    IF (CNT_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(CEIL(SAMPLE_LENGTH, 32)-3, LOG2(CEIL(SAMPLE_LENGTH, 32))))) THEN
                        STATE       <= S_SAMPLE_LAST;
                    ELSE
                        STATE       <= S_SAMPLE;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_SAMPLE_LAST  =>
                    -- GLOBAL ----------
                    DONE            <= '0';
                    LAST_BLOCK      <= '1';

                    -- BRAM ------------
                    RDEN            <= '1';
                    WREN            <= '1';
                                        
                    -- COUNTER ---------
                    CNT_RESET       <= '0';
                    CNT_ENABLE      <= '0';
                    
                    -- TRANSITION ------
                    STATE           <= S_DONE;
                ----------------------------------------------
                                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- GLOBAL ----------
                    DONE            <= '1';
                    LAST_BLOCK      <= '0';

                    -- BRAM ------------
                    RDEN            <= '0';
                    WREN            <= '0';
                                        
                    -- COUNTER ---------
                    CNT_RESET       <= '1';
                    CNT_ENABLE      <= '0';
                    
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

END Behavioral;
