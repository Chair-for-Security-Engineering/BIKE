----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       07/04/2020
-- LAST CHANGES:      07/04/2020
-- MODULE NAME:       BIKE_INVERSION_FSM_BRAM
--
-- REVISION:          1.00 - File created.
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

LIBRARY UNISIM;
    USE UNISIM.vcomponents.ALL;
LIBRARY UNIMACRO;
    USE unimacro.Vcomponents.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_INVERSION_FSM_BRAM IS
    PORT (  
        -- CONTROL PORTS ---------------
        CLK             : IN  STD_LOGIC; 	
        RESET           : IN  STD_LOGIC;
        EVENODD         : IN  STD_LOGIC;
        SQU_DONE        : IN  STD_LOGIC;
        MUL_DONE        : IN  STD_LOGIC;
        -- OUTPUT ----------------------
        STATE_OUT       : OUT STATES_BRAM_SEL
    );
END BIKE_INVERSION_FSM_BRAM;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_INVERSION_FSM_BRAM IS


-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL STATE_INT        : STD_LOGIC_VECTOR(3 DOWNTO 0);


-- STATES (defined in settings.vhd)
----------------------------------------------------------------------------------
SIGNAL STATE : STATES_BRAM_SEL := S_SQU_0;


-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    STATE_OUT <= STATE;

    -- FSM -----------------------------------------------------------------------
    SELECTION_BRAM : PROCESS(CLK, EVENODD, SQU_DONE, MUL_DONE, RESET)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                STATE <= S_SQU_0;
            ELSE
                CASE STATE IS
                    ----------------------------------------
                    WHEN S_SQU_0 =>
                        IF EVENODD = '1' AND SQU_DONE = '1' THEN
                            STATE <= S_RMV;
                        ELSIF EVENODD = '0' AND SQU_DONE = '1' THEN
                            STATE <= S_MRV;
                        ELSE 
                            STATE <= S_SQU_0;
                        END IF;
                    ----------------------------------------
                    
                    ----------------------------------------
                    WHEN S_SQU_1 =>
                        IF EVENODD = '1' AND SQU_DONE = '1' THEN
                            STATE <= S_MVR;
                        ELSIF EVENODD = '0' AND SQU_DONE = '1' THEN
                            STATE <= S_RVM;
                        ELSE 
                            STATE <= S_SQU_1;
                        END IF;
                    ----------------------------------------

                    ----------------------------------------
                    WHEN S_SQU_2 =>
                        IF EVENODD = '1' AND SQU_DONE = '1' THEN
                            STATE <= S_VRM;
                        ELSIF EVENODD = '0' AND SQU_DONE = '1' THEN
                            STATE <= S_VMR;
                        ELSE 
                            STATE <= S_SQU_2;
                        END IF;
                    ----------------------------------------
                    
                    ----------------------------------------
                    WHEN S_MVR =>
                        IF MUL_DONE = '1' THEN
                            STATE <= S_SQU_0;
                        ELSE 
                            STATE <= S_MVR;
                        END IF;
                    ----------------------------------------                                    

                    ----------------------------------------
                    WHEN S_VMR =>
                        IF MUL_DONE = '1' THEN
                            STATE <= S_SQU_0;
                        ELSE 
                            STATE <= S_VMR;
                        END IF;
                    ----------------------------------------  

                    ----------------------------------------
                    WHEN S_MRV =>
                        IF MUL_DONE = '1' THEN
                            STATE <= S_SQU_1;
                        ELSE 
                            STATE <= S_MRV;
                        END IF;
                    ----------------------------------------                     
                    
                    ----------------------------------------
                    WHEN S_VRM =>
                        IF MUL_DONE = '1' THEN
                            STATE <= S_SQU_1;
                        ELSE 
                            STATE <= S_VRM;
                        END IF;
                    ----------------------------------------                      
                    
                    ----------------------------------------
                    WHEN S_RMV =>
                        IF MUL_DONE = '1' THEN
                            STATE <= S_SQU_2;
                        ELSE 
                            STATE <= S_RMV;
                        END IF;
                    ---------------------------------------- 

                    ----------------------------------------
                    WHEN S_RVM =>
                        IF MUL_DONE = '1' THEN
                            STATE <= S_SQU_2;
                        ELSE 
                            STATE <= S_RVM;
                        END IF;
                    ---------------------------------------- 
                                        
                    ----------------------------------------
                    WHEN OTHERS => 
                        STATE_INT <= "0000";
                    ----------------------------------------
                                                          
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------

END Behavioral;
