----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    23/04/2020
-- LAST CHANGES:            23/04/2020
-- MODULE NAME:			    BIKE_GENERIC_BRAM
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
ENTITY BIKE_GENERIC_BRAM IS
    GENERIC (
        OUTPUT_BRAM     : NATURAL := 0
    );
	PORT ( 
	   -- CONTROL PORTS ----------------
        CLK             : IN  STD_LOGIC; 	
        RESET           : IN  STD_LOGIC;
        SAMPLING        : IN  STD_LOGIC;
        -- SAMPLING --------------------
        WEN_SAMP        : IN  STD_LOGIC;
        REN_SAMP        : IN  STD_LOGIC;
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
END BIKE_GENERIC_BRAM;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_GENERIC_BRAM IS



-- CONSTANTS
----------------------------------------------------------------------------------
CONSTANT NUM_OF_BRAM : NATURAL := MAX(CEIL(R_BITS, BRAM_CAP), CEIL(B_WIDTH, 64));



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL WREN_B               : STD_LOGIC;
SIGNAL RDEN_BRAM            : STD_LOGIC;
SIGNAL WREN_A, WREN_A_PRE   : STD_LOGIC_VECTOR(NUM_OF_BRAM-1 DOWNTO 0);
SIGNAL ADDR_A, ADDR_B       : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL DIN_A, DIN_B         : STD_LOGIC_VECTOR(32*NUM_OF_BRAM-1 DOWNTO 0); 
SIGNAL DIN_PRE_A, DIN_PRE_B : STD_LOGIC_VECTOR(32*NUM_OF_BRAM-1 DOWNTO 0); 
SIGNAL DIN_PRE_A_SAMP       : STD_LOGIC_VECTOR(32*NUM_OF_BRAM-1 DOWNTO 0); 
SIGNAL DOUT_A, DOUT_B       : STD_LOGIC_VECTOR(32*NUM_OF_BRAM-1 DOWNTO 0); 
SIGNAL ADDR_SAMP_D          : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- currently this implementaton just works with the paramter set {B_WIDTH,R} of {32,19853},{32,32794},{64,10163},{64,19853},etc.
    -- the first case {32,10163} needs to be added

    -- SIGNAL ASSIGNMENT ---------------------------------------------------------
    -- write signals
    --IF NUM_OF_BRAM = 1 GENERATE
    --    WEN_A <= '1';
    RDEN_BRAM <= REN_SAMP WHEN SAMPLING = '1' ELSE REN;

   I1: IF NUM_OF_BRAM = 1 GENERATE
        WREN_A_PRE <= (OTHERS => '1');
   END GENERATE I1;
    
   I2: IF NUM_OF_BRAM >= 2 GENERATE
       ONE_HOT_ENCDOING : PROCESS(ADDR_SAMP)
       BEGIN
            FOR W IN 0 TO NUM_OF_BRAM-1 LOOP
                IF ADDR_SAMP(LOG2(NUM_OF_BRAM) DOWNTO 1) = STD_LOGIC_VECTOR( TO_UNSIGNED( W, LOG2(NUM_OF_BRAM))) THEN
                    WREN_A_PRE <= STD_LOGIC_VECTOR(TO_UNSIGNED(2**W, NUM_OF_BRAM));
                END IF; 
            END LOOP;
        END PROCESS;
    END GENERATE I2;

    I1_WREN : IF B_WIDTH = 32 GENERATE
        WREN_A <= WREN_A_PRE AND (NUM_OF_BRAM-1 DOWNTO 0 => WEN_SAMP) WHEN SAMPLING = '1' ELSE (NUM_OF_BRAM-1 DOWNTO 0 => WEN);
        WREN_B <= '0';
    END GENERATE I1_WREN;
    
    I2_WREN : IF B_WIDTH >= 64 GENERATE
        WREN_A <= WREN_A_PRE AND (NUM_OF_BRAM-1 DOWNTO 0 => WEN_SAMP) WHEN SAMPLING = '1' ELSE (NUM_OF_BRAM-1 DOWNTO 0 => WEN);
        WREN_B <= '0' WHEN SAMPLING = '1' ELSE WEN;
    END GENERATE I2_WREN;
    
    
    -- addresses
    I1_ADDR : IF B_WIDTH = 32 GENERATE
        ADDR_A <= (9 DOWNTO LOG2(WORDS) => '0') & ADDR_SAMP WHEN SAMPLING = '1' ELSE (9 DOWNTO LOG2(WORDS) => '0') & ADDR;
        ADDR_B <= (OTHERS => '0');
    END GENERATE I1_ADDR;
    
    I2_ADDR : IF B_WIDTH >= 64 GENERATE
        --ADDR_A <= (9 DOWNTO LOG2(R_BLOCKS)-LOG2(NUM_OF_BRAM)+1 => '0') & (ADDR_SAMP(LOG2(R_BLOCKS)-1 DOWNTO LOG2(NUM_OF_BRAM)+1) & ADDR_SAMP(0)) WHEN SAMPLING = '1' ELSE (9 DOWNTO LOG2(WORDS)+1 => '0') & ADDR & '0';
        ADDR_A <= (9 DOWNTO LOG2(R_BLOCKS)-LOG2(NUM_OF_BRAM) => '0') & (ADDR_SAMP(LOG2(R_BLOCKS)-1 DOWNTO LOG2(NUM_OF_BRAM)+1) & ADDR_SAMP(0)) WHEN SAMPLING = '1' ELSE (9 DOWNTO LOG2(WORDS)+1 => '0') & ADDR & '0';
        ADDR_B <= (OTHERS => '0') WHEN SAMPLING = '1' ELSE (9 DOWNTO LOG2(WORDS)+1 => '0') & ADDR & '1';
    END GENERATE I2_ADDR;
    
    -- inputs
    L_DIN : FOR I IN 0 TO NUM_OF_BRAM-1 GENERATE
        I0: IF B_WIDTH = 32 GENERATE
            DIN_PRE_A <= DIN;
            DIN_PRE_B <= (OTHERS => '0');
        END GENERATE I0;
        
        I1 : IF B_WIDTH >= 64 GENERATE
            DIN_PRE_A((I+1)*32-1 DOWNTO I*32) <= DIN((I+1)*64-32-1 DOWNTO I*64);
            DIN_PRE_B((I+1)*32-1 DOWNTO I*32) <= DIN((I+1)*64-1 DOWNTO I*64+32);
        END GENERATE I1;
        
        DIN_PRE_A_SAMP((I+1)*32-1 DOWNTO I*32) <= DIN_SAMP;
    END GENERATE L_DIN;
        
    --DIN_A <= (32*NUM_OF_BRAM-1 DOWNTO 32 => '0') & DIN_SAMP WHEN SAMPLING = '1' ELSE DIN_PRE_A;
    DIN_A <= DIN_PRE_A_SAMP WHEN SAMPLING = '1' ELSE DIN_PRE_A;
    DIN_B <= DIN_PRE_B;
    
    -- outputs
    OI1: IF NUM_OF_BRAM = 1 GENERATE
         DOUT_SAMP <= DOUT_A(31 DOWNTO 0);
    END GENERATE OI1;
    
    OI2: IF NUM_OF_BRAM >= 2 GENERATE
        OI_OUTPUT : IF OUTPUT_BRAM = 1 GENERATE
            ADDR_SAMP_REG : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => LOG2(R_BLOCKS))
            PORT MAP(D => ADDR_SAMP, Q => ADDR_SAMP_D, CLK => CLK, EN => REN_SAMP, RST => RESET);
            
            PROCESS(ADDR_SAMP_D, DOUT_A)
            BEGIN
                FOR W IN 0 TO NUM_OF_BRAM-1 LOOP
                    --IF TO_INTEGER(UNSIGNED(ADDR_SAMP(NUM_OF_BRAM-1 DOWNTO 1))) = W THEN
                    IF ADDR_SAMP_D(LOG2(NUM_OF_BRAM) DOWNTO 1) = STD_LOGIC_VECTOR( TO_UNSIGNED( W, LOG2(NUM_OF_BRAM))) THEN
                        DOUT_SAMP <= DOUT_A((W+1)*32-1 DOWNTO W*32);
                    END IF; 
                END LOOP;
            END PROCESS;
        END GENERATE OI_OUTPUT;
    
        OI_OUTPUT2 : IF OUTPUT_BRAM = 0 GENERATE
            PROCESS(ADDR_SAMP, DOUT_A)
            BEGIN
                FOR W IN 0 TO NUM_OF_BRAM-1 LOOP
                    --IF TO_INTEGER(UNSIGNED(ADDR_SAMP(NUM_OF_BRAM-1 DOWNTO 1))) = W THEN
                    IF ADDR_SAMP(LOG2(NUM_OF_BRAM) DOWNTO 1) = STD_LOGIC_VECTOR( TO_UNSIGNED( W, LOG2(NUM_OF_BRAM))) THEN
                        DOUT_SAMP <= DOUT_A((W+1)*32-1 DOWNTO W*32);
                    END IF; 
                END LOOP;
            END PROCESS;
        END GENERATE OI_OUTPUT2;        

    END GENERATE OI2;
    
    L_DOUT : FOR I IN 0 TO NUM_OF_BRAM-1 GENERATE
        I0: IF B_WIDTH = 32 GENERATE
            DOUT <= DOUT_A;
        END GENERATE I0;
        
        I1 : IF B_WIDTH >= 64 GENERATE
            DOUT((I+1)*64-32-1 DOWNTO I*64) <= DOUT_A((I+1)*32-1 DOWNTO I*32);
            DOUT((I+1)*64-1 DOWNTO I*64+32) <= DOUT_B((I+1)*32-1 DOWNTO I*32);
        END GENERATE I1;
    END GENERATE L_DOUT;
    ------------------------------------------------------------------------------
    
    
    -- BRAM INSTANTIATION --------------------------------------------------------
    BRAM_LOOP : FOR B IN 0 TO NUM_OF_BRAM-1 GENERATE
        BRAM : ENTITY work.BIKE_BRAM_DUAL_PORT
        PORT MAP(
            -- CONTROL PORTS -----------
            CLK             => CLK,     
            RESET           => RESET,
            WEN_A           => WREN_A(B),
            WEN_B           => WREN_B,
            REN_A           => RDEN_BRAM,
            REN_B           => RDEN_BRAM,
            -- I/O ---------------------
            ADDR_A          => ADDR_A,
            ADDR_B          => ADDR_B,
            DOUT_A          => DOUT_A((B+1)*32-1 DOWNTO B*32),
            DOUT_B          => DOUT_B((B+1)*32-1 DOWNTO B*32),
            DIN_A           => DIN_A((B+1)*32-1 DOWNTO B*32),
            DIN_B           => DIN_B((B+1)*32-1 DOWNTO B*32)
        );
    END GENERATE;
    ------------------------------------------------------------------------------  

END Behavioral;