----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       07/04/2020
-- LAST CHANGES:      07/04/2020
-- MODULE NAME:       BIKE_INVERSION_BRAM_ASSIGNMENT
--
-- REVISION:          1.00 - File created.
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

LIBRARY UNISIM;
    USE UNISIM.vcomponents.ALL;
LIBRARY UNIMACRO;
    USE unimacro.Vcomponents.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_INVERSION_BRAM_ASSIGNMENT IS
    GENERIC (
        OUTPUT_SIZE     : INTEGER := B_WIDTH
    );
    PORT (  
        -- INPUTS ----------------------
        SEL_BRAM        : IN  STATES_BRAM_SEL; 
        INPUT0          : IN  STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        INPUT1          : IN  STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        INPUT2          : IN  STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        INPUT3          : IN  STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        INPUT4          : IN  STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        -- OUTPUTS ---------------------
        B0              : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        B1              : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
        B2              : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0)
    );
END BIKE_INVERSION_BRAM_ASSIGNMENT;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_INVERSION_BRAM_ASSIGNMENT IS


-- SIGNALS
----------------------------------------------------------------------------------



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- ASSIGNMENT ----------------------------------------------------------------
    WITH SEL_BRAM SELECT B0 <=
        INPUT0          WHEN S_SQU_2, 
        INPUT1          WHEN S_SQU_1,
        (OTHERS => '0') WHEN S_SQU_0,
        INPUT2          WHEN S_MRV, 
        INPUT2          WHEN S_RMV, 
        INPUT3          WHEN S_VRM,
        INPUT3          WHEN S_RVM,
        INPUT4          WHEN S_MVR,        
        INPUT4          WHEN S_VMR,        
        (OTHERS => '0') WHEN OTHERS; 

    WITH SEL_BRAM SELECT B1 <=
        INPUT0          WHEN S_SQU_0, 
        INPUT1          WHEN S_SQU_2,
        (OTHERS => '0') WHEN S_SQU_1,
        INPUT2          WHEN S_RVM, 
        INPUT2          WHEN S_MVR, 
        INPUT3          WHEN S_VMR,
        INPUT3          WHEN S_RMV,
        INPUT4          WHEN S_MRV,        
        INPUT4          WHEN S_VRM,        
        (OTHERS => '0') WHEN OTHERS; 

    WITH SEL_BRAM SELECT B2 <=
        INPUT0          WHEN S_SQU_1, 
        INPUT1          WHEN S_SQU_0,
        (OTHERS => '0') WHEN S_SQU_2,
        INPUT2          WHEN S_VMR, 
        INPUT2          WHEN S_VRM, 
        INPUT3          WHEN S_MRV,
        INPUT3          WHEN S_MVR,
        INPUT4          WHEN S_RVM,        
        INPUT4          WHEN S_RMV,        
        (OTHERS => '0') WHEN OTHERS;
    ------------------------------------------------------------------------------

END Behavioral;