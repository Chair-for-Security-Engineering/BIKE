----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_ShiftRows
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
ENTITY AES_ShiftRows IS
	PORT ( 
        SR_IN	: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        SR_OUT	: OUT STD_LOGIC_VECTOR (127 DOWNTO 0)
    );
END AES_ShiftRows;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF AES_ShiftRows IS



-- ALIAS
----------------------------------------------------------------------------------
ALIAS IN_0_0  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN(127 DOWNTO 120);
ALIAS IN_1_0  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN(119 DOWNTO 112);
ALIAS IN_2_0  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN(111 DOWNTO 104);
ALIAS IN_3_0  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN(103 DOWNTO  96);
ALIAS IN_0_1  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 95 DOWNTO  88);
ALIAS IN_1_1  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 87 DOWNTO  80);
ALIAS IN_2_1  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 79 DOWNTO  72);
ALIAS IN_3_1  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 71 DOWNTO  64);
ALIAS IN_0_2  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 63 DOWNTO  56);
ALIAS IN_1_2  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 55 DOWNTO  48);
ALIAS IN_2_2  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 47 DOWNTO  40);
ALIAS IN_3_2  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 39 DOWNTO  32);
ALIAS IN_0_3  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 31 DOWNTO  24);
ALIAS IN_1_3  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 23 DOWNTO  16);
ALIAS IN_2_3  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN( 15 DOWNTO   8);
ALIAS IN_3_3  : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_IN(  7 DOWNTO   0);

ALIAS OUT_0_0 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT(127 DOWNTO 120);
ALIAS OUT_1_0 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT(119 DOWNTO 112);
ALIAS OUT_2_0 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT(111 DOWNTO 104);
ALIAS OUT_3_0 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT(103 DOWNTO  96);
ALIAS OUT_0_1 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 95 DOWNTO  88);
ALIAS OUT_1_1 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 87 DOWNTO  80);
ALIAS OUT_2_1 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 79 DOWNTO  72);
ALIAS OUT_3_1 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 71 DOWNTO  64);
ALIAS OUT_0_2 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 63 DOWNTO  56);
ALIAS OUT_1_2 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 55 DOWNTO  48);
ALIAS OUT_2_2 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 47 DOWNTO  40);
ALIAS OUT_3_2 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 39 DOWNTO  32);
ALIAS OUT_0_3 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 31 DOWNTO  24);
ALIAS OUT_1_3 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 23 DOWNTO  16);
ALIAS OUT_2_3 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT( 15 DOWNTO   8);
ALIAS OUT_3_3 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS SR_OUT(  7 DOWNTO   0);



-- DATAFLOW
----------------------------------------------------------------------------------
BEGIN

    -- I/O -----------------------------------------------------------------------

        -- ROW 0 (0 SHIFT LEFT FOR ENC) --------------------
        OUT_0_0 <= IN_0_0;
        OUT_0_1 <= IN_0_1;
        OUT_0_2 <= IN_0_2;
        OUT_0_3 <= IN_0_3;
        --------------------------------------------------------------------------
        
        -- ROW 1 (1 SHIFT LEFT FOR ENC) --------------------
        OUT_1_0 <= IN_1_1;
        OUT_1_1 <= IN_1_2;
        OUT_1_2 <= IN_1_3;
        OUT_1_3 <= IN_1_0;
        --------------------------------------------------------------------------
        
        -- ROW 2 (2 SHIFT LEFT FOR ENC) --------------------
        OUT_2_0 <= IN_2_2;
        OUT_2_1 <= IN_2_3;
        OUT_2_2 <= IN_2_0;
        OUT_2_3 <= IN_2_1;
        --------------------------------------------------------------------------
        
        -- ROW 3 (3 SHIFT LEFT FOR ENC) --------------------
        OUT_3_0 <= IN_3_3;
        OUT_3_1 <= IN_3_0;
        OUT_3_2 <= IN_3_1;
        OUT_3_3 <= IN_3_2;
        --------------------------------------------------------------------------
		
	------------------------------------------------------------------------------

END Dataflow;