----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_ROUND
--
-- REVISION:				1.00 - File created
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or	if you have questions regarding the code
--							please contact Tim Gueneysu (tim.gueneysu@rub.de) and
--							Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
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
ENTITY AES_Round IS
	PORT (   
        CLK         : IN  STD_LOGIC;
        -- CONTROL PORTS --------------------------------	
        KEY_INIT    : IN  STD_LOGIC;
        INIT        : IN  STD_LOGIC;
        ENABLE      : IN  STD_LOGIC;
        RST         : IN  STD_LOGIC;
        LAST		: IN  STD_LOGIC;
        -- DATA PORTS -----------------------------------
        ROUND_KEY	: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        ROUND_IN	: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        ROUND_OUT	: OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
END AES_Round;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF AES_Round IS



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL STATE, NEXT_STATE, KEY_ADD, SB_IN, SB_OUT, SR_IN, SR_OUT, MC_IN, MC_OUT	: STD_LOGIC_VECTOR (127 DOWNTO 0);



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

	-- MULTIPLEXER (INPUT) -------------------------------------------------------
	STATE      <= SB_IN WHEN (INIT = '1') ELSE NEXT_STATE;	

	-- KEY ADDITION (KA) ---------------------------------------------------------
	KEY_ADD	   <= ROUND_IN WHEN KEY_INIT = '1' ELSE STATE XOR ROUND_KEY;
	
	-- SUBBYTES REGISTER ---------------------------------------------------------
    AESSB_BUFFER : ENTITY work.RegisterFDRE GENERIC MAP (SIZE => 128)
    PORT MAP (D => KEY_ADD, Q => SB_IN, CLK => CLK, EN => ENABLE, RST => RST);
    
	-- SUB BYTES (SB) ------------------------------------------------------------
	SB : ENTITY work.AES_SUBBYTES
	PORT MAP (
		SB_IN		=> SB_IN,
		SB_OUT		=> SB_OUT
	);
	
	SR_IN <= SB_OUT;
	
	-- SHIFT ROWS (SR) -----------------------------------------------------------
	SR : ENTITY work.AES_ShiftRows
	PORT MAP (
		SR_IN		=> SR_IN,
		SR_OUT	    => SR_OUT
	);	
    
    MC_IN <= SR_OUT;
	
	-- MIX COLUMNS (MC) ----------------------------------------------------------
	MC : ENTITY work.AES_MixColumns
	PORT MAP (
		MC_IN		=> MC_IN,
		MC_OUT	    => MC_OUT
	);	
	
	-- MULTIPLEXER (LAST ROUND) --------------------------------------------------
	NEXT_STATE	<= MC_IN WHEN (LAST = '1') ELSE MC_OUT;	
	
	-- OUTPUT --------------------------------------------------------------------
	ROUND_OUT	<= SB_IN;
	
END Structural;

