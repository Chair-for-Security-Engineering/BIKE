----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    23/04/2020
-- LAST CHANGES:            23/04/2020
-- MODULE NAME:			    BIKE_BRAM_SAMP
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
ENTITY BIKE_BRAM_SAMP IS
	PORT ( 
	   -- CONTROL PORTS ----------------
        CLK             : IN  STD_LOGIC; 	
        RESET           : IN  STD_LOGIC;
        -- SAMPLING --------------------
        REN0_SAMP       : IN  STD_LOGIC;
        REN1_SAMP       : IN  STD_LOGIC;
        WEN0_SAMP       : IN  STD_LOGIC;
        WEN1_SAMP       : IN  STD_LOGIC;
        ADDR0_SAMP      : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        ADDR1_SAMP      : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        DOUT0_SAMP      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DOUT1_SAMP      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN0_SAMP       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN1_SAMP       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END BIKE_BRAM_SAMP;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_BRAM_SAMP IS



-- CONSTANTS
----------------------------------------------------------------------------------
CONSTANT NUM_OF_BRAM : NATURAL := CEIL(R_BITS, BRAM_CAP);



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL REN_BRAM, RDEN_SAMP  : STD_LOGIC;
SIGNAL WREN_A, WREN_B       : STD_LOGIC;
SIGNAL ADDR_A, ADDR_B       : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL DIN_A, DIN_B         : STD_LOGIC_VECTOR(31 DOWNTO 0);  
SIGNAL DOUT_A, DOUT_B       : STD_LOGIC_VECTOR(31 DOWNTO 0); 



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- Secret Key ----------------------------------------------------------------
    I0_BRAM : IF R_BITS <= BRAM_CAP/2 GENERATE
        BRAM_SK : ENTITY work.BIKE_GENERIC_BRAM_SHARED_SAMP
        PORT MAP (
            -- CONTROL PORTS ----------------
            CLK             => CLK,     
            RESET           => RESET,
            -- SAMPLING --------------------
            REN0_SAMP       => REN0_SAMP,
            REN1_SAMP       => REN1_SAMP,
            WEN0_SAMP       => WEN0_SAMP,
            WEN1_SAMP       => WEN1_SAMP,
            ADDR0_SAMP      => ADDR0_SAMP,
            ADDR1_SAMP      => ADDR1_SAMP,
            DOUT0_SAMP      => DOUT0_SAMP,
            DOUT1_SAMP      => DOUT1_SAMP,
            DIN0_SAMP       => DIN0_SAMP,
            DIN1_SAMP       => DIN1_SAMP
        );
    END GENERATE I0_BRAM;
    
    I1_BRAM : IF R_BITS > BRAM_CAP/2 GENERATE
        BRAM_SK0 : ENTITY work.BIKE_GENERIC_BRAM_SAMP
        GENERIC MAP(OUTPUT_BRAM => 0)
        PORT MAP (
            -- CONTROL PORTS ----------------
             CLK            => CLK,     
             RESET          => RESET,
             -- SAMPLING --------------------
             WEN_SAMP       => WEN0_SAMP,
             REN_SAMP       => REN0_SAMP,
             ADDR_SAMP      => ADDR0_SAMP,
             DOUT_SAMP      => DOUT0_SAMP,
             DIN_SAMP       => DIN0_SAMP
        );

        BRAM_SK1 : ENTITY work.BIKE_GENERIC_BRAM_SAMP
        GENERIC MAP(OUTPUT_BRAM => 0)
        PORT MAP (
            -- CONTROL PORTS ----------------
             CLK            => CLK,     
             RESET          => RESET,
             -- SAMPLING --------------------
             WEN_SAMP       => WEN1_SAMP,
             REN_SAMP       => REN1_SAMP,
             ADDR_SAMP      => ADDR1_SAMP,
             DOUT_SAMP      => DOUT1_SAMP,
             DIN_SAMP       => DIN1_SAMP
        );
    END GENERATE I1_BRAM;
    ------------------------------------------------------------------------------ 

END Behavioral;