----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2019 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    09/03/2020
-- LAST CHANGES:            09/03/2020
-- MODULE NAME:			    BIKE_GENERIC_BRAM_SHARED
--
-- REVISION:				1.00 - File created.
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

LIBRARY UNISIM;
    USE UNISIM.vcomponents.ALL;
LIBRARY UNIMACRO;
    USE unimacro.Vcomponents.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_BRAM_SP IS
    GENERIC (
        OUTPUT_BRAM     : NATURAL := 0
    );
	PORT ( 
	   -- CONTROL PORTS ----------------
        CLK             : IN  STD_LOGIC; 	
        RESET           : IN  STD_LOGIC;
        SAMPLING        : IN  STD_LOGIC;
        -- SAMPLING --------------------
        REN_SAMP        : IN  STD_LOGIC;
        WEN_SAMP        : IN  STD_LOGIC;
        ADDR_SAMP       : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        DOUT_SAMP       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN_SAMP        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- COMPUTATION -----------------
        WEN             : IN  STD_LOGIC;
        REN             : IN  STD_LOGIC;
        ADDR            : IN  STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        DOUT            : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        DIN             : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0)
    );
END BIKE_BRAM_SP;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_BRAM_SP IS



-- SIGNALS
----------------------------------------------------------------------------------



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- BRAM ----------------------------------------------------------------------
    BRAM_INST : ENTITY work.BIKE_GENERIC_BRAM
    GENERIC MAP(OUTPUT_BRAM => OUTPUT_BRAM)
    PORT MAP (
        -- CONTROL PORTS ----------------
         CLK            => CLK,     
         RESET          => RESET,
         SAMPLING       => SAMPLING,
         -- SAMPLING --------------------
         WEN_SAMP       => WEN_SAMP,
         REN_SAMP       => REN_SAMP,
         ADDR_SAMP      => ADDR_SAMP,
         DOUT_SAMP      => DOUT_SAMP,
         DIN_SAMP       => DIN_SAMP,
         -- COMPUTATION -----------------
         WEN            => WEN,
         REN            => REN,
         ADDR           => ADDR,
         DOUT           => DOUT,
         DIN            => DIN
    );
    ------------------------------------------------------------------------------ 

END Behavioral;