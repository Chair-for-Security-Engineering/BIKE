
----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       2020-04-22
-- LAST CHANGES:      2020-04-22
-- MODULE NAME:       SHA_settings
--
-- REVISION:          1.00 - File was created.
--
-- LICENCE:           Please look at licence.txt
-- USAGE INFORMATION: Please look at readme.txt. If licence.txt or readme.txt
--                    are missing or	if you have questions regarding the code
--                    please contact Tim Gueneysu (tim.gueneysu@rub.de) and
--                    Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
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
    
    
    
-- PACKAGE
----------------------------------------------------------------------------------
PACKAGE SHA_settings IS

    -- FUNCTIONS -----------------------------------------------------------------
    FUNCTION CEIL (Z : NATURAL; N : POSITIVE) RETURN NATURAL;
    FUNCTION FLOOR (Z : NATURAL; N : POSITIVE) RETURN NATURAL;
    FUNCTION LOG2 (N : POSITIVE) RETURN NATURAL;
    FUNCTION MAX (X : POSITIVE; Y : POSITIVE) RETURN NATURAL; 
    FUNCTION MY_MOD (N : POSITIVE; R : POSITIVE) RETURN NATURAL; 
    ------------------------------------------------------------------------------
    
    -- PARAMETER -----------------------------------------------------------------
    CONSTANT NUM_OF_ROUNDS        : INTEGER;
    ------------------------------------------------------------------------------
    
    -- DEFINITIONS ---------------------------------------------------------------
    type word_array is array (integer range<>) of std_logic_vector(63 downto 0);    
    ------------------------------------------------------------------------------

END PACKAGE;



-- PACKAGE BODY
----------------------------------------------------------------------------------
PACKAGE BODY SHA_settings IS 

    -- CEIL ----------------------------------------------------------------------
    FUNCTION CEIL (Z : NATURAL; N : POSITIVE) RETURN NATURAL IS
        VARIABLE I : NATURAL;
        VARIABLE C : NATURAL;
    BEGIN
        I := Z;
        C := 1;
        WHILE (I > N) LOOP
            I := I - N;
            C := C + 1;
        END LOOP;
        
        RETURN C;
    END FUNCTION;
    ------------------------------------------------------------------------------

    -- FLOOR ---------------------------------------------------------------------
    FUNCTION FLOOR (Z : NATURAL; N : POSITIVE) RETURN NATURAL IS
        VARIABLE I : NATURAL;
        VARIABLE C : NATURAL;
    BEGIN
        I := Z;
        C := 0;
        WHILE (I >= N) LOOP
            I := I - N;
            C := C + 1;
        END LOOP;
        
        RETURN C;
    END FUNCTION;
    ------------------------------------------------------------------------------
        
    -- LOG2 ----------------------------------------------------------------------
    FUNCTION LOG2 (N : POSITIVE) RETURN NATURAL IS
        VARIABLE I : NATURAL;
    BEGIN
        I := 0;  
        WHILE (2**i < N) and I < 31 LOOP
            I := I + 1;
        END LOOP;
        
        RETURN I;
    END FUNCTION;
    ------------------------------------------------------------------------------
    
    -- MAX -----------------------------------------------------------------------
    FUNCTION MAX (X : POSITIVE; Y : POSITIVE) RETURN NATURAL IS
    BEGIN
        IF X >= Y THEN
            RETURN X;
        ELSE
            RETURN Y;
        END IF;
    END FUNCTION;
    ------------------------------------------------------------------------------   

    -- MY MOD --------------------------------------------------------------------
    FUNCTION MY_MOD (N : POSITIVE; R : POSITIVE) RETURN NATURAL IS
        VARIABLE I : NATURAL;
    BEGIN
        I := N;  
        WHILE (I >= R) LOOP
            I := I - R;
        END LOOP;
        
        RETURN I;
    END FUNCTION;
    ------------------------------------------------------------------------------
        
    
    -- SETTINGS ------------------------------------------------------------------
    CONSTANT NUM_OF_ROUNDS         : INTEGER := 80;
    ------------------------------------------------------------------------------
    

     
END PACKAGE BODY;
