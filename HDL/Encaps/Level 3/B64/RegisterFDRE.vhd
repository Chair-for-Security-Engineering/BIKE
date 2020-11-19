----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2019 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    27/02/2019
-- LAST CHANGES:            27/02/2019
-- MODULE NAME:			    RegisterFDRE
--
-- REVISION:				1.00 - Created file.
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

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY RegisterFDRE IS
    GENERIC ( 
        SIZE : POSITIVE := 8 
    );
    PORT ( 
        D   : IN  STD_LOGIC_VECTOR ((SIZE-1) DOWNTO 0);
        Q   : OUT STD_LOGIC_VECTOR ((SIZE-1) DOWNTO 0);
        CLK : IN  STD_LOGIC;
        EN  : IN  STD_LOGIC;
        RST : IN  STD_LOGIC
    );
END RegisterFDRE;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF RegisterFDRE IS



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

	-- REGISTER INSTANCE ----------------------------------------------------------
	REG : FOR I IN 0 TO (SIZE-1) GENERATE
		FF : FDRE
		GENERIC MAP (INIT => '0')
		PORT MAP (
			Q	=> Q(I),
			C	=> CLK,
			CE	=> EN,
			R	=> RST,
			D	=> D(I)
		);		
	END GENERATE;
	-------------------------------------------------------------------------------

END Behavioral;

