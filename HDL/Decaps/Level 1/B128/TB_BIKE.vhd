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
        CLK                     : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------    
        RESET                   : IN  STD_LOGIC;
        ENABLE                  : IN  STD_LOGIC;
        DECAPS_DONE             : OUT STD_LOGIC;
        -- CRYPTOGRAM ------------------
        C_IN_DIN                : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        C_IN_ADDR               : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        C0_IN_VALID             : IN  STD_LOGIC;
        C1_IN_VALID             : IN  STD_LOGIC;
        -- SECRET KEY ------------------
        SK0_IN_DIN              : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        SK1_IN_DIN              : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        SK_IN_ADDR              : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        SK_IN_VALID             : IN  STD_LOGIC;
        SK0_COMPACT_IN_DIN      : IN  STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
        SK1_COMPACT_IN_DIN      : IN  STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
        SK_COMPACT_IN_ADDR      : IN  STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        SK_COMPACT_IN_VALID     : IN  STD_LOGIC;
        SIGMA_IN_DIN            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGMA_IN_ADDR           : IN  STD_LOGIC_VECTOR(LOG2(CEIL(L, 32))-1 DOWNTO 0);
        SIGMA_IN_VALID          : IN  STD_LOGIC;
        -- OUTPUT ----------------------
        K_VALID                 : OUT STD_LOGIC;
        K_OUT                   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;

    -- INPUTS --------------------------------------------------------------------
    SIGNAL CLK                          : STD_LOGIC := '0';
    SIGNAL RESET                        : STD_LOGIC := '1';
    SIGNAL ENABLE                       : STD_LOGIC := '0';

    SIGNAL C_IN_DIN                     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL C_IN_ADDR                    : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL C0_IN_VALID                  : STD_LOGIC := '0'; 
    SIGNAL C1_IN_VALID                  : STD_LOGIC := '0'; 
    
    SIGNAL ERROR_RAND                   : STD_LOGIC_VECTOR(LOG2(2*R_BITS+1)-1 DOWNTO 0) := (OTHERS => '0');
        
    SIGNAL SK0_IN_DIN                   : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK1_IN_DIN                   : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK_IN_ADDR                   : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK_IN_VALID                  : STD_LOGIC := '0'; 
    
    SIGNAL SK0_COMPACT_IN_DIN           : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK1_COMPACT_IN_DIN           : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK_COMPACT_IN_ADDR           : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SK_COMPACT_IN_VALID          : STD_LOGIC := '0';

    SIGNAL SIGMA_IN_DIN                 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SIGMA_IN_ADDR                : STD_LOGIC_VECTOR(LOG2(CEIL(L, 32))-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SIGMA_IN_VALID               : STD_LOGIC := '0';

    
    -- OUTPUTS -------------------------------------------------------------------
    SIGNAL DECAPS_DONE                  : STD_LOGIC;
    
    SIGNAL K_VALID                      : STD_LOGIC;
    SIGNAL K_OUT                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- CLOCK PERIOD DEFINITION ---------------------------------------------------
    CONSTANT CLK_PERIOD  : TIME := 10 NS;



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN

    -- UNIT UNDER TEST -----------------------------------------------------------
    UUT : BIKE
    PORT MAP (
        CLK                     => CLK,
        -- CONTROL PORTS ---------------
        RESET                   => RESET,
        ENABLE                  => ENABLE,
        DECAPS_DONE             => DECAPS_DONE,
        -- CRYPTOGRAM ------------------
        C_IN_DIN                => C_IN_DIN,
        C_IN_ADDR               => C_IN_ADDR,
        C0_IN_VALID             => C0_IN_VALID,
        C1_IN_VALID             => C1_IN_VALID,
        -- SECRET KEY ------------------
        SK0_IN_DIN              => SK0_IN_DIN,
        SK1_IN_DIN              => SK1_IN_DIN,
        SK_IN_ADDR              => SK_IN_ADDR,
        SK_IN_VALID             => SK_IN_VALID,
        SK0_COMPACT_IN_DIN      => SK0_COMPACT_IN_DIN, 
        SK1_COMPACT_IN_DIN      => SK1_COMPACT_IN_DIN,
        SK_COMPACT_IN_ADDR      => SK_COMPACT_IN_ADDR,
        SK_COMPACT_IN_VALID     => SK_COMPACT_IN_VALID,
        SIGMA_IN_DIN            => SIGMA_IN_DIN,
        SIGMA_IN_ADDR           => SIGMA_IN_ADDR,
        SIGMA_IN_VALID          => SIGMA_IN_VALID,
        -- OUTPUT ----------------------
        K_VALID                 => K_VALID,
        K_OUT                   => K_OUT 
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
        FILE FILE_SK0                   : TEXT open READ_MODE is "path_to_project\hdl\tv\sk0.txt";
        FILE FILE_SK1                   : TEXT open READ_MODE is "path_to_project\hdl\tv\sk1.txt";
        FILE FILE_SK0_COMPACT           : TEXT open READ_MODE is "path_to_project\hdl\tv\sk0_compact.txt";
        FILE FILE_SK1_COMPACT           : TEXT open READ_MODE is "path_to_project\hdl\tv\sk1_compact.txt";
        FILE FILE_SIGMA                 : TEXT open READ_MODE is "path_to_project\hdl\tv\sigma.txt";
        FILE FILE_C                     : TEXT open READ_MODE is "path_to_project\hdl\tv\c.txt";
        VARIABLE V_ILINE_SK0            : LINE;
        VARIABLE V_ILINE_SK1            : LINE;
        VARIABLE V_ILINE_SK0_COMPACT    : LINE;
        VARIABLE V_ILINE_SK1_COMPACT    : LINE;
        VARIABLE V_ILINE_SIGMA          : LINE;
        VARIABLE V_ILINE_C              : LINE;
        VARIABLE V_SK0                  : STD_LOGIC_VECTOR(31 downto 0);
        VARIABLE V_SK1                  : STD_LOGIC_VECTOR(31 downto 0);
        VARIABLE V_SK0_COMPACT          : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 downto 0);
        VARIABLE V_SK1_COMPACT          : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 downto 0);
        VARIABLE V_SIGMA                : STD_LOGIC_VECTOR(31 downto 0);
        VARIABLE V_C                    : STD_LOGIC_VECTOR(31 downto 0);
        VARIABLE C_TRIGGER              : STD_LOGIC := '0';
        VARIABLE E_TRIGGER              : STD_LOGIC := '0';
        VARIABLE SK_ADDR                : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
        VARIABLE SK_COMPACT_ADDR        : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
        VARIABLE SIGMA_ADDR             : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0) := (OTHERS => '0');
        VARIABLE C_ADDR                 : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0) := (OTHERS => '0');
        -- TV OUTPUT
        FILE FILE_HASH                  : TEXT open READ_MODE is "path_to_project\hdl\tv\k.txt";
        VARIABLE V_ILINE_HASH           : LINE;
        VARIABLE V_HASH                 : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE CORRECT_HASH           : STD_LOGIC := '1';
        VARIABLE CORRECT_C              : STD_LOGIC := '1';
    BEGIN          
        -- HOLD RESET ------------------
        WAIT FOR 100 NS;
        
        
        -- STIMULUS --------------------
        RESET           <= '0';
        
        SK_IN_VALID     <= '0';
        SK0_IN_DIN      <= (OTHERS => '0');
        SK1_IN_DIN      <= (OTHERS => '0');
        SK_IN_ADDR      <= (OTHERS => '0');

        C0_IN_VALID     <= '0';
        C1_IN_VALID     <= '0';
        C_IN_DIN        <= (OTHERS => '0');
        C_IN_ADDR       <= (OTHERS => '0');
                
        WAIT FOR 4*CLK_PERIOD;
        --------------------------------
        
        
        -- INPUT SECRET KEY ------------
        SK_IN_VALID <= '1';
        
        WHILE NOT endfile(FILE_SK0) LOOP
            readline(FILE_SK0, V_ILINE_SK0);
            hread(V_ILINE_SK0, V_SK0);

            readline(FILE_SK1, V_ILINE_SK1);
            hread(V_ILINE_SK1, V_SK1);
                        
            SK0_IN_DIN  <= V_SK0;
            SK1_IN_DIN  <= V_SK1;
            
            SK_IN_ADDR  <= SK_ADDR;
            
            SK_ADDR := STD_LOGIC_VECTOR(UNSIGNED(SK_ADDR) + 1);
                        
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        SK_IN_VALID     <= '0';
        SK0_IN_DIN      <= (OTHERS => '0');
        SK1_IN_DIN      <= (OTHERS => '0');
        SK_IN_ADDR      <= (OTHERS => '0');
        
        WAIT FOR 4*CLK_PERIOD;
        
        file_close(FILE_SK0);
        
        -- SK compact
        SK_COMPACT_IN_VALID <= '1';
        
        WHILE NOT endfile(FILE_SK0_COMPACT) LOOP
            readline(FILE_SK0_COMPACT, V_ILINE_SK0_COMPACT);
            read(V_ILINE_SK0_COMPACT, V_SK0_COMPACT);

            readline(FILE_SK1_COMPACT, V_ILINE_SK1_COMPACT);
            read(V_ILINE_SK1_COMPACT, V_SK1_COMPACT);
                        
            SK0_COMPACT_IN_DIN  <= V_SK0_COMPACT;
            SK1_COMPACT_IN_DIN  <= V_SK1_COMPACT;
            
            SK_COMPACT_IN_ADDR  <= SK_COMPACT_ADDR;
            
            SK_COMPACT_ADDR := STD_LOGIC_VECTOR(UNSIGNED(SK_COMPACT_ADDR) + 1);
                        
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        SK_COMPACT_IN_VALID     <= '0';
        SK0_COMPACT_IN_DIN      <= (OTHERS => '0');
        SK1_COMPACT_IN_DIN      <= (OTHERS => '0');
        SK_COMPACT_IN_ADDR      <= (OTHERS => '0');
        
        WAIT FOR 4*CLK_PERIOD;
        
        file_close(FILE_SK0_COMPACT);
        file_close(FILE_SK1_COMPACT);
        --------------------------------
        
        
        -- INPUT SIGMA -----------------
        SIGMA_IN_VALID <= '1';
        
        WHILE NOT endfile(FILE_SIGMA) LOOP
            readline(FILE_SIGMA, V_ILINE_SIGMA);
            hread(V_ILINE_SIGMA, V_SIGMA);
                        
            SIGMA_IN_DIN  <= V_SIGMA;
            
            SIGMA_IN_ADDR  <= SIGMA_ADDR;
            
            SIGMA_ADDR := STD_LOGIC_VECTOR(UNSIGNED(SIGMA_ADDR) + 1);
                        
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        SIGMA_IN_VALID     <= '0';
        SIGMA_IN_DIN      <= (OTHERS => '0');
        SIGMA_IN_ADDR      <= (OTHERS => '0');
        
        WAIT FOR 4*CLK_PERIOD;
        
        file_close(FILE_SIGMA);
        --------------------------------


        -- INPUT CRYPTOGRAM ------------
        C0_IN_VALID <= '1';
        
        WHILE NOT endfile(FILE_C) LOOP
            readline(FILE_C, V_ILINE_C);
            hread(V_ILINE_C, V_C);
                        
            C_IN_DIN  <= V_C;
            
            C_IN_ADDR  <= C_ADDR;
            
            C_ADDR := STD_LOGIC_VECTOR(UNSIGNED(C_ADDR) + 1);
            
            IF C_TRIGGER = '0' THEN
                C0_IN_VALID <= '1';
                C1_IN_VALID <= '0';
            ELSE
                C0_IN_VALID <= '0';
                C1_IN_VALID <= '1';
            END IF;
            
            IF C_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(R_BLOCKS, LOG2(R_BLOCKS))) THEN
                C_TRIGGER := '1';
                C_ADDR := STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(R_BLOCKS)));
            END IF;
                        
            WAIT FOR CLK_PERIOD;
        END LOOP;
        
        C0_IN_VALID     <= '0';
        C1_IN_VALID     <= '0';
        C_IN_DIN        <= (OTHERS => '0');
        C_IN_ADDR       <= (OTHERS => '0');
        
        WAIT FOR 4*CLK_PERIOD;
        
        file_close(FILE_C);
        --------------------------------
                
        
        --------------------------------
        ENABLE          <= '1';
        
        WAIT FOR 2*CLK_PERIOD;     

        
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
                
        WAIT;        
    END PROCESS;
    ------------------------------------------------------------------------------ 

END Structural;
