----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_MixColumns
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
ENTITY AES_MixColumns IS
	PORT ( 
        MC_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        MC_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0)
    );
END AES_MixColumns;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF AES_MixColumns IS



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

	-- INSTANCES ------------------------------------------------------------------
	Column1 : ENTITY work.AES_MixSingleColumn
	PORT MAP (
		COLUMN => MC_IN (127 DOWNTO 96),
		RESULT => MC_OUT(127 DOWNTO 96)
	);
	
	Column2 : ENTITY work.AES_MixSingleColumn
	PORT MAP (
		COLUMN => MC_IN ( 95 DOWNTO 64),
		RESULT => MC_OUT( 95 DOWNTO 64)
	);
	
	Column3 : ENTITY work.AES_MixSingleColumn
	PORT MAP (
		COLUMN => MC_IN ( 63 DOWNTO 32),
		RESULT => MC_OUT( 63 DOWNTO 32)
	);
	
	Column4 : ENTITY work.AES_MixSingleColumn
	PORT MAP (
		COLUMN => MC_IN ( 31 DOWNTO  0),
		RESULT => MC_OUT( 31 DOWNTO  0)
	);
	-------------------------------------------------------------------------------
	
END Structural;