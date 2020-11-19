----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    28/04/2020
-- LAST CHANGES:            28/04/2020
-- MODULE NAME:			    BIKE
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
    USE IEEE.MATH_REAL.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE IS
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
        -- OUTPUT ----------------------
        PK_OUT          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)   
    );
END BIKE;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE IS



-- TYPES
----------------------------------------------------------------------------------
TYPE WORD_ARRAY IS ARRAY (INTEGER RANGE<>) OF STD_LOGIC_VECTOR(31 DOWNTO 0); 



-- SIGNALS
----------------------------------------------------------------------------------
-- KEY GENERATION
SIGNAL KEYGEN_SAMPLE_ENABLE                     : STD_LOGIC;
SIGNAL SK0_SAMPLE_DONE, SK1_SAMPLE_DONE         : STD_LOGIC;


-- SECRET KEY
SIGNAL SK0_DIN_A, SK0_DIN_B                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SK1_DIN_A, SK1_DIN_B                     : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL SK0_SAMPLE_RAND, SK1_SAMPLE_RAND         : STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0);

SIGNAL SK0_SAMPLE_RDEN, SK0_SAMPLE_WREN         : STD_LOGIC;
SIGNAL SK0_SAMPLE_ADDR                          : STD_LOGIC_VECTOR(LOG2(CEIL(R_BITS,32))-1 DOWNTO 0);
SIGNAL SK0_SAMPLE_DOUT                          : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL SK1_SAMPLE_RDEN, SK1_SAMPLE_WREN         : STD_LOGIC;
SIGNAL SK1_SAMPLE_ADDR                          : STD_LOGIC_VECTOR(LOG2(CEIL(R_BITS,32))-1 DOWNTO 0);
SIGNAL SK1_SAMPLE_DOUT                          : STD_LOGIC_VECTOR(31 DOWNTO 0);


-- Inversion
SIGNAL DONE_OUT                                 : STD_LOGIC;
SIGNAL INV_RESET, INV_ENABLE, INV_DONE          : STD_LOGIC;
SIGNAL SK0_INV_RDEN, SK1_INV_RDEN               : STD_LOGIC;
SIGNAL SK0_INV_WREN, SK1_INV_WREN               : STD_LOGIC;
SIGNAL SK0_INV_ADDR, SK1_INV_ADDR               : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SK0_INV_DIN, SK1_INV_DIN                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SK0_INV_DOUT, SK1_INV_DOUT               : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL INV_DOUT                                 : STD_LOGIC_VECTOR(31 DOWNTO 0);


-- Sample SIGMA
SIGNAL SIGMA_SAMPLE_RESET                       : STD_LOGIC;
SIGNAL SIGMA_SAMPLE_ENABLE, SIGMA_SAMPLE_DONE   : STD_LOGIC;
SIGNAL SIGMA_SAMPLE_RDEN, SIGMA_SAMPLE_WREN     : STD_LOGIC;
SIGNAL SIGMA_SAMPLE_ADDR                        : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0);
SIGNAL SIGMA_SAMPLE_DOUT                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SIGMA_REG_IN, SIGMA_REG_OUT              : WORD_ARRAY(7 DOWNTO 0);
SIGNAL SIGMA_REG_EN                             : STD_LOGIC_VECTOR(7 DOWNTO 0);


-- FSM
SIGNAL SAMPLE_RESET                             : STD_LOGIC;
SIGNAL ENCODING_RESET, ENCAPS_RESET             : STD_LOGIC;
SIGNAL OUTPUT_DONE                              : STD_LOGIC;



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_KEYGEN_SAMPLE, S_KEYGEN_PK, S_OUTPUT, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- ATTRIBUTES
----------------------------------------------------------------------------------
ATTRIBUTE DONT_TOUCH : STRING;
ATTRIBUTE DONT_TOUCH OF SAMPLE_SIGMA : LABEL IS "TRUE";
ATTRIBUTE DONT_TOUCH OF REG_SIGMA : LABEL IS "TRUE";



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
            
    -- OUTPUT --------------------------------------------------------------------       
    PK_OUT <= INV_DOUT; 
    ------------------------------------------------------------------------------

      
    -- SECRET KEY ----------------------------------------------------------------
    SK0_SAMPLE_RAND  <= SK0_RAND;
    SAMPLE_SK0 : ENTITY work.BIKE_SAMPLER
    GENERIC MAP (
        THRESHOLD       => W/2,
        SIZE            => LOG2(R_BITS+1)
    )
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS -----------    
        RESET           => SAMPLE_RESET,
        ENABLE          => KEYGEN_SAMPLE_ENABLE,
        DONE            => SK0_SAMPLE_DONE,
        -- RAND --------------------
        NEW_POSITION    => SK0_SAMPLE_RAND,
        -- MEMORY I/O --------------
        RDEN            => SK0_SAMPLE_RDEN,
        WREN            => SK0_SAMPLE_WREN,
        ADDR            => SK0_SAMPLE_ADDR,
        DOUT            => SK0_SAMPLE_DOUT,
        DIN             => SK0_DIN_A
    );

    SK1_SAMPLE_RAND  <= SK1_RAND;
    SAMPLE_SK1 : ENTITY work.BIKE_SAMPLER
    GENERIC MAP (
        THRESHOLD       => W/2,
        SIZE            => LOG2(R_BITS+1)
    )
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS -----------   
        RESET           => SAMPLE_RESET,
        ENABLE          => KEYGEN_SAMPLE_ENABLE,
        DONE            => SK1_SAMPLE_DONE,
        -- RAND --------------------
        NEW_POSITION    => SK1_SAMPLE_RAND,
        -- MEMORY I/O --------------
        RDEN            => SK1_SAMPLE_RDEN,
        WREN            => SK1_SAMPLE_WREN,
        ADDR            => SK1_SAMPLE_ADDR,
        DOUT            => SK1_SAMPLE_DOUT,
        DIN             => SK1_DIN_A
    );
    
    BRAM_SK : ENTITY work.BIKE_BRAM
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => KEYGEN_SAMPLE_ENABLE,
        -- SAMPLING --------------------
        REN0_SAMP       => SK0_SAMPLE_RDEN,
        REN1_SAMP       => SK1_SAMPLE_RDEN,
        WEN0_SAMP       => SK0_SAMPLE_WREN,
        WEN1_SAMP       => SK1_SAMPLE_WREN,
        ADDR0_SAMP      => SK0_SAMPLE_ADDR,
        ADDR1_SAMP      => SK1_SAMPLE_ADDR,
        DOUT0_SAMP      => SK0_DIN_A,
        DOUT1_SAMP      => SK1_DIN_A,
        DIN0_SAMP       => SK0_SAMPLE_DOUT,
        DIN1_SAMP       => SK1_SAMPLE_DOUT,
        -- COMPUTATION -----------------
        WEN0            => SK0_INV_WREN,
        WEN1            => SK1_INV_WREN,
        REN0            => SK0_INV_RDEN,
        REN1            => SK1_INV_RDEN,
        ADDR0           => SK0_INV_ADDR,
        ADDR1           => SK1_INV_ADDR,
        DOUT0           => SK0_INV_DOUT,
        DOUT1           => SK1_INV_DOUT,
        DIN0            => (OTHERS => '0'),
        DIN1            => (OTHERS => '0')
    );
    ------------------------------------------------------------------------------    
       
    
    -- INVERSION -----------------------------------------------------------------         
    INV : ENTITY work.BIKE_INVERSION
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS ---------------
        RESET           => INV_RESET,
        ENABLE          => INV_ENABLE,
        DONE            => INV_DONE,
        -- INPUT POLYNOMIAL ------------
        POL_IN_REN      => SK0_INV_RDEN,
        POL_IN_ADDR     => SK0_INV_ADDR,
        POL_IN_DIN      => SK0_INV_DOUT, 
        -- INPUT H1 - FINAL MUL --------
        H1_IN_REN       => SK1_INV_RDEN,
        H1_IN_ADDR      => SK1_INV_ADDR,
        H1_IN_DIN       => SK1_INV_DOUT,
        -- OUTPUT ----------------------
        DONE_OUT        => DONE_OUT,
        DOUT            => INV_DOUT  
    );
    
    KEYGEN_DONE <= INV_DONE;   
    ------------------------------------------------------------------------------
    
    
    -- SAMPLE SIGMA --------------------------------------------------------------
    SAMPLE_SIGMA : ENTITY work.BIKE_SAMPLER_UNIFORM
    GENERIC MAP (
        SAMPLE_LENGTH   => L
    )
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS -----------   
        RESET           => SIGMA_SAMPLE_RESET,
        ENABLE          => SIGMA_SAMPLE_ENABLE,
        DONE            => SIGMA_SAMPLE_DONE,
        -- RAND --------------------
        NEW_RAND        => SIGMA_RAND,
        -- MEMORY I/O --------------
        RDEN            => SIGMA_SAMPLE_RDEN,
        WREN            => SIGMA_SAMPLE_WREN,
        ADDR            => SIGMA_SAMPLE_ADDR,
        DOUT            => SIGMA_SAMPLE_DOUT     
    );    
    
    REG_SIGMA : FOR I IN 0 TO 7 GENERATE
        ATTRIBUTE DONT_TOUCH : STRING;
        ATTRIBUTE DONT_TOUCH OF REG : LABEL IS "TRUE";
    BEGIN
        SIGMA_REG_EN(I) <= SIGMA_SAMPLE_WREN WHEN SIGMA_SAMPLE_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(I, LOG2(CEIL(L,32)))) ELSE '0';
        
        REG : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => 32)
        PORT MAP(D => SIGMA_SAMPLE_DOUT, Q => SIGMA_REG_OUT(I), CLK => CLK, EN => SIGMA_REG_EN(I), RST => RESET);
    END GENERATE;
    ------------------------------------------------------------------------------


    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET        =>        
                    -- SAMPLING --------                    
                    SAMPLE_RESET            <= '1';
                    KEYGEN_SAMPLE_ENABLE    <= '0';
                    
                    SIGMA_SAMPLE_RESET      <= '1'; 
                    SIGMA_SAMPLE_ENABLE     <= '0'; 
                    
                    -- INVERSION -------                
                    INV_RESET               <= '1';
                    INV_ENABLE              <= '0';
             
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN                      
                        STATE               <= S_KEYGEN_SAMPLE;
                    ELSE
                        STATE               <= S_RESET;
                    END IF;
                ----------------------------------------------
 
                ----------------------------------------------
                WHEN S_KEYGEN_SAMPLE  =>
                    -- SAMPLING --------                    
                    SAMPLE_RESET            <= '0';
                    KEYGEN_SAMPLE_ENABLE    <= '1';
                    
                    SIGMA_SAMPLE_RESET      <= '0'; 
                    SIGMA_SAMPLE_ENABLE     <= '1'; 
                    
                    -- INVERSION -------                
                    INV_RESET               <= '1';
                    INV_ENABLE              <= '0';
                                       
                    -- TRANSITION ------
                    IF (SK0_SAMPLE_DONE = '1' AND SK1_SAMPLE_DONE = '1') THEN                      
                        STATE               <= S_KEYGEN_PK;
                    ELSE
                        STATE               <= S_KEYGEN_SAMPLE;
                    END IF;
                ----------------------------------------------
                               
                ----------------------------------------------
                WHEN S_KEYGEN_PK =>
                    -- SAMPLING --------                    
                    SAMPLE_RESET            <= '1';
                    KEYGEN_SAMPLE_ENABLE    <= '0';
                    
                    SIGMA_SAMPLE_RESET      <= '0'; 
                    SIGMA_SAMPLE_ENABLE     <= '1'; 
                    
                    -- INVERSION -------                
                    INV_RESET               <= '0';
                    INV_ENABLE              <= '1';
                                
                    -- TRANSITION ------
                    IF (INV_DONE = '1') THEN                      
                        STATE               <= S_OUTPUT;
                    ELSE
                        STATE               <= S_KEYGEN_PK;
                    END IF;                                           
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_OUTPUT         =>
                    -- SAMPLING --------                    
                    SAMPLE_RESET            <= '1';
                    KEYGEN_SAMPLE_ENABLE    <= '0';
                    
                    SIGMA_SAMPLE_RESET      <= '1'; 
                    SIGMA_SAMPLE_ENABLE     <= '0'; 
                    
                    -- INVERSION -------                
                    INV_RESET               <= '0';
                    INV_ENABLE              <= '0';
                    
                    -- TRANSITION ------
                    IF (DONE_OUT = '1') THEN
                        STATE       <= S_DONE;
                    ELSE 
                        STATE       <= S_OUTPUT;
                    END IF;
                ----------------------------------------------
                                                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- SAMPLING --------                    
                    SAMPLE_RESET            <= '1';
                    KEYGEN_SAMPLE_ENABLE    <= '0';
                    
                    SIGMA_SAMPLE_RESET      <= '1'; 
                    SIGMA_SAMPLE_ENABLE     <= '0'; 
                    
                    -- INVERSION -------                
                    INV_RESET               <= '1';
                    INV_ENABLE              <= '0';
         
                    -- TRANSITION ------
                    IF RESET = '1' THEN
                        STATE       <= S_RESET;
                    ELSE 
                        STATE       <= S_DONE;
                    END IF;
                ----------------------------------------------
                                
            END CASE;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------
END Structural;
