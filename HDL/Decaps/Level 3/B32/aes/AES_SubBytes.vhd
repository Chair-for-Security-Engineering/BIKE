----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_SUBBYTES
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
ENTITY AES_SUBBYTES IS
	PORT (   -- DATA PORTS -----------------------------------
             SB_IN		      : IN  STD_LOGIC_VECTOR ( 127 DOWNTO 0);
             SB_OUT		      : OUT STD_LOGIC_VECTOR ( 127 DOWNTO 0));
END AES_SUBBYTES;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF AES_SUBBYTES IS



-- SIGNAL
----------------------------------------------------------------------------------
SIGNAL BUFFERED	: STD_LOGIC_VECTOR (127 DOWNTO 0);



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
		
    -- SUBSTITUTION LAYER ---------------------------------------------------------
	GEN : FOR I IN 0 TO 15 GENERATE
		S : ENTITY work.AES_Sbox
		PORT MAP (
			S_IN		=> SB_IN	((I*8)+7 DOWNTO (I*8)),		
			S_OUT 		=> SB_OUT	((I*8)+7 DOWNTO (I*8))
		);
	END GENERATE;
	
END Structural;
