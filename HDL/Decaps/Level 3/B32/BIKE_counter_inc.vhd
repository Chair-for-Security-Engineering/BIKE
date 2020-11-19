----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    15/04/2020
-- LAST CHANGES:            15/04/2020
-- MODULE NAME:			    BIKE_COUNTER_INC
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
    USE IEEE.NUMERIC_STD.ALL;
        


ENTITY BIKE_COUNTER_INC IS
    GENERIC (   
        SIZE        : POSITIVE := 5;
        MAX_VALUE   : INTEGER := 20);
    PORT(       
        CLK         : IN  STD_LOGIC;
        EN          : IN  STD_LOGIC;
        RST         : IN  STD_LOGIC;
        CNT_OUT     : OUT STD_LOGIC_VECTOR((SIZE-1) DOWNTO 0)
    );
END BIKE_COUNTER_INC;



-- ARCHITECTURE ------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_COUNTER_INC IS



-- SIGNALS -----------------------------------------------------------------------
SIGNAL COUNT    : UNSIGNED((SIZE-1) DOWNTO 0) := (OTHERS => '0');
SIGNAL COUNT_IN : UNSIGNED((SIZE-1) DOWNTO 0);



-- BEHAVIORAL --------------------------------------------------------------------
BEGIN

    -- COUNTER PROCESS -----------------------------------------------------------
    COUNT_IN <= (COUNT + 1) WHEN (COUNT < MAX_VALUE) ELSE (OTHERS => '0'); 
    CNT : PROCESS(CLK, RST)
    BEGIN
        IF (RISING_EDGE(CLK)) THEN
            IF (RST = '1') THEN
                COUNT <= (others => '0');
            ELSIF (EN = '1') THEN
                COUNT <= COUNT_IN;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------

    -- COUNTER OUTPUT ------------------------------------------------------------
    CNT_OUT <= STD_LOGIC_VECTOR(COUNT);
    ------------------------------------------------------------------------------
    
END Behavioral;
