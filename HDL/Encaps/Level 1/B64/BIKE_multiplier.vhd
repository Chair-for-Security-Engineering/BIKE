----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    03/02/2020
-- LAST CHANGES:            23/04/2020
-- MODULE NAME:			    BIKE_MULTIPLIER
--
-- REVISION:				1.10 - Adapted to BIKE-2.
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
ENTITY BIKE_MULTIPLIER IS
	PORT (  
        CLK                 : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET               : IN  STD_LOGIC;
        ENABLE              : IN  STD_LOGIC;
        DONE                : OUT STD_LOGIC;
        -- RESULT ----------------------
        RESULT_RDEN         : OUT STD_LOGIC;
        RESULT_WREN         : OUT STD_LOGIC;
        RESULT_ADDR         : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        RESULT_DOUT_0       : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        RESULT_DIN_0        : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- KEY -------------------------
        K_RDEN              : OUT STD_LOGIC;
        K_WREN              : OUT STD_LOGIC;
        K_ADDR              : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        K_DOUT_0            : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        K_DIN_0             : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- MESSAGE ---------------------
        M_RDEN              : OUT STD_LOGIC;
        M_ADDR              : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        M_DIN               : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0)   
    );
END BIKE_MULTIPLIER;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_MULTIPLIER IS



-- CONSTANTS ---------------------------------------------------------------------
CONSTANT WORDS      : NATURAL := CEIL(R_BITS, B_WIDTH);
CONSTANT OVERHANG   : NATURAL := R_BITS - B_WIDTH*(WORDS-1);



-- SIGNALS
----------------------------------------------------------------------------------
-- CONTROL
SIGNAL WRITE_LAST                               : STD_LOGIC;
SIGNAL WRITE_FRAC                               : STD_LOGIC;
SIGNAL SEL_LOW, SEL_LOW_D                       : STD_LOGIC_VECTOR(1 DOWNTO 0);

-- COUNTER
SIGNAL CNT_ROW_EN, CNT_ROW_RST                  : STD_LOGIC;   
SIGNAL CNT_COL_EN, CNT_COL_RST                  : STD_LOGIC;   
SIGNAL CNT_SHIFT_EN, CNT_SHIFT_RST              : STD_LOGIC;   
SIGNAL CNT_ROW_OUT, CNT_COL_OUT, CNT_SHIFT_OUT  : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);

-- KEY 
SIGNAL K_ADDR_INT                               : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL K_KEY0_MSBS_D, K_KEY1_MSBS_D             : STD_LOGIC_VECTOR(B_WIDTH-OVERHANG-1 DOWNTO 0);

-- INTERMEDIATE REGISTER
SIGNAL INT_IN_0, INT_OUT_0                      : STD_LOGIC_VECTOR(B_WIDTH-2 DOWNTO 0);

-- SYSTOLIC MULTIPLIER
SIGNAL RESULT_SUBARRAY_0                        : STD_LOGIC_VECTOR(B_WIDTH*B_WIDTH-1 DOWNTO 0);
SIGNAL RESULT_UPPER_SUBARRAY_REORDERED_0        : STD_LOGIC_VECTOR(B_WIDTH*(B_WIDTH+1)/2-1 DOWNTO 0);
SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_0        : STD_LOGIC_VECTOR((B_WIDTH-1)*(B_WIDTH)/2-1 DOWNTO 0);
SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_INIT1_0  : STD_LOGIC_VECTOR((B_WIDTH-1)*(B_WIDTH)/2-1 DOWNTO 0) := (OTHERS => '0');
SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0  : STD_LOGIC_VECTOR((B_WIDTH-1)*(B_WIDTH)/2-1 DOWNTO 0) := (OTHERS => '0');
SIGNAL RESULT_TRAPEZOIDAL_UPPER_ADDITION_0      : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL RESULT_UPPER_INT_ADD_0                   : STD_LOGIC_VECTOR(B_WIDTH*(B_WIDTH+1)/2-1 DOWNTO 0); 
SIGNAL RESULT_LOWER_SUBARRAY_ADD_IN_0           : STD_LOGIC_VECTOR((B_WIDTH-1)*(B_WIDTH)/2-1 DOWNTO 0);
SIGNAL RESULT_TRAPEZOIDAL_LOWER_ADDITION_0      : STD_LOGIC_VECTOR(B_WIDTH-2 DOWNTO 0);
SIGNAL RESULT_LOWER_INT_ADD_0                   : STD_LOGIC_VECTOR((B_WIDTH-1)*(B_WIDTH)/2-1 DOWNTO 0);
SIGNAL RESULT_DOUT_ADD_0                        : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_READ_SECOND_LAST, S_READ_LAST, S_FIRST_COLUMN, S_COLUMN, S_SWITCH_COLUMN, S_WRITE_LAST, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- KEY -----------------------------------------------------------------------
    WITH SEL_LOW SELECT K_ADDR_INT <=
        (OTHERS => '0') WHEN "00",
        STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-2, LOG2(WORDS))) WHEN "01",
        STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) WHEN "10",
        CNT_ROW_OUT WHEN "11",
        (OTHERS => '0') WHEN OTHERS;
          
    K_ADDR <= (OTHERS => '0') WHEN WRITE_LAST = '1' ELSE (K_ADDR_INT);
    
    K_DOUT_0 <= K_DIN_0(OVERHANG-1 DOWNTO 0) & K_KEY0_MSBS_D WHEN WRITE_LAST = '1' ELSE K_DIN_0;

    -- REGISTER 
    REG_KEY0_MSBs : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH-OVERHANG)
    PORT MAP (D => K_DIN_0(B_WIDTH-1 DOWNTO OVERHANG), Q => K_KEY0_MSBS_D, CLK => CLK, EN => ENABLE, RST => RESET);    
    ------------------------------------------------------------------------------


    -- ERROR AND ADDITION --------------------------------------------------------
    RESULT_ADDR <= CNT_SHIFT_OUT;
    ------------------------------------------------------------------------------
        
    
    -- MESSAGE -------------------------------------------------------------------
    M_ADDR <= CNT_COL_OUT;
    ------------------------------------------------------------------------------
    
    
    -- MULTIPLIER ----------------------------------------------------------------
    L_MULT : FOR I IN 0 TO B_WIDTH-1 GENERATE
        RESULT_SUBARRAY_0((I+1)*B_WIDTH-1 DOWNTO I*B_WIDTH) <= K_DIN_0 WHEN M_DIN(I) = '1' ELSE (OTHERS => '0');
    END GENERATE;   
    ------------------------------------------------------------------------------
        
    -- REORDERING ----------------------------------------------------------------
    -- UPPER REGULAR TRIANGLE
    L_RE_UP0 : FOR R IN 0 TO B_WIDTH-1 GENERATE
        L_RE_UP1 : FOR C IN 0 TO R GENERATE
            RESULT_UPPER_SUBARRAY_REORDERED_0(R*(R+1)/2+C) <= RESULT_SUBARRAY_0(C*B_WIDTH+R-C);
        END GENERATE;
    END GENERATE;  
    
    -- LOWER REGULAR TRIANGLE
    L_RE_LOW0 : FOR R IN 0 TO B_WIDTH-2 GENERATE
        L_RE_LOW1 : FOR C IN 0 TO B_WIDTH-2-R GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-R)*(B_WIDTH-R)/2 + C) <= RESULT_SUBARRAY_0((B_WIDTH-1-C)*B_WIDTH + R + C + 1);
        END GENERATE;
    END GENERATE;   

    -- GENERATE UPPER TRIANGLE FOR INITIAL PHASE 
    L_RE_INIT0 : FOR R IN 0 TO B_WIDTH-OVERHANG-2 GENERATE
        L_RE_INIT1 : FOR C IN 0 TO B_WIDTH-OVERHANG-2-R GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_INIT1_0(((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-R)*(B_WIDTH-R)/2) + C) <= RESULT_LOWER_SUBARRAY_REORDERED_0((B_WIDTH-1)*(B_WIDTH)/2 - (B_WIDTH-OVERHANG-1-R)*(B_WIDTH-OVERHANG-R)/2 + C);
        END GENERATE;
    END GENERATE;
    
    -- GENERATE LOWER TRAPEZOID FOR INITIAL PHASE
    L_RE_INIT2 : FOR R IN 0 TO B_WIDTH-OVERHANG-2 GENERATE
        L_RE_INIT3 : FOR C IN B_WIDTH-1-R-OVERHANG TO B_WIDTH-2-R GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0(((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-R)*(B_WIDTH-R)/2) + C) <= RESULT_SUBARRAY_0((C-(B_WIDTH-1-R-OVERHANG)) + B_WIDTH*(OVERHANG+(B_WIDTH-1-OVERHANG-C)));
        END GENERATE;
    END GENERATE;    

    L_RE_INIT4 : FOR R IN B_WIDTH-OVERHANG-1 TO B_WIDTH-2 GENERATE
        L_RE_INIT5 : FOR C IN 0 TO B_WIDTH-2-R GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0(((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-R)*(B_WIDTH-R)/2) + C) <= RESULT_SUBARRAY_0((C-(B_WIDTH-1-R-OVERHANG)) + B_WIDTH*(OVERHANG+(B_WIDTH-1-OVERHANG-C)));
        END GENERATE;
    END GENERATE; 
    
    L_RE_INIT6 : FOR R IN 0 TO B_WIDTH-OVERHANG-2 GENERATE
        RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0(((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-R)*(B_WIDTH-R)/2)) <= INT_OUT_0(R);
    END GENERATE;
    ------------------------------------------------------------------------------
            
    -- ADDITION ------------------------------------------------------------------
    -- UPPER ADDITION
    RESULT_TRAPEZOIDAL_UPPER_ADDITION_0(0) <= RESULT_UPPER_SUBARRAY_REORDERED_0(0); 
    
    RESULT_UPPER_INT_ADD_0(0) <= '0'; -- never used
    
    L_UPPER_ADD : FOR I IN 1 TO B_WIDTH-1 GENERATE
        RESULT_UPPER_INT_ADD_0(I*(I+1)/2) <= RESULT_UPPER_SUBARRAY_REORDERED_0(I*(I+1)/2);
        LO : FOR R IN 1 TO I GENERATE
            RESULT_UPPER_INT_ADD_0(I*(I+1)/2+R) <= RESULT_UPPER_INT_ADD_0(I*(I+1)/2+R-1) XOR RESULT_UPPER_SUBARRAY_REORDERED_0(I*(I+1)/2+R);
        END GENERATE;
        RESULT_TRAPEZOIDAL_UPPER_ADDITION_0(I) <= RESULT_UPPER_INT_ADD_0(I*(I+1)/2+I);
    END GENERATE;    
    
    -- LOWER ADDITION
    SEL_REG : ENTITY work.RegisterFDRE GENERIC MAP (SIZE => 2)
    PORT MAP (D => SEL_LOW, Q => SEL_LOW_D, CLK => CLK, EN => ENABLE, RST => RESET);
    
    WITH SEL_LOW_D SELECT RESULT_LOWER_SUBARRAY_ADD_IN_0 <=
        (OTHERS => '0') WHEN "00",
        RESULT_LOWER_SUBARRAY_REORDERED_INIT1_0 WHEN "01",
        RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0 WHEN "10",
        RESULT_LOWER_SUBARRAY_REORDERED_0 WHEN "11",
        (OTHERS => '0') WHEN OTHERS;
            
    RESULT_TRAPEZOIDAL_LOWER_ADDITION_0(B_WIDTH-2) <= RESULT_LOWER_SUBARRAY_ADD_IN_0((B_WIDTH-1)*(B_WIDTH)/2-1);
    
    RESULT_LOWER_INT_ADD_0((B_WIDTH-1)*(B_WIDTH)/2-1) <= '0';
    
    L_LOWER_ADD : FOR I IN 0 TO B_WIDTH-3 GENERATE
        RESULT_LOWER_INT_ADD_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-(I))*(B_WIDTH-(I))/2) <= RESULT_LOWER_SUBARRAY_ADD_IN_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-(I))*(B_WIDTH-(I))/2);
        L_LOWERO : FOR R IN 1 TO B_WIDTH-2-I GENERATE
            RESULT_LOWER_INT_ADD_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-(I))*(B_WIDTH-(I))/2 + R) <= RESULT_LOWER_INT_ADD_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-(I))*(B_WIDTH-(I))/2+R-1) XOR RESULT_LOWER_SUBARRAY_ADD_IN_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-(I))*(B_WIDTH-(I))/2 + R);
        END GENERATE;
        RESULT_TRAPEZOIDAL_LOWER_ADDITION_0(I) <= RESULT_LOWER_INT_ADD_0((B_WIDTH-1)*B_WIDTH/2 - (B_WIDTH-1-(I))*(B_WIDTH-(I))/2 + B_WIDTH-2-I);
    END GENERATE;  
    
    -- FINAL ADDITION 
    WRITE_FRAC <= '1' WHEN CNT_ROW_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS, LOG2(WORDS))) ELSE '0';
    
    RESULT_DOUT_ADD_0 <= RESULT_DIN_0 XOR RESULT_TRAPEZOIDAL_UPPER_ADDITION_0 XOR ('0' & INT_OUT_0);
    
    RESULT_DOUT_0 <= RESULT_DOUT_ADD_0 WHEN WRITE_FRAC = '0' ELSE (B_WIDTH-1 DOWNTO OVERHANG => '0') & RESULT_DOUT_ADD_0(OVERHANG-1 DOWNTO 0);
    
    -- WRITE INTERMEDIATE RESULT TO REGISTER
    INT_IN_0 <= RESULT_TRAPEZOIDAL_LOWER_ADDITION_0;
    ------------------------------------------------------------------------------
    
    
    -- INTERMEDIATE REGISTER -----------------------------------------------------
    INTERMEDIATE_REG_LO_0 : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH-1)
    PORT MAP(D => INT_IN_0, Q => INT_OUT_0, CLK => CLK, EN => ENABLE, RST => RESET);
    ------------------------------------------------------------------------------    
    

    -- COUNTER -------------------------------------------------------------------    
    -- COUNTS THE NUMBER OF FINISHED ROWS (KEY COUNTER)
    ROW_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP(CLK => CLK, EN => CNT_ROW_EN, RST => CNT_ROW_RST, CNT_OUT => CNT_ROW_OUT);

    -- COUNTS THE NUMBER OF FINISHED COLUMNS
    ROL_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP(CLK => CLK, EN => CNT_COL_EN, RST => CNT_COL_RST, CNT_OUT => CNT_COL_OUT);
        
    -- TRACKS AND COUNTS THE LEAST SIGNIFICANT WORD OD THE RESULT
    SHIFT_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS-1)
    PORT MAP(CLK => CLK, EN => CNT_SHIFT_EN, RST => CNT_SHIFT_RST, CNT_OUT => CNT_SHIFT_OUT);
    ------------------------------------------------------------------------------
    
    
    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                STATE <= S_RESET;
                
                -- GLOBAL ----------
                DONE            <= '0';
                
                -- CONTROL ---------
                SEL_LOW         <= "00";
                WRITE_LAST      <= '0';

                -- KEY -------------
                K_RDEN          <= '0';                   
                K_WREN          <= '0';   
                
                -- ERROR -----------
                RESULT_RDEN     <= '0';
                RESULT_WREN     <= '0'; 
                
                -- MESSAGE ---------
                M_RDEN          <= '0';
                                    
                -- COUNTER ---------
                CNT_ROW_EN      <= '0';
                CNT_ROW_RST     <= '1';
                
                CNT_COL_EN      <= '0';
                CNT_COL_RST     <= '1';

                CNT_SHIFT_EN    <= '0';
                CNT_SHIFT_RST   <= '1';  
            ELSE
                CASE STATE IS
                    
                    ----------------------------------------------
                    WHEN S_RESET                =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "00";
                        WRITE_LAST      <= '0';
    
                        -- KEY -------------
                        K_RDEN          <= '0';                   
                        K_WREN          <= '0';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '0';
                        RESULT_WREN     <= '0'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '0';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '0';
                        CNT_ROW_RST     <= '1';
                        
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '1';
     
                        CNT_SHIFT_EN    <= '0';
                        CNT_SHIFT_RST   <= '1';               
                        
                        -- TRANSITION ------
                        IF (ENABLE = '1') THEN
                            STATE       <= S_READ_SECOND_LAST;
                        ELSE
                            STATE       <= S_RESET;
                        END IF;
                    ----------------------------------------------
                                    
                    ----------------------------------------------
                    WHEN S_READ_SECOND_LAST     =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "01";
                        WRITE_LAST      <= '0';
    
                        -- KEY -------------
                        K_RDEN          <= '1';                  
                        K_WREN          <= '0';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '0';
                        RESULT_WREN     <= '0'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '1';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '0';
                        CNT_ROW_RST     <= '0';
                        
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '0';
     
                        CNT_SHIFT_EN    <= '0';
                        CNT_SHIFT_RST   <= '0';               
                        
                        -- TRANSITION ------
                        STATE           <= S_READ_LAST;
                    ----------------------------------------------                
                    
                    ----------------------------------------------
                    WHEN S_READ_LAST            =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "10";
                        WRITE_LAST      <= '0';
    
                        -- KEY -------------
                        K_RDEN          <= '1';                  
                        K_WREN          <= '0';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '0';
                        RESULT_WREN     <= '0'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '1';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '0';
                        CNT_ROW_RST     <= '0';
                        
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '0';
     
                        CNT_SHIFT_EN    <= '0';
                        CNT_SHIFT_RST   <= '0';               
                        
                        -- TRANSITION ------
                        STATE           <= S_FIRST_COLUMN;
                    ----------------------------------------------  
                    
                    ----------------------------------------------
                    WHEN S_FIRST_COLUMN         =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        WRITE_LAST      <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "11";
    
                        -- KEY -------------
                        K_RDEN          <= '1';                  
                        K_WREN          <= '0';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '1';
                        RESULT_WREN     <= '0'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '1';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '1';
                        CNT_ROW_RST     <= '0';
                        
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '0';
     
                        CNT_SHIFT_EN    <= '1';
                        CNT_SHIFT_RST   <= '0';               
                        
                        -- TRANSITION ------
                        STATE           <= S_COLUMN;
                    ----------------------------------------------                                  
    
                    ----------------------------------------------
                    WHEN S_COLUMN               =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "11";
                        WRITE_LAST      <= '0';
    
                        -- KEY -------------
                        K_RDEN          <= '1';                  
                        K_WREN          <= '1';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '1';
                        RESULT_WREN     <= '1'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '1';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '1';
                        CNT_ROW_RST     <= '0';
                        
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '0';
     
                        CNT_SHIFT_EN    <= '1';
                        CNT_SHIFT_RST   <= '0';               
                        
                        -- TRANSITION ------                    
                        IF (CNT_ROW_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-2, LOG2(WORDS)))) THEN
                            IF (CNT_COL_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS)))) THEN
                                STATE           <= S_WRITE_LAST;
                            ELSE
                                STATE           <= S_SWITCH_COLUMN;
                            END IF;
                        ELSE
                            STATE               <= S_COLUMN;
                        END IF;                    
                    ---------------------------------------------- 
                    
                    ----------------------------------------------
                    WHEN S_SWITCH_COLUMN        =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "11";
                        WRITE_LAST      <= '1';
    
                        -- KEY -------------
                        K_RDEN          <= '1';                  
                        K_WREN          <= '1';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '1';
                        RESULT_WREN     <= '1'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '1';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '0';
                        CNT_ROW_RST     <= '1';
                        
                        CNT_COL_EN      <= '1';
                        CNT_COL_RST     <= '0';
     
                        CNT_SHIFT_EN    <= '1';
                        CNT_SHIFT_RST   <= '0';               
                        
                        -- TRANSITION ------
                        STATE           <= S_READ_SECOND_LAST;                   
                    ---------------------------------------------- 
    
                    ----------------------------------------------
                    WHEN S_WRITE_LAST        =>
                        -- GLOBAL ----------
                        DONE            <= '0';
                        
                        -- CONTROL ---------
                        SEL_LOW         <= "11";
                        WRITE_LAST      <= '1';
    
                        -- KEY -------------
                        K_RDEN          <= '0';                  
                        K_WREN          <= '0';   
                        
                        -- ERROR -----------
                        RESULT_RDEN     <= '1';
                        RESULT_WREN     <= '1'; 
                        
                        -- MESSAGE ---------
                        M_RDEN          <= '0';
                                            
                        -- COUNTER ---------
                        CNT_ROW_EN      <= '0';
                        CNT_ROW_RST     <= '1';
                        
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '0';
     
                        CNT_SHIFT_EN    <= '0';
                        CNT_SHIFT_RST   <= '0';               
                        
                        -- TRANSITION ------
                        STATE           <= S_DONE;                   
                    ---------------------------------------------- 
                                                            
                    ----------------------------------------------
                    WHEN S_DONE         =>   
                        -- GLOBAL ----------
                        DONE            <= '1';
                        
                        -- PRIVATE KEY -----
                        K_RDEN          <= '0';
                        K_WREN          <= '0';
    
                        -- ERROR -----------
                        RESULT_RDEN     <= '0';
                        RESULT_WREN     <= '0';
    
                        -- MESSAGE ---------
                        M_RDEN          <= '0';                
                        
                        CNT_ROW_EN      <= '0';
                        CNT_ROW_RST     <= '1';
    
                        CNT_COL_EN      <= '0';
                        CNT_COL_RST     <= '1';
                                            
                        CNT_SHIFT_EN    <= '0';
                        CNT_SHIFT_RST   <= '1';                            
                                 
                        -- TRANSITION ------
                        STATE           <= S_RESET;
                    ----------------------------------------------
                                    
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------

END Behavioral;
