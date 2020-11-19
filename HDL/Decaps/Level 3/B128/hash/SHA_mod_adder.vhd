----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    26/04/2020
-- LAST CHANGES:            26/04/2020
-- MODULE NAME:			    SHA_MOD_ADDER
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
        


ENTITY SHA_MOD_ADDER IS
    GENERIC (   
        SIZE        : POSITIVE := 5
    );
    PORT(       
        DINA        : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
        DINB        : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
        DOUT        : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0)
    );
END SHA_MOD_ADDER;



-- ARCHITECTURE ------------------------------------------------------------------
ARCHITECTURE Behavioral OF SHA_MOD_ADDER IS



-- SIGNALS -----------------------------------------------------------------------
SIGNAL CARRY        : STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);

SIGNAL A, B, C      : STD_LOGIC_VECTOR(SIZE DOWNTO 0);



-- BEHAVIORAL --------------------------------------------------------------------
BEGIN

    -- ADDER ---------------------------------------------------------------------
--    HALF : ENTITY work.HALF_ADDER PORT MAP (A => DINA(0), B => DINB(0), C => CARRY(0), S => DOUT(0));
    
--    LOOP_FULL : FOR I IN 1 TO SIZE-1 GENERATE
--        FULL : ENTITY work.FULL_ADDER PORT MAP (A => DINA(I), B => DINB(I), CIN => CARRY(I-1), S => DOUT(I), C => CARRY(I));
--    END GENERATE;
    
    -- this is more efficient than using a CRA
    -- consumes less area and achieves better timing
    A <= '0' & DINA;
    B <= '0' & DINB;
    C <= STD_LOGIC_VECTOR(UNSIGNED(A) + UNSIGNED(B));
    DOUT <= C(63 DOWNTO 0);
    ------------------------------------------------------------------------------
    
END Behavioral;
