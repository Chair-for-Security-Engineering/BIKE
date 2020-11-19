----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_Controller
--
-- REVISION:				2.00 - Adapted controller to handle a round-based implementation
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



-- ENTITY
----------------------------------------------------------------------------------
ENTITY AES_Controller IS
	PORT (   
        CLK					: IN  STD_LOGIC;
        -- GLOBAL ----------------------
        DATA_AVAIL 			: IN  STD_LOGIC;
        DATA_READY 			: OUT STD_LOGIC;
        -- AES CONTROL PORTS -----------
        AES_INIT 			: OUT STD_LOGIC;
        AES_ENABLE			: OUT STD_LOGIC;
        AES_LAST 			: OUT STD_LOGIC;
        -- KEYSCHEDULE CONTROL PORTS ---
        KEY_INIT 			: OUT STD_LOGIC;
        KEY_ENABLE 			: OUT STD_LOGIC;
        -- ROUND COUNTER ---------------
        CNT_RESET			: OUT STD_LOGIC;
        CNT_ENABLE			: OUT STD_LOGIC;
        ROUND_COUNT			: IN  STD_LOGIC_VECTOR(3 DOWNTO 0)
    );	
END AES_Controller;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE FSM OF AES_Controller IS



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_INIT, S_ROUND, S_LAST, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- 1-PROCESS FSM
----------------------------------------------------------------------------------
BEGIN

	-- FINITE STATE MACHINE PROCESS ----------------------------------------------
	Moore : PROCESS(CLK)
	BEGIN
			
		-- SYNCHRONOUS STATE TRANSITION ------------------------------------------		
		IF RISING_EDGE(CLK) THEN
			
			-- CASE EVALUATION ---------------------------------------------------
			CASE STATE IS			
			
				------------------------------------------------------------------
				WHEN S_RESET			=> 
				    -- CONTROL -----------------	
                    DATA_READY					<= '0';
                    
                    -- INTERNAL CONTROL --------                    
                    CNT_RESET					<= '1';
                    CNT_ENABLE					<= '0';
                    
                    AES_LAST					<= '0';
                
                    -- TRANSITION --------------	
                    IF (DATA_AVAIL = '1') THEN
                        CNT_RESET				<= '0';
                        CNT_ENABLE              <= '1';
                    
                        AES_INIT				<= '0';
                        AES_ENABLE              <= '1';
                        
                        KEY_INIT                <= '1';
                        KEY_ENABLE              <= '1';
                    
                        STATE					<= S_INIT;
                    ELSE
                        CNT_RESET				<= '1';
                        CNT_ENABLE              <= '0';
                        
                        AES_INIT				<= '0';
                        AES_ENABLE              <= '0';
                        
                        KEY_INIT                <= '0';
                        KEY_ENABLE              <= '0';                    
                    
                        STATE					<= S_RESET;
                    END IF;   
				----------------------------------------------------------------------

				----------------------------------------------------------------------	
				WHEN S_INIT			=> 
				    -- CONTROL -----------------	
                    DATA_READY					<= '0';
                    
                    -- INTERNAL CONTROL --------                   
                    CNT_RESET					<= '0';
                    CNT_ENABLE					<= '1';
                    
                    AES_INIT					<= '1';
                    AES_ENABLE					<= '1'; 
                    AES_LAST					<= '0';
                    
                    KEY_INIT					<= '0';
                    KEY_ENABLE					<= '1';
                    
                    -- TRANSITION --------------
                    STATE                       <= S_ROUND;  							
				----------------------------------------------------------------------
																												
				----------------------------------------------------------------------	
				WHEN S_ROUND			=> 
				    -- CONTROL -----------------	
                    DATA_READY					<= '0';
                    
                    -- INTERNAL CONTROL --------                   
                    CNT_RESET					<= '0';
                    CNT_ENABLE					<= '1';
                    
                    AES_INIT					<= '0';
                    AES_ENABLE					<= '1'; 
                    AES_LAST					<= '0';
                    
                    KEY_INIT					<= '0';
                    KEY_ENABLE					<= '1';
                    
                    -- TRANSITION --------------
                    IF (ROUND_COUNT = X"D") THEN 
                        STATE                    <= S_LAST;
                    ELSE
                        STATE                    <= S_ROUND;
                    END IF;    							
				----------------------------------------------------------------------
												
				----------------------------------------------------------------------	
				WHEN S_LAST				=> 
				    -- CONTROL -----------------	
                    DATA_READY					<= '0';
                    
                    -- INTERNAL CONTROL --------                    
                    CNT_RESET					<= '0';
                    CNT_ENABLE					<= '0';
                    
                    AES_INIT					<= '0';
                    AES_ENABLE					<= '1';  
                    AES_LAST					<= '1';
                    
                    KEY_INIT					<= '0';
                    KEY_ENABLE					<= '0';
                
                    -- TRANSITION --------------	
                    STATE						<= S_DONE; 
                ----------------------------------------------------------------------
												
				----------------------------------------------------------------------	
				WHEN S_DONE			=> 
				    -- CONTROL -----------------	
                    DATA_READY					<= '1';
                    
                    -- INTERNAL CONTROL --------
                    CNT_RESET					<= '0';
                    CNT_ENABLE					<= '0';
                    
                    AES_INIT					<= '0';
                    AES_ENABLE					<= '0';  
                    AES_LAST					<= '0';
                    
                    KEY_INIT					<= '0';
                    KEY_ENABLE					<= '0';
                
                    -- TRANSITION --------------	
                    STATE                       <= S_RESET;
--                    IF (DATA_AVAIL = '0') THEN
--                        STATE					<= S_RESET;
--                    ELSE
--                        STATE					<= S_DONE;
--                    END IF;	
                ----------------------------------------------------------------------
			END CASE;
		END IF;
	END PROCESS;
	
END FSM;

