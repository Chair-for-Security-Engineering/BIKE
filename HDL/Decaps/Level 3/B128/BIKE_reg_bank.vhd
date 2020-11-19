----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    BIKE_REG_BANK
--
-- REVISION:				1.00 - File created.
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

LIBRARY UNISIM;
    USE UNISIM.vcomponents.ALL;
LIBRARY UNIMACRO;
    USE unimacro.Vcomponents.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_REG_BANK IS
    GENERIC (
        SIZE    : POSITIVE := 8
    );
    PORT (
        CLK     : IN  STD_LOGIC;
        RST     : IN  STD_LOGIC;        
        EN      : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
        DIN     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        DOUT    : OUT WORD_ARRAY(SIZE-1 DOWNTO 0)
    );
END BIKE_REG_BANK;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_REG_BANK IS



-- SIGNALS
----------------------------------------------------------------------------------




-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- REGISTER BANK -------------------------------------------------------------
    REG_C1 : FOR I IN 0 TO SIZE-1 GENERATE
        ATTRIBUTE DONT_TOUCH : STRING;
        ATTRIBUTE DONT_TOUCH OF REG : LABEL IS "TRUE";
    BEGIN
        REG : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => 32)
        PORT MAP(D => DIN, Q => DOUT(I), CLK => CLK, EN => EN(I), RST => RST);
    END GENERATE;  
    ------------------------------------------------------------------------------ 

END Behavioral;