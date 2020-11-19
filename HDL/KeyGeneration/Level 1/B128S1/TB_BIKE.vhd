----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2019 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    05/03/2019
-- LAST CHANGES:            05/03/2019
-- MODULE NAME:			    TB_BIKE
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

    USE STD.textio.ALL;
    USE IEEE.STD_LOGIC_TEXTIO.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY TB_BIKE IS
END TB_BIKE;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF TB_BIKE IS

    -- COMPONENTS ----------------------------------------------------------------
    COMPONENT BIKE IS
    PORT (  
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------    
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        KEYGEN_DONE     : OUT STD_LOGIC;
        -- RANDOMNESS-------------------
        SK0_RAND        : IN  STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0);
        SK1_RAND        : IN  STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0); 
        SIGMA_RAND      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        --SIGMA1_RAND     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);  
        -- OUTPUT ----------------------
        PK_OUT          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)   
    );
    END COMPONENT;

    -- INPUTS --------------------------------------------------------------------
    SIGNAL CLK                          : STD_LOGIC := '0';
    SIGNAL RESET                        : STD_LOGIC := '1';
    SIGNAL ENABLE                       : STD_LOGIC := '0';
    
    SIGNAL SK0_RAND                     : STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK1_RAND                     : STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SIGMA_RAND                   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL SIGMA0_RAND                  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL SIGMA1_RAND                  : STD_LOGIC_VECTOR(31 DOWNTO 0); 
    
    -- OUTPUTS -------------------------------------------------------------------
    SIGNAL KEYGEN_DONE                  : STD_LOGIC;
    
    SIGNAL PK_OUT                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- CLOCK PERIOD DEFINITION ---------------------------------------------------
    CONSTANT CLK_PERIOD  : TIME := 10 NS;



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

    -- UNIT UNDER TEST -----------------------------------------------------------
    UUT : BIKE
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS ---------------
        RESET           => RESET,
        ENABLE          => ENABLE,
        KEYGEN_DONE     => KEYGEN_DONE,
        --ENCAPS_DONE     => ENCAPS_DONE,
        -- RANDOMNESS-------------------
        SK0_RAND        => SK0_RAND,
        SK1_RAND        => SK1_RAND,
        SIGMA_RAND      => SIGMA_RAND,
        --SIGMA0_RAND     => SIGMA0_RAND,
        --SIGMA1_RAND     => SIGMA1_RAND,
        -- OUTPUT ----------------------
        PK_OUT          => PK_OUT   
    );
    ------------------------------------------------------------------------------  
        
    -- CLOCK PROCESS DEFINITION --------------------------------------------------
    CLK_PROCESS : PROCESS
    BEGIN
        CLK <= '1'; WAIT FOR CLK_PERIOD/2;
        CLK <= '0'; WAIT FOR CLK_PERIOD/2;
    END PROCESS;
    ------------------------------------------------------------------------------
    
    -- STIMULUS PROCESS ----------------------------------------------------------
    STIM_PROCESS : PROCESS
        -- INPUT FILES -----------------------------------------------------------
        FILE FILE_SK0           : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\00 - Key Generation\Level 1\D128S1\hdl\tv\sk0.txt";
        FILE FILE_SK1           : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\00 - Key Generation\Level 1\D128S1\hdl\tv\sk1.txt";
        FILE FILE_SIGMA0        : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\00 - Key Generation\Level 1\D128S1\hdl\tv\sigma.txt";
        VARIABLE V_ILINE_SK0    : LINE;
        VARIABLE V_ILINE_SK1    : LINE;
        VARIABLE V_ILINE_SIGMA0 : LINE;
        VARIABLE V_SK0          : STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1  DOWNTO 0);
        VARIABLE V_SK1          : STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1  DOWNTO 0);
        VARIABLE V_SIGMA0       : STD_LOGIC_VECTOR(31  DOWNTO 0);
        VARIABLE TRIGGER_SK0    : STD_LOGIC := '0';
        VARIABLE TRIGGER_SK1    : STD_LOGIC := '0';
        VARIABLE TRIGGER        : STD_LOGIC := '0';
        VARIABLE WAIT_SIGMA     : STD_LOGIC := '1';
        VARIABLE END_OF_SK      : STD_LOGIC := '1';
        -- TV OUTPUT
        FILE FILE_PK0            : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\00 - Key Generation\Level 1\D128S1\hdl\tv\pk.txt";
        VARIABLE V_ILINE_PK0     : LINE;
        VARIABLE V_PK0           : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE CORRECT_PK0     : STD_LOGIC := '1';
    BEGIN          
        -- HOLD RESET ------------------
        WAIT FOR 100 NS;
        SIGMA_RAND <= (OTHERS => '0');
        SIGMA0_RAND <= (OTHERS => '0');
        SIGMA1_RAND <= (OTHERS => '0');
        
        -- STIMULUS --------------------
        RESET           <= '0';
        
        --------------------------------
        WAIT FOR CLK_PERIOD;
        
        ENABLE          <= '1';
        
        WAIT FOR 2*CLK_PERIOD;
        --------------------------------
        --------------------------------
        WHILE END_OF_SK = '1' OR (NOT endfile(FILE_SIGMA0)) LOOP
            IF WAIT_SIGMA = '1' THEN
                WAIT_SIGMA := '0'; -- we have to wait one clock cycle until the sampler is ready to process any data
            ELSE
                -- SIGMA0 ------------------
                IF (NOT endfile(FILE_SIGMA0)) THEN
                    readline(FILE_SIGMA0, V_ILINE_SIGMA0);
                    hread(V_ILINE_SIGMA0, V_SIGMA0);
                    
                    SIGMA_RAND <= V_SIGMA0;
                END IF;
                ----------------------------

            END IF;
                    
            -- SK0 ---------------------
            IF (NOT endfile(FILE_SK0)) OR TRIGGER_SK0 = '1' THEN
                IF TRIGGER_SK0 = '0' THEN
                    readline(FILE_SK0, V_ILINE_SK0);
                    read(V_ILINE_SK0, V_SK0);
                    
                    SK0_RAND  <= V_SK0;
                    
                    TRIGGER_SK0 := '1';
                ELSE
                    TRIGGER_SK0 := '0';
                END IF;
            ELSE
                SK0_RAND <= (OTHERS => '0');
            END IF;   
            ----------------------------
            
            -- SK1 ---------------------
            IF (NOT endfile(FILE_SK1)) OR TRIGGER_SK1 = '1' THEN
                IF TRIGGER_SK1 = '0' THEN
                    readline(FILE_SK1, V_ILINE_SK1);
                    read(V_ILINE_SK1, V_SK1);
                    
                    SK1_RAND  <= V_SK1;
                    
                    TRIGGER_SK1 := '1';
                ELSE
                    TRIGGER_SK1 := '0';
                END IF;
            ELSE
                SK1_RAND <= (OTHERS => '0');
            END IF; 
            ----------------------------  
            
            IF endfile(FILE_SK0) AND endfile(FILE_SK1) THEN
                END_OF_SK := '0';
            END IF;
            
            WAIT FOR CLK_PERIOD;
        END LOOP;
        --------------------------------
                                
        -- VERIFY PUBLIC KEY -----------
        WAIT UNTIL KEYGEN_DONE = '1';
        
        WAIT FOR CLK_PERIOD;

        WHILE NOT endfile(FILE_PK0) LOOP
            readline(FILE_PK0, V_ILINE_PK0);
            hread(V_ILINE_PK0, V_PK0);
            
            IF PK_OUT /= V_PK0 THEN
                CORRECT_PK0 := '0';
            END IF;
                                    
            WAIT FOR CLK_PERIOD;
        END LOOP;
        -------------------------------- 
        
        -- CHECK C ---------------------
        IF (CORRECT_PK0 = '1') THEN
            report("PUBLIC KEY CORRECT!");
        ELSE
            report("PUBLIC KEY WRONG!");
        END IF;
        -------------------------------
        
        --------------------------------
        ENABLE          <= '0';
         
        file_close(FILE_PK0);
        --------------------------------
                
        WAIT;        
    END PROCESS;
    ------------------------------------------------------------------------------ 

END Structural;
