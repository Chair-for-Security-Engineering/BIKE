----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2014 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Secure Hardware Group
-- AUTHOR:					Pascal Sasdrich
--
-- CREATE DATA:			    17/4/2014
-- MODULE NAME:			    RegisterFDE
--
-- REVISION:				1.00 - File created
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or	if you have questions regarding the code
--							please contact Tim Güneysu (tim.gueneysu@rub.de) and
--							Pascal Sasdrich (pascal.sasdrich@rub.de)
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

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY RegisterFDE IS
	GENERIC ( SIZE : POSITIVE := 8 );
	PORT ( D   : IN  STD_LOGIC_VECTOR ((SIZE-1) DOWNTO 0);
           Q   : OUT STD_LOGIC_VECTOR ((SIZE-1) DOWNTO 0);
           CLK : IN  STD_LOGIC;
           EN  : IN  STD_LOGIC);
END RegisterFDE;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF RegisterFDE IS



-- SIGNAL
----------------------------------------------------------------------------------
SIGNAL STATE : STD_LOGIC_VECTOR ((SIZE-1) DOWNTO 0) := (OTHERS => '0');


-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

	-- REGISTER INSTANCE ----------------------------------------------------------
	REG : FOR I IN 0 TO (SIZE-1) GENERATE
		FF : FDE
		GENERIC MAP (INIT => '0')
		PORT MAP (
			Q	=> Q(I),
			C	=> CLK,
			CE	=> EN,
			D	=> D(I)
		);		
	END GENERATE;
	-------------------------------------------------------------------------------
	
END Behavioral;

