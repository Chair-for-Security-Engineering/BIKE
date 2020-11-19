----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
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
        ENCAPS_DONE     : OUT STD_LOGIC;
        -- RANDOMNESS-------------------   
        M_RAND          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);       
        -- PUBLIC KEY ------------------
        PK_IN_DIN       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        PK_IN_ADDR      : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        PK_IN_VALID     : IN  STD_LOGIC; 
        -- OUTPUT ----------------------
        K_VALID         : OUT STD_LOGIC;
        K_OUT           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        C_OUT           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)  
    );
    END COMPONENT;

    -- INPUTS --------------------------------------------------------------------
    SIGNAL CLK                          : STD_LOGIC := '0';
    SIGNAL RESET                        : STD_LOGIC := '1';
    SIGNAL ENABLE                       : STD_LOGIC := '0';
    
    SIGNAL M_RAND                       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL PK_IN_DIN                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL PK_IN_ADDR                   : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
    SIGNAL PK_IN_VALID                  : STD_LOGIC; 
    
    -- OUTPUTS -------------------------------------------------------------------
    SIGNAL ENCAPS_DONE                  : STD_LOGIC;
    
    SIGNAL K_VALID                      : STD_LOGIC;
    SIGNAL K_OUT                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL C_OUT                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
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
        ENCAPS_DONE     => ENCAPS_DONE,
        -- RANDOMNESS-------------------
        M_RAND          => M_RAND,
        -- PUBLIC KEY ------------------
        PK_IN_DIN       => PK_IN_DIN,
        PK_IN_ADDR      => PK_IN_ADDR,
        PK_IN_VALID     => PK_IN_VALID, 
        -- OUTPUT ----------------------
        K_VALID         => K_VALID,
        K_OUT           => K_OUT,
        C_OUT           => C_OUT  
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
        FILE FILE_M             : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\01 - Encapsulation\Level 3\D32\hdl\tv\m.txt";
        FILE FILE_PK            : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\01 - Encapsulation\Level 3\D32\hdl\tv\pk.txt";
        VARIABLE V_ILINE_M      : LINE;
        VARIABLE V_ILINE_PK     : LINE;
        VARIABLE V_M            : STD_LOGIC_VECTOR(31 downto 0);
        VARIABLE V_PK           : STD_LOGIC_VECTOR(31  downto 0);
        VARIABLE TRIGGER        : STD_LOGIC := '0';
        VARIABLE PK_ADDR        : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
        -- TV OUTPUT
        FILE FILE_HASH          : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\01 - Encapsulation\Level 3\D32\hdl\tv\k.txt";
        FILE FILE_C             : TEXT open READ_MODE is "C:\Users\Jan\NextcloudSecEng\10 - Research\02 - BIKE\01 - VHDL\30 - Paper\01 - Encapsulation\Level 3\D32\hdl\tv\c.txt";
        VARIABLE V_ILINE_HASH   : LINE;
        VARIABLE V_ILINE_C      : LINE;
        VARIABLE V_HASH         : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE V_C            : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE CORRECT_HASH   : STD_LOGIC := '1';
        VARIABLE CORRECT_C      : STD_LOGIC := '1';
    BEGIN          
        -- HOLD RESET ------------------
        WAIT FOR 100 NS;
        
        
        -- STIMULUS --------------------
        RESET           <= '0';
        PK_IN_VALID     <= '0';
        PK_IN_DIN       <= (OTHERS => '0');
        PK_IN_ADDR      <= (OTHERS => '0');
        
        WAIT FOR 4*CLK_PERIOD;
        --------------------------------
        
        
        -- INPUT PUBPLIC KEY -----------
        PK_IN_VALID <= '1';
        
        WHILE NOT endfile(FILE_PK) LOOP
            readline(FILE_PK, V_ILINE_PK);
            hread(V_ILINE_PK, V_PK);
            
            PK_IN_DIN   <= V_PK;
            PK_IN_ADDR  <= PK_ADDR;
            
            PK_ADDR := STD_LOGIC_VECTOR(UNSIGNED(PK_ADDR) + 1);
                        
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        PK_IN_VALID     <= '0';
        PK_IN_DIN       <= (OTHERS => '0');
        PK_IN_ADDR      <= (OTHERS => '0');
        
        WAIT FOR 4*CLK_PERIOD;
        
        file_close(FILE_PK);
        --------------------------------
        
        
        --------------------------------
        ENABLE          <= '1';
        
        WAIT FOR 3*CLK_PERIOD;
        --------------------------------
            
            
        -- MESSAGE -----------------
        WHILE NOT endfile(FILE_M) LOOP
            readline(FILE_M, V_ILINE_M);
            hread(V_ILINE_M, V_M);
            
            M_RAND <= V_M; 
            
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        file_close(FILE_M);
        ----------------------------           

        
        -- VERIFY HASH -----------------
        WAIT UNTIL K_VALID = '1';
        
        WAIT FOR CLK_PERIOD;

        WHILE NOT endfile(FILE_HASH) LOOP
            readline(FILE_HASH, V_ILINE_HASH);
            hread(V_ILINE_HASH, V_HASH);
            
            IF K_OUT /= V_HASH THEN
                CORRECT_HASH := '0';
            END IF;
                        
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        file_close(FILE_HASH); 
        --------------------------------
        
        -- CHECK HASH ------------------
        IF (CORRECT_HASH = '1') THEN
            report("KEY CORRECT!");
        ELSE
            report("KEY WRONG!");
        END IF;
        --------------------------------
                                
        -- VERIFY C --------------------
        WAIT UNTIL ENCAPS_DONE = '1';
        
        WAIT FOR CLK_PERIOD;

        WHILE NOT endfile(FILE_C) LOOP
            readline(FILE_C, V_ILINE_C);
            hread(V_ILINE_C, V_C);
            
            IF C_OUT /= V_C THEN
                CORRECT_C := '0';
            END IF;
                     
            WAIT FOR CLK_PERIOD;
        END LOOP;
        -------------------------------- 
        
        -- CHECK C ---------------------
        IF (CORRECT_C = '1')THEN
            report("CRYPTOGRAM CORRECT!");
        ELSE
            report("CRYPTOGRAM WRONG!");
        END IF;
        -------------------------------
        
        --------------------------------
        ENABLE          <= '0';
         
        file_close(FILE_C);
        --------------------------------
                
        WAIT;        
    END PROCESS;
    ------------------------------------------------------------------------------ 

END Structural;
