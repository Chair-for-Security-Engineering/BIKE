
----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:           Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:            Jan Richter-Brockmann
--
-- CREATE DATE:       2020-05-27
-- LAST CHANGES:      2020-05-27
-- MODULE NAME:       BIKE_SQUARING_K1_GENERIC
--
-- REVISION:          1.00 - File was automatically created by a Sage script for r=12323 and d=32.
--
-- LICENCE:           Please look at licence.txt
-- USAGE INFORMATION: Please look at readme.txt. If licence.txt or readme.txt
--                    are missing or	if you have questions regarding the code
--                    please contact Tim Güneysu (tim.gueneysu@rub.de) and
--                    Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
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
ENTITY BIKE_SQUARING_K1_GENERIC IS
  PORT (  
    -- CONTROL PORTS ----------------
    CLK             : IN  STD_LOGIC; 	
    RESET           : IN  STD_LOGIC;
    ENABLE          : IN  STD_LOGIC;
    DONE            : OUT STD_LOGIC;
    -- INPUT POL -------------------
    REN_IN          : OUT STD_LOGIC;
    ADDR_IN         : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
    DIN_IN          : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
    -- OUTPUT POL ------------------
    WEN_OUT         : OUT STD_LOGIC;
    ADDR_OUT        : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
    DOUT_OUT        : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0)
  );
END BIKE_SQUARING_K1_GENERIC;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_SQUARING_K1_GENERIC IS
  
    
    
-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_RST                          : STD_LOGIC;
SIGNAL CNT_EN                           : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL CNT_OUT_0                        : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL CNT_OUT_1                        : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);

SIGNAL CNT_EN_OUT, CNT_RST_OUT          : STD_LOGIC;
SIGNAL CNT_DONE_OUT                     : STD_LOGIC;
SIGNAL CNT_OUT_OUT                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);

SIGNAL CNT_EN_INIT, CNT_RST_INIT        : STD_LOGIC;
SIGNAL CNT_DONE_INIT                    : STD_LOGIC;
SIGNAL CNT_OUT_INIT                     : STD_LOGIC_VECTOR(LOG2(2)-1 DOWNTO 0);

-- REGISTER
SIGNAL SEL_REG_EN                       : STD_LOGIC;
SIGNAL REG_EN                           : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL REG_IN                           : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL REG0_OUT                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL REG1_OUT                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

-- CONTROL MEMORY
SIGNAL SEL_ADDR_EN                      : STD_LOGIC;
SIGNAL SEL_ADDR                         : STD_LOGIC_VECTOR(1 DOWNTO 0);

-- OUTPUT
SIGNAL DOUT_OUT_PRE                     : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL DOUT_0, DOUT_PART_0              : STD_LOGIC_VECTOR(B_WIDTH/2-1 DOWNTO 0);
SIGNAL DOUT_1, DOUT_PART_1              : STD_LOGIC_VECTOR(B_WIDTH/2-1 DOWNTO 0);

SIGNAL DOUT_REG_COMB0_0                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL DOUT_REG_COMB1_0                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL DOUT_REG_COMB0_1                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL DOUT_REG_COMB1_1                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

SIGNAL WRITE_LAST                       : STD_LOGIC;
SIGNAL SEL_REG_OUT                      : STD_LOGIC_VECTOR(0 DOWNTO 0);
  
    
    
-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_INIT0, S_INIT1, S_WRITE, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN
  
    -- COUNTER -------------------------------------------------------------------
    CNT_DONE_OUT <= '0' WHEN CNT_OUT_OUT < STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-2, LOG2(WORDS))) ELSE '1';
    WRITE_LAST <= '1' WHEN CNT_OUT_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) ELSE '0';
    
    CNT_OUT : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP(CLK => CLK, EN => CNT_EN_OUT, RST => CNT_RST_OUT, CNT_OUT => CNT_OUT_OUT);
    
    CNT_DONE_INIT <= '0' WHEN CNT_OUT_INIT < STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(2))) ELSE '1';
    CNT_INIT : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(2), MAX_VALUE => 1)
    PORT MAP(CLK => CLK, EN => CNT_EN_INIT, RST => CNT_RST_INIT, CNT_OUT => CNT_OUT_INIT);
    
    CNT_EN <= SEL_ADDR;
    
    CNT0 : ENTITY work.BIKE_COUNTER_INC_INIT GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => 386, INITIAL => 192)
    PORT MAP(CLK => CLK, EN => CNT_EN(0), RST => CNT_RST, CNT_OUT => CNT_OUT_0);
    CNT1 : ENTITY work.BIKE_COUNTER_INC_INIT GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => 193, INITIAL => 0)
    PORT MAP(CLK => CLK, EN => CNT_EN(1), RST => CNT_RST, CNT_OUT => CNT_OUT_1);  
    ------------------------------------------------------------------------------


    -- OUTPUT --------------------------------------------------------------------
    ADDR_OUT <= CNT_OUT_OUT;
    
    -- special case for the polynomial's last msbs
    DOUT_OUT <= DOUT_OUT_PRE WHEN WRITE_LAST = '0' ELSE (B_WIDTH-1 DOWNTO OVERHANG => '0') & DOUT_OUT_PRE(OVERHANG-1 DOWNTO 0);
    
    -- spread output
    DOUT_ASSIGN : FOR I IN 0 TO B_WIDTH/2-1 GENERATE
      DOUT_OUT_PRE(2*I+0)   <= DOUT_0(I);
      DOUT_OUT_PRE(2*I+1)   <= DOUT_1(I);
    END GENERATE;

    
    -- assignment for DOUT_0
    DOUT_0 <= DOUT_PART_0;
    WITH SEL_ADDR SELECT DOUT_PART_0 <=
      DOUT_REG_COMB0_0(1*B_WIDTH/2-1+0 DOWNTO 0*B_WIDTH/2+0) WHEN "10",
      DOUT_REG_COMB0_0(2*B_WIDTH/2-1+0 DOWNTO 1*B_WIDTH/2+0) WHEN "01",
      (OTHERS => '0') WHEN OTHERS; 

    WITH SEL_REG_OUT SELECT DOUT_REG_COMB0_0 <=
      REG1_OUT WHEN "1",
      (OTHERS => '0') WHEN OTHERS; 

    WITH SEL_REG_OUT SELECT DOUT_REG_COMB1_0 <=
      REG1_OUT WHEN "1",
      (OTHERS => '0') WHEN OTHERS; 



    -- assignment for DOUT_1
    DOUT_1 <= DOUT_PART_1;
    WITH SEL_ADDR SELECT DOUT_PART_1 <=
      DIN_IN(1 DOWNTO 0) & DOUT_REG_COMB0_1(31 DOWNTO 1*B_WIDTH/2+2) WHEN "10",
      DOUT_REG_COMB1_1(1*B_WIDTH/2-1+2 DOWNTO 0*B_WIDTH/2+2) WHEN "01",
      (OTHERS => '0') WHEN OTHERS; 

    WITH SEL_REG_OUT SELECT DOUT_REG_COMB0_1 <=
      REG0_OUT WHEN "1",
      (OTHERS => '0') WHEN OTHERS; 

    WITH SEL_REG_OUT SELECT DOUT_REG_COMB1_1 <=
      REG0_OUT WHEN "1",
      (OTHERS => '0') WHEN OTHERS; 



    -- selection of the correct registers to create output   
    SELECTION_REG : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                SEL_REG_OUT <= "1";
            ELSE
                IF SEL_ADDR = "01" AND CNT_DONE_INIT = '1' THEN
                    SEL_REG_OUT <= SEL_REG_OUT(-1 DOWNTO 0) & SEL_REG_OUT(0);
                ELSE 
                    SEL_REG_OUT <= SEL_REG_OUT;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------
  

    -- REGISTER ------------------------------------------------------------------
    -- generate selection signal to read from lower or upper part of the polynomial    
    SELECTION_ADDR : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                SEL_ADDR <= "01";
            ELSE
                IF SEL_ADDR_EN = '1' THEN
                    SEL_ADDR <= SEL_ADDR(0 DOWNTO 0) & SEL_ADDR(1);
                ELSE 
                    SEL_ADDR <= SEL_ADDR;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- select the correct part of the polynomial
    WITH SEL_ADDR SELECT ADDR_IN <=
      CNT_OUT_0 WHEN "01",
      CNT_OUT_1 WHEN "10",
      (OTHERS => '0') WHEN OTHERS;

    -- registers to hold previous read words   
    SELECTION_REG_EN : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                REG_EN <= "01";
            ELSE
                IF SEL_REG_EN = '1' THEN
                    REG_EN <= REG_EN(0 DOWNTO 0) & REG_EN(1);
                ELSE 
                    REG_EN <= REG_EN;
                END IF;
            END IF;
        END IF;
    END PROCESS;
      
    REG_IN  <= DIN_IN;
  
    REG0 : ENTITY work.RegisterFDRE GENERIC MAP (SIZE => B_WIDTH)
    PORT MAP(D => REG_IN, Q => REG0_OUT, CLK => CLK, EN => REG_EN(0), RST => RESET);
    REG1 : ENTITY work.RegisterFDRE GENERIC MAP (SIZE => B_WIDTH)
    PORT MAP(D => REG_IN, Q => REG1_OUT, CLK => CLK, EN => REG_EN(1), RST => RESET);
    ------------------------------------------------------------------------------

    -- FSM -----------------------------------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET        =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';
                    
                    CNT_EN_INIT             <= '0';
                    CNT_RST_INIT            <= '1';
                    
                    CNT_RST                 <= '1';
                    
                    -- CONTROL ---------
                    SEL_REG_EN              <= '0';
                    SEL_ADDR_EN             <= '0'; 
                    
                    -- BRAM ------------
                    REN_IN                  <= '0';
                    WEN_OUT                 <= '0';
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN                      
                        STATE               <= S_INIT0;
                    ELSE
                        STATE               <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_INIT0  =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';

                    CNT_EN_INIT             <= '1';
                    CNT_RST_INIT            <= '0';
                                        
                    CNT_RST                 <= '0';
                    
                    -- CONTROL ---------
                    SEL_REG_EN              <= '0';
                    SEL_ADDR_EN             <= '1';                
                    
                    -- BRAM ------------
                    REN_IN                  <= '1';
                    WEN_OUT                 <= '0';
                                      
                    -- TRANSITION ------
                    STATE                   <= S_INIT1;
                ----------------------------------------------    

                ----------------------------------------------
                WHEN S_INIT1  =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';
                    
                    CNT_EN_INIT             <= '1';
                    CNT_RST_INIT            <= '0';
                    
                    CNT_RST                 <= '0';
                    
                    -- CONTROL ---------
                    SEL_REG_EN              <= '1';
                    SEL_ADDR_EN             <= '1';                
                    
                    -- BRAM ------------
                    REN_IN                  <= '1';
                    WEN_OUT                 <= '0';
                                      
                    -- TRANSITION ------
                    --STATE <= S_INIT2;
                    IF (CNT_DONE_INIT = '1') THEN
                        STATE               <= S_WRITE;
                    ELSE
                        STATE               <= S_INIT1;
                    END IF;
                ----------------------------------------------
                                
                ----------------------------------------------
                WHEN S_WRITE  =>
                    -- GLOBAL ----------
                    DONE                    <= '0';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '1';
                    CNT_RST_OUT             <= '0';
                    
                    CNT_EN_INIT             <= '0';
                    CNT_RST_INIT            <= '0';
                    
                    CNT_RST                 <= '0';
                    
                    -- CONTROL ---------
                    SEL_REG_EN              <= '1';
                    SEL_ADDR_EN             <= '1';                
                    
                    -- BRAM ------------
                    REN_IN                  <= '1';
                    WEN_OUT                 <= '1';   
                                                        
                    -- TRANSITION ------
                    IF (CNT_DONE_OUT = '1') THEN
                        STATE               <= S_DONE;
                    ELSE
                        STATE               <= S_WRITE;
                    END IF;
                ---------------------------------------------- 
                                                                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- GLOBAL ----------
                    DONE                    <= '1';
                
                    -- COUNTER ---------
                    CNT_EN_OUT              <= '0';
                    CNT_RST_OUT             <= '1';

                    
                    CNT_EN_INIT             <= '0';
                    CNT_RST_INIT            <= '1';
                                        
                    CNT_RST                 <= '1';
                    
                    -- CONTROL ---------
                    SEL_REG_EN              <= '0';
                    SEL_ADDR_EN             <= '0';                
                    
                    -- BRAM ------------
                    REN_IN                  <= '0';
                    WEN_OUT                 <= '0';
                                        
                    -- TRANSITION ------
                    STATE                   <= S_RESET;
                ----------------------------------------------
                                
            END CASE;
        END IF;
    END PROCESS;    
    ------------------------------------------------------------------------------

END Behavioral;
