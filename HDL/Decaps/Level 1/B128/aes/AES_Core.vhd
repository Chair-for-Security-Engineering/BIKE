----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_Core
--
-- REVISION:				2.00 - Adapted to AES256.
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



-- ENTITY
----------------------------------------------------------------------------------
ENTITY AES256 IS
	PORT (
        CLK             : IN  STD_LOGIC;
        RESET           : IN  STD_LOGIC;
        -- CONTROL PORTS --------------------------------	
        DATA_AVAIL      : IN  STD_LOGIC;
        DATA_READY      : OUT STD_LOGIC;
        -- DATA PORTS -----------------------------------
        KEY 			: IN  STD_LOGIC_VECTOR (255 DOWNTO 0);
        DATA_IN 	    : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        DATA_OUT 	    : OUT STD_LOGIC_VECTOR (127 DOWNTO 0)
    );
END AES256;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF AES256 IS



-- SIGNALS
----------------------------------------------------------------------------------
-- AES
SIGNAL ROUND_IN, ROUND_OUT, ROUND_KEY	    : STD_LOGIC_VECTOR (127 DOWNTO 0);
SIGNAL IBUFFER, OBUFFER						: STD_LOGIC_VECTOR (127 DOWNTO 0);	

-- STATE MACHINE
SIGNAL ROUND_COUNT							: STD_LOGIC_VECTOR ( 3 DOWNTO 0);

SIGNAL RESET_IO, ENABLE_IN, ENABLE_OUT	    : STD_LOGIC;
SIGNAL AES_INIT, AES_ENABLE, AES_LAST	    : STD_LOGIC;
SIGNAL KEY_INIT, KEY_ENABLE				    : STD_LOGIC;
SIGNAL CNT_RESET, CNT_ENABLE				: STD_LOGIC;



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

	-- ENCRYPTION
	IBUFFER	       <= DATA_IN;

	-- ROUND COUNTER -------------------------------------------------------------
	CNT_ROUND : ENTITY work.COUNTER_INC GENERIC MAP (SIZE => 4)
	PORT MAP (CLK => CLK, EN => CNT_ENABLE, RST => CNT_RESET, CNT_OUT => ROUND_COUNT);
	------------------------------------------------------------------------------
	
		
	-- AES KEYSCHEDULE -----------------------------------------------------------
	Keyschedule : ENTITY work.AES256_Keyschedule
	PORT MAP (
		CLK			=> CLK,
		INIT		=> KEY_INIT,
		ENABLE		=> KEY_ENABLE,
		ROUND		=> ROUND_COUNT,
		KEY			=> KEY,
		ROUND_KEY	=> ROUND_KEY
	);
	------------------------------------------------------------------------------
	
	
	-- AES ROUND FUNCTION --------------------------------------------------------
	AESRound : ENTITY work.AES_Round
	PORT MAP (
		CLK			=> CLK,
		KEY_INIT    => KEY_INIT,
		INIT		=> AES_INIT,
		ENABLE		=> AES_ENABLE,
		RST         => RESET,
		LAST		=> AES_LAST,
		ROUND_KEY	=> ROUND_KEY,
		ROUND_IN	=> IBUFFER,
		ROUND_OUT	=> DATA_OUT
	);
	------------------------------------------------------------------------------
	
	
	-- FINITE STATE MACHINE ------------------------------------------------------
	FSM : ENTITY work.AES_Controller
	PORT MAP (
		CLK			=> CLK,
		-- GLOBAL ----------------------
		DATA_AVAIL	=> DATA_AVAIL,
		DATA_READY	=> DATA_READY,
		-- AES CONTROL PORTS -----------
		AES_INIT	=> AES_INIT,
		AES_ENABLE	=> AES_ENABLE,
		AES_LAST	=> AES_LAST,
		-- KEYSCHEDULE CONTROL PORTS ---
		KEY_INIT	=> KEY_INIT,
		KEY_ENABLE	=> KEY_ENABLE,
		-- ROUND COUNTER ---------------
		CNT_RESET	=> CNT_RESET,
		CNT_ENABLE	=> CNT_ENABLE,
		ROUND_COUNT	=> ROUND_COUNT
	);	
	------------------------------------------------------------------------------

END Structural;

