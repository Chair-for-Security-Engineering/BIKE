
----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       2020-11-03
-- LAST CHANGES:      2020-11-03
-- MODULE NAME:       BIKE_COMPUTE_THRESHOLD
--
-- REVISION:          1.00 - File was automatically created by a Sage script.
--
-- LICENCE:           Please look at licence.txt
-- USAGE INFORMATION: Please look at readme.txt. If licence.txt or readme.txt
--                    are missing or if you have questions regarding the code
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
    USE IEEE.MATH_REAL.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_COMPUTE_THRESHOLD IS
    PORT(
        CLK     : IN  STD_LOGIC;	
        EN      : IN  STD_LOGIC;   
        S       : IN  STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
        T       : OUT STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0)
    );
END BIKE_COMPUTE_THRESHOLD;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE_COMPUTE_THRESHOLD IS 



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL A            : STD_LOGIC_VECTOR(24 DOWNTO 0);
SIGNAL B            : STD_LOGIC_VECTOR(17 DOWNTO 0);
SIGNAL C            : STD_LOGIC_VECTOR(47 DOWNTO 0);
SIGNAL DOUT         : STD_LOGIC_VECTOR(47 DOWNTO 0);
SIGNAL RES_MULADD   : STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0);



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
    
    -- THRESHOLD -----------------------------------------------------------------
    -- A*B+C
    A <= "0111001000111011100001101";
    B <= (17 DOWNTO LOG2(R_BITS) => '0') & S;
    C <= "000000000000011011000011110101110000101000111101";
    
    MULADD : ENTITY work.BIKE_MUL_ADD
    PORT MAP (
        CLK     => CLK,
        EN      => EN,
        DIN_A   => A,
        DIN_B   => B,
        DIN_C   => C,
        DOUT    => DOUT
    );
    
    RES_MULADD <= DOUT(LOG2(W/2)-1+31 DOWNTO 31);
    
    T <= RES_MULADD WHEN RES_MULADD > STD_LOGIC_VECTOR(TO_UNSIGNED(MAX_C, LOG2(W/2))) ELSE STD_LOGIC_VECTOR(TO_UNSIGNED(MAX_C, LOG2(W/2)));
    ------------------------------------------------------------------------------
    
END Structural;
