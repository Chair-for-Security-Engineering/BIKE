----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_KeySchedule
--
-- REVISION:			    2.00 - Adapted to AES256.
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



-- ENTITY
----------------------------------------------------------------------------------
ENTITY AES256_KeySchedule IS
	PORT (
        CLK         : IN  STD_LOGIC;
        INIT		: IN  STD_LOGIC;
        ENABLE	    : IN  STD_LOGIC;
        ROUND	    : IN  STD_LOGIC_VECTOR (  3 DOWNTO 0);
        KEY	  	    : IN  STD_LOGIC_VECTOR (255 DOWNTO 0);
        ROUND_KEY   : OUT STD_LOGIC_VECTOR (127 DOWNTO 0)
    );
END AES256_KeySchedule;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF AES256_KeySchedule IS



-- CONSTANTS
----------------------------------------------------------------------------------
CONSTANT RCONS : STD_LOGIC_VECTOR (111 DOWNTO 0) := X"01020408102040801B366CD8AB4D";



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL STATE, STATE_BUFFERED, CURRENT_KEY, NEXT_KEY, ROUND_KEY_INT	  : STD_LOGIC_VECTOR (255 DOWNTO 0);
SIGNAL SB_IN_G, SB_OUT_G						                      : STD_LOGIC_VECTOR ( 31 DOWNTO 0);
SIGNAL SB_IN_H, SB_OUT_H						                      : STD_LOGIC_VECTOR ( 31 DOWNTO 0);
SIGNAL RCON 										                  : STD_LOGIC_VECTOR (  7 DOWNTO 0);
SIGNAL ENABLE_REG                                                     : STD_LOGIC;



-- ATTRIBUTES
----------------------------------------------------------------------------------
ATTRIBUTE KEEP : STRING;
ATTRIBUTE KEEP OF STATE_BUFFERED : SIGNAL IS "TRUE";



-- DATAFLOW
----------------------------------------------------------------------------------
BEGIN

	-- I/O -----------------------------------------------------------------------
	-- input
	STATE	 	   <= KEY WHEN (INIT = '1') ELSE NEXT_KEY;		
	
	-- output
	ROUND_KEY      <= STATE_BUFFERED(255 DOWNTO 128) WHEN ROUND(0) = '1' ELSE STATE_BUFFERED(127 DOWNTO 0);
	------------------------------------------------------------------------------
	
	
    -- REGISTER ------------------------------------------------------------------
    ENABLE_REG <= ENABLE AND NOT ROUND(0);
    
    RegA : ENTITY work.RegisterFDE
    GENERIC MAP (SIZE => 256)
    PORT MAP (
        D       => STATE,
        Q       => STATE_BUFFERED,
        CLK     => CLK,
        EN      => ENABLE_REG
    );
    
    CURRENT_KEY    <= STATE_BUFFERED;
    ------------------------------------------------------------------------------
    
	
	-- S-BOXES -------------------------------------------------------------------
	SUB_G : FOR I IN 0 TO 3 GENERATE
		SBoxes : ENTITY work.AES_SBox
		PORT MAP (
			S_IN   => SB_IN_G ((I*8)+7 DOWNTO (I*8)),
			S_OUT  => SB_OUT_G((I*8)+7 DOWNTO (I*8))
		);
	END GENERATE;

	SUB_H : FOR I IN 0 TO 3 GENERATE
		SBoxes : ENTITY work.AES_SBox
		PORT MAP (
			S_IN   => SB_IN_H ((I*8)+7 DOWNTO (I*8)),
			S_OUT  => SB_OUT_H((I*8)+7 DOWNTO (I*8))
		);
	END GENERATE;	
	------------------------------------------------------------------------------
	
	
	-- KEY SCHEDULE --------------------------------------------------------------
    WITH ROUND SELECT RCON <=   
        RCONS(111 DOWNTO 104) WHEN X"2",
        RCONS(103 DOWNTO  96) WHEN X"4",
        RCONS( 95 DOWNTO  88) WHEN X"6",
        RCONS( 87 DOWNTO  80) WHEN X"8",
        RCONS( 79 DOWNTO  72) WHEN X"A",
        RCONS( 71 DOWNTO  64) WHEN X"C",
        RCONS( 63 DOWNTO  56) WHEN X"E",
        RCONS(  7 DOWNTO   0) WHEN OTHERS;
					
	SB_IN_G <= CURRENT_KEY(23 DOWNTO 0) & CURRENT_KEY(31 DOWNTO 24);	
	SB_IN_H <= NEXT_KEY(159 DOWNTO 128);
	
	NEXT_KEY(255 DOWNTO 224) <= CURRENT_KEY(255 DOWNTO 224) XOR ((SB_OUT_G(31 DOWNTO 24) XOR RCON) & SB_OUT_G(23 DOWNTO 0));
	NEXT_KEY(223 DOWNTO 192) <= CURRENT_KEY(223 DOWNTO 192) XOR NEXT_KEY(255 DOWNTO 224);
	NEXT_KEY(191 DOWNTO 160) <= CURRENT_KEY(191 DOWNTO 160) XOR NEXT_KEY(223 DOWNTO 192);
	NEXT_KEY(159 DOWNTO 128) <= CURRENT_KEY(159 DOWNTO 128) XOR NEXT_KEY(191 DOWNTO 160);
	
	NEXT_KEY(127 DOWNTO 96) <= CURRENT_KEY(127 DOWNTO 96) XOR SB_OUT_H;
	NEXT_KEY( 95 DOWNTO 64) <= CURRENT_KEY( 95 DOWNTO 64) XOR NEXT_KEY(127 DOWNTO 96);
	NEXT_KEY( 63 DOWNTO 32) <= CURRENT_KEY( 63 DOWNTO 32) XOR NEXT_KEY( 95 DOWNTO 64);
	NEXT_KEY( 31 DOWNTO  0) <= CURRENT_KEY( 31 DOWNTO  0) XOR NEXT_KEY( 63 DOWNTO 32);
	------------------------------------------------------------------------------
	
END Dataflow;