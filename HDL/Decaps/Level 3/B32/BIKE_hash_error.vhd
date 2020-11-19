----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    04/05/2020
-- LAST CHANGES:            03/11/2020
-- MODULE NAME:			    BIKE_HASH_ERROR
--
-- REVISION:				1.10 - Fixed bug (some entries where not correctly hashed).
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
ENTITY BIKE_HASH_ERROR IS
	PORT (  
        CLK                 : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET               : IN  STD_LOGIC;
        HASH_EN             : IN  STD_LOGIC;
        HASH_DONE           : IN  STD_LOGIC;
        -- ERROR BRAM ------------------
        ERROR0_RDEN         : OUT STD_LOGIC;
        ERROR1_RDEN         : OUT STD_LOGIC;
        ERROR0_ADDR         : OUT STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        ERROR1_ADDR         : OUT STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        ERROR0_DIN          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        ERROR1_DIN          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- HASH ------------------------
        HASH_M              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        HASH_VALID          : OUT STD_LOGIC;
        HASH_RDY            : IN  STD_LOGIC
    );
END BIKE_HASH_ERROR;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE_HASH_ERROR IS



-- CONSTANTS
----------------------------------------------------------------------------------
--CONSTANT OVERHANG        : INTEGER := R_BITS - 32*(R_BLOCKS-1);   -- use this setting if e represented as one polynomial should be hashed
CONSTANT OVERHANG        : INTEGER := 8 * CEIL(R_BITS - 32*(R_BLOCKS-1), 8);    -- use this setting if e0 || e1 should be hashed (represented in bytes)
--CONSTANT OVERHANG        : INTEGER := R_BITS - 32*(R_BLOCKS-1);
--CONSTANT NUM_LOWER_BYTES : INTEGER := CEIL(OVERHANG,8); 
--CONSTANT OVER            : INTEGER := R_BITS - 32*(R_BLOCKS-1);
--CONSTANT NUM_LAST_BYTES  : INTEGER := FLOOR(OVER, 8);
--CONSTANT NUM_BITS        : INTEGER := MY_MOD(OVER, 8);  



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_HASH_FIRST_PART, S_HASH_SECOND_PART, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_ADDR_EN, CNT_ADDR_RST                        : STD_LOGIC;
SIGNAL CNT_ADDR_OUT                                     : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

-- BRAM PORTS HASH
SIGNAL ADDR_E0, ADDR_E1                                 : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

-- SHA
SIGNAL SHA_M_VALID                                      : STD_LOGIC;

-- CONTROLLING
SIGNAL SECOND_PART                                      : STD_LOGIC;
SIGNAL SEC_ENABLE                                       : STD_LOGIC;
SIGNAL FIRST_M, SECOND_M, COMP_M                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SECOND_M_PRE, SECOND_M_SWITCH, SECOND_M_SW       : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL INT_ERROR1                                       : STD_LOGIC_VECTOR(OVERHANG-1 DOWNTO 0);



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN    
    
    -- DATA REORDERING -----------------------------------------------------------
    ERROR0_ADDR <= ADDR_E0; 
    ERROR1_ADDR <= ADDR_E1; 
    
    ERROR0_RDEN <= HASH_RDY;
    ERROR1_RDEN <= HASH_RDY;
    
    ADDR_E0 <= CNT_ADDR_OUT;
    ADDR_E1 <= (OTHERS => '0') WHEN CNT_ADDR_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(R_BLOCKS-1, LOG2(R_BLOCKS))) ELSE STD_LOGIC_VECTOR(UNSIGNED(CNT_ADDR_OUT)+1);
    
    -- input data need to be rearranged as our memory layout differs that from the reference implementation
    HASH_M  <= FIRST_M WHEN SECOND_PART = '0' ELSE COMP_M;

    -- reordering for e0
    FIRST_M         <= ERROR0_DIN(7 DOWNTO 0) & ERROR0_DIN(15 DOWNTO 8) & ERROR0_DIN(23 DOWNTO 16) & ERROR0_DIN(31 DOWNTO 24);
    
    -- reordering for switching between e0 and e1
    SECOND_M_SWITCH <= ERROR1_DIN(32-OVERHANG-1 DOWNTO 0) & ERROR0_DIN(OVERHANG-1 DOWNTO 0);
    SECOND_M_SW     <= SECOND_M_SWITCH(7 DOWNTO 0) & SECOND_M_SWITCH(15 DOWNTO 8) & SECOND_M_SWITCH(23 DOWNTO 16) & SECOND_M_SWITCH(31 DOWNTO 24);
    
    -- reordering for e1
    SECOND_M_PRE    <= ERROR1_DIN(32-OVERHANG-1 DOWNTO 0) & INT_ERROR1;    
    SECOND_M        <= SECOND_M_PRE(7 DOWNTO 0) & SECOND_M_PRE(15 DOWNTO 8) & SECOND_M_PRE(23 DOWNTO 16) & SECOND_M_PRE(31 DOWNTO 24);
    
    --COMP_M          <= SECOND_M_SW WHEN SWITCH_POLY_D = '1' ELSE SECOND_M;
    COMP_M          <= SECOND_M_SW WHEN CNT_ADDR_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(R_BLOCKS)))  ELSE SECOND_M;
    
    -- store higher bits in a register
    REG_E2_PART : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => OVERHANG)
    PORT MAP(D => ERROR1_DIN(31 DOWNTO 32-OVERHANG), Q => INT_ERROR1, CLK => CLK, EN => SECOND_PART, RST => RESET);
    
    REG_M_VALID : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            SHA_M_VALID <= HASH_RDY;
        END IF;
    END PROCESS;

    SEC_ENABLE <= '1' WHEN CNT_ADDR_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(R_BLOCKS-1, LOG2(R_BLOCKS))) ELSE '0';
    
    REG_SEC_POLY : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                SECOND_PART <= '0';
            ELSE
                IF SEC_ENABLE = '1' THEN
                    SECOND_PART <= '1';
                END IF;
             END IF;
        END IF;
    END PROCESS;
        
    HASH_VALID <= SHA_M_VALID;
    ------------------------------------------------------------------------------  
    
 
    -- COUNTER -------------------------------------------------------------------
    CNT_ADDR_EN <= HASH_RDY;
    CNT_ADDR : ENTITY work.BIKE_counter_inc GENERIC MAP(SIZE => LOG2(R_BLOCKS), MAX_VALUE => R_BLOCKS-1)
    PORT MAP(CLK => CLK, EN => CNT_ADDR_EN, RST => CNT_ADDR_RST, CNT_OUT => CNT_ADDR_OUT);
    ------------------------------------------------------------------------------
    
    
    -- FINITE STATE MACHINE ------------------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET        =>
                    -- COUNTER ---------
                    CNT_ADDR_RST    <= '1';                              
                    
                    -- TRANSITION ------
                    IF (HASH_EN = '1') THEN
                        STATE       <= S_HASH_FIRST_PART;
                    ELSE
                        STATE       <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_HASH_FIRST_PART  =>
                    -- COUNTER ---------
                    CNT_ADDR_RST    <= '0';
                                                                                
                    -- TRANSITION ------
                    IF (UNSIGNED(CNT_ADDR_OUT) = R_BLOCKS-2) THEN 
                        STATE       <= S_HASH_SECOND_PART;
                    ELSE
                        STATE       <= S_HASH_FIRST_PART;                      
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_HASH_SECOND_PART         =>
                    -- COUNTER ---------
                    CNT_ADDR_RST    <= '0'; 
                                                                                
                    -- TRANSITION ------
                    IF (HASH_DONE = '1') THEN
                        STATE           <= S_DONE;
                    ELSE
                        STATE           <= S_HASH_SECOND_PART;
                    END IF;
                ----------------------------------------------    
                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- COUNTER ---------
                    CNT_ADDR_RST    <= '1'; 
                                                            
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
