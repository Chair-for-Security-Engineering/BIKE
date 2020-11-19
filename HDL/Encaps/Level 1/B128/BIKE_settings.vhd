
----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       2020-11-04
-- LAST CHANGES:      2020-11-04
-- MODULE NAME:       BIKE_settings
--
-- REVISION:          1.00 - File was automatically created by a Sage script.
--
-- LICENCE:           Please look at licence.txt
-- USAGE INFORMATION: Please look at readme.txt. If licence.txt or readme.txt
--                    are missing or	if you have questions regarding the code
--                    please contact Tim Güneysu (tim.gueneysu@rub.de) and
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
PACKAGE BIKE_SETTINGS IS

    -- FUNCTIONS -----------------------------------------------------------------
    FUNCTION CEIL (Z : NATURAL; N : POSITIVE) RETURN NATURAL;
    FUNCTION FLOOR (Z : NATURAL; N : POSITIVE) RETURN NATURAL;
    FUNCTION LOG2 (N : POSITIVE) RETURN NATURAL;
    FUNCTION MAX (X : POSITIVE; Y : POSITIVE) RETURN NATURAL; 
    FUNCTION MY_MOD (N : POSITIVE; R : POSITIVE) RETURN NATURAL; 
    ------------------------------------------------------------------------------
    
    -- PARAMETER -----------------------------------------------------------------
    -- BIKE SPECIFIC PARAMETERS
    CONSTANT R_BITS         : POSITIVE;
    CONSTANT T1             : POSITIVE;
    CONSTANT W              : POSITIVE;
    CONSTANT L              : POSITIVE;
    
    -- IMPLEMENTAION PARAMETERS
    CONSTANT N_BITS         : INTEGER;
    CONSTANT B_WIDTH        : INTEGER;
    CONSTANT WORDS          : NATURAL;
    CONSTANT R_BLOCKS       : NATURAL; 
    CONSTANT OVERHANG       : NATURAL;
    CONSTANT BRAM_CAP       : NATURAL;
    ------------------------------------------------------------------------------
    
    -- DEFINITIONS ---------------------------------------------------------------    
    TYPE STATES_BRAM_SEL IS (S_SQU_0, S_SQU_1, S_SQU_2, S_MVR, S_VMR, S_MRV, S_VRM, S_RMV, S_RVM);
    
    TYPE WORD_ARRAY IS ARRAY (INTEGER RANGE<>) OF STD_LOGIC_VECTOR(31 DOWNTO 0); 
    ------------------------------------------------------------------------------

END PACKAGE;



-- PACKAGE BODY
----------------------------------------------------------------------------------
PACKAGE BODY BIKE_SETTINGS IS 

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
    CONSTANT R_BITS         : POSITIVE := 12323;
    CONSTANT T1             : POSITIVE := 134;
    CONSTANT W              : POSITIVE := 142;
    
    CONSTANT L              : POSITIVE := 256;
    
    -- IMPLEMENTAION PARAMETERS
    CONSTANT B_WIDTH        : INTEGER := 128;
    CONSTANT WORDS          : NATURAL := CEIL(R_BITS, B_WIDTH);
    CONSTANT R_BLOCKS       : NATURAL := CEIL(R_BITS, 32); 
    CONSTANT OVERHANG       : NATURAL := R_BITS - B_WIDTH*(WORDS-1);
    CONSTANT N_BITS         : INTEGER := 2*R_BITS;
    CONSTANT BRAM_CAP       : NATURAL := 32768;
    
    
    ------------------------------------------------------------------------------
     
END PACKAGE BODY;
