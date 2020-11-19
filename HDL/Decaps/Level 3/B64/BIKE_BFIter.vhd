----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    13/06/2020
-- LAST CHANGES:            14/08/2020
-- MODULE NAME:			    BIKE_BFITER
--
-- REVISION:				2.00 - Adapted to decoder used in [1].
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
--
-- [1] Nir Drucker, Shay Gueron, and Dusan Kostic; "Additional implementation of BIKE 
--     (Bit Flipping Key Encapsulation)"; https://github.com/awslabs/bike-kem
--
----------------------------------------------------------------------------------



-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
            
LIBRARY work;
        USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_BFITER IS
    PORT(   
        CLK                 : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------
        RESET               : IN  STD_LOGIC;    
        ENABLE              : IN  STD_LOGIC;    
        DONE                : OUT STD_LOGIC;
        MODE_SEL            : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); -- "00" Produce black/gray lists; "01" use black mask; "10" use gray mask; "11" only error flip
        -- THRESHOLD -------------------
        TH                  : IN  STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0);
        -- SYNDROME --------------------
        SYNDROME_RDEN       : OUT STD_LOGIC;  
        SYNDROME_WREN       : OUT STD_LOGIC;
        SYNDROME_A_ADDR     : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);  
        SYNDROME_A_DOUT     : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);  
        SYNDROME_A_DIN      : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        SYNDROME_B_ADDR     : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);  
        SYNDROME_B_DOUT     : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);  
        SYNDROME_B_DIN      : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- SECRET KEY ------------------
        SK0_RDEN            : OUT STD_LOGIC;  
        SK1_RDEN            : OUT STD_LOGIC;  
        SK0_WREN            : OUT STD_LOGIC;
        SK1_WREN            : OUT STD_LOGIC;
        SK_ADDR             : OUT STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        SK_DOUT             : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        SK0_DIN             : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        SK1_DIN             : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- ERROR -----------------------
        E0_RDEN             : OUT STD_LOGIC;  
        E1_RDEN             : OUT STD_LOGIC;  
        E0_WREN             : OUT STD_LOGIC;  
        E1_WREN             : OUT STD_LOGIC; 
        E_ADDR              : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        E_DOUT              : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        E0_DIN              : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        E1_DIN              : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- BLACK -----------------------
        BLACK0_RDEN         : OUT STD_LOGIC;
        BLACK1_RDEN         : OUT STD_LOGIC;
        BLACK0_WREN         : OUT STD_LOGIC;
        BLACK1_WREN         : OUT STD_LOGIC;
        BLACK_ADDR          : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        BLACK_DOUT          : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        BLACK0_DIN          : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        BLACK1_DIN          : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        -- GRAY -----------------------
        GRAY0_RDEN          : OUT STD_LOGIC;
        GRAY1_RDEN          : OUT STD_LOGIC;
        GRAY0_WREN          : OUT STD_LOGIC;
        GRAY1_WREN          : OUT STD_LOGIC;
        GRAY_ADDR           : OUT STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
        GRAY_DOUT           : OUT STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        GRAY0_DIN           : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        GRAY1_DIN           : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0)
    );
END BIKE_BFITER;



-- ARCHITECTURE ------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_BFITER IS



-- TYPES -------------------------------------------------------------------------
TYPE BIT_POS_ARRAY IS ARRAY (INTEGER RANGE<>) OF STD_LOGIC_VECTOR(LOG2(B_WIDTH) DOWNTO 0);
TYPE UPC_ARRAY IS ARRAY (INTEGER RANGE<>) OF STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0);



-- SIGNALS -----------------------------------------------------------------------
-- Counter
SIGNAL CNT_CTR_DONE                 : STD_LOGIC;
SIGNAL CNT_CTR_RST, CNT_CTR_EN      : STD_LOGIC;
SIGNAL CNT_CTR_OUT                  : STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0);

SIGNAL CNT_UPC_RST                  : STD_LOGIC;
SIGNAL CNT_UPC_EN                   : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL CNT_UPC_OUT                  : UPC_ARRAY(0 TO B_WIDTH-1);

SIGNAL CNT_NCOL_DONE                : STD_LOGIC; 
SIGNAL CNT_COL_RST, CNT_COL_EN      : STD_LOGIC;
SIGNAL CNT_NCOL_OUT                 : STD_LOGIC_VECTOR(LOG2(2*WORDS)-1 DOWNTO 0);
SIGNAL CNT_RCOL_OUT                 : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
SIGNAL CNT_ERROR_OUT                : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);

-- Control
SIGNAL CNT_UPC_VALID                : STD_LOGIC;
SIGNAL SECOND_POLY                  : STD_LOGIC;
SIGNAL ADJUST_SYNDROME              : STD_LOGIC;

-- SK
SIGNAL SK_ROW                       : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
SIGNAL SK_ROW_HI                    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL SK_ROW_PRE                   : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
SIGNAL ROW_DEC, ROW_RED, ROW_FIN    : STD_LOGIC_VECTOR(LOG2(R_BITS) DOWNTO 0);
SIGNAL SK_ROW_ADD, SK_BIT           : STD_LOGIC_VECTOR(LOG2(B_WIDTH) DOWNTO 0);
SIGNAL SK_RDEN, SK_WREN             : STD_LOGIC;
SIGNAL READ_FROM_MSB_IN             : STD_LOGIC;
SIGNAL READ_FROM_MSB                : STD_LOGIC;

-- SYNDROME
SIGNAL SYNDROME_INIT_RD             : STD_LOGIC;
SIGNAL SYNDROME_INIT_WR             : STD_LOGIC;
SIGNAL SYNDROME_ADDR_HIGH           : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROME_DIN                 : STD_LOGIC_VECTOR(2*B_WIDTH-1 DOWNTO 0);

-- Error
SIGNAL NEW_E_VEC, NEW_GRAY_VEC      : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL E_RDEN, E_WREN               : STD_LOGIC;
SIGNAL E_DOUT_FLIP, E_DOUT_BG       : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL E_DOUT_PRE                   : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL E0_XOR_BIT, E1_XOR_BIT       : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL E_XOR_BIT, E_IN              : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

-- Black/Gray
SIGNAL BLACK_NEW, GRAY_NEW          : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL BLACK_CHUNK, GRAY_CHUNK      : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL MASK                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL BLACK_DIN, GRAY_DIN          : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL GRAY_RDEN, GRAY_WREN         : STD_LOGIC; 



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_INIT0, S_INIT1, S_CTR_READ_SK_INIT, S_CTR_READ_SK, S_CTR_READ_S, S_CTR_READ_LAST_S, S_CTR_READ_LAST_S2, S_CHECK_TH, S_ERROR_READ, S_ERROR_WRITE, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- BEHAVIORAL --------------------------------------------------------------------
BEGIN

    -- PROCEDURE: CTR ------------------------------------------------------------
    -- used to read the secret key
    CNT_CTR_DONE <= '1' WHEN CNT_CTR_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(W/2-1, LOG2(W/2))) ELSE '0';
    CNT_CTR : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(W/2), MAX_VALUE => W/2-1)
    PORT MAP(CLK => CLK, RST => CNT_CTR_RST, EN => CNT_CTR_EN, CNT_OUT => CNT_CTR_OUT);

    -- count the unsatisfied parity check equations
    UPC_COUNTER : FOR I IN 0 TO B_WIDTH-1 GENERATE
        CNT_UPC : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(W/2), MAX_VALUE => W/2)
        PORT MAP(CLK => CLK, RST => CNT_UPC_RST, EN => CNT_UPC_EN(I), CNT_OUT => CNT_UPC_OUT(I));
    END GENERATE;
    
    -- indicates whether the computation is in the first polynomial or in the second
    SECOND_POLY <= '1' WHEN CNT_NCOL_OUT >= STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS, LOG2(2*WORDS))) ELSE '0';
    
    -- counts the total number of columns already checked
    CNT_NCOL_DONE <= '1' WHEN CNT_NCOL_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2*WORDS-1, LOG2(2*WORDS))) ELSE '0';
    CNT_NCOL : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(2*WORDS), MAX_VALUE => 2*WORDS)
    PORT MAP(CLK => CLK, RST => CNT_COL_RST, EN => CNT_COL_EN, CNT_OUT => CNT_NCOL_OUT);
    
    -- counter for the error polynomial
    CNT_ERROR : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS-1)
    PORT MAP(CLK => CLK, RST => CNT_COL_RST, EN => CNT_COL_EN, CNT_OUT => CNT_ERROR_OUT);
        
    -- addresses
    SK_ADDR <= (LOG2(R_BLOCKS)-1 DOWNTO LOG2(W/2) => '0') & CNT_CTR_OUT;
    
    -- we need 2*B_WIDTH bits of the syndrome
    SYNDROME_A_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) WHEN SYNDROME_INIT_RD = '1' OR SYNDROME_INIT_WR = '1' ELSE SK_ROW(LOG2(WORDS)-1+LOG2(B_WIDTH) DOWNTO LOG2(B_WIDTH)); 
    SYNDROME_ADDR_HIGH <= STD_LOGIC_VECTOR(UNSIGNED(SK_ROW(LOG2(WORDS)-1+LOG2(B_WIDTH) DOWNTO LOG2(B_WIDTH))) + 1);
    SYNDROME_B_ADDR <= (LOG2(WORDS)-1 DOWNTO 0 => '0') WHEN SYNDROME_INIT_RD = '1' ELSE STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) WHEN SYNDROME_INIT_WR = '1' ELSE (OTHERS => '0') WHEN UNSIGNED(SYNDROME_ADDR_HIGH) = TO_UNSIGNED(WORDS, LOG2(WORDS)) ELSE SYNDROME_ADDR_HIGH;
    
    -- just needed in the initial phase to copy the LSBs to the most significant chunk of the syndrome polynomials
    -- As an example for R_BITS=59 and B_WIDTH=8:
    -- |0 0 0 0 0 s58 s57 s56 | ... | ... | s7 s6 s5 s4 s3 s2 s1 s0 | -> |s4 s3 s2 s1 s0 s58 s57 s56 | ... | ... | s7 s6 s5 s4 s3 s2 s1 s0 |
    SYNDROME_A_DOUT <= SYNDROME_B_DIN(B_WIDTH-OVERHANG-1 DOWNTO 0) & SYNDROME_A_DIN(OVERHANG-1 DOWNTO 0);   
    SYNDROME_B_DOUT <= SYNDROME_B_DIN(B_WIDTH-OVERHANG-1 DOWNTO 0) & SYNDROME_A_DIN(OVERHANG-1 DOWNTO 0); 
    
    READ_FROM_MSB_IN <= '1' WHEN UNSIGNED(SK_ROW(LOG2(WORDS)-1+LOG2(B_WIDTH) DOWNTO LOG2(B_WIDTH))) = (WORDS-1) ELSE '0';
    ID_MSB_ADDR : FDRE GENERIC MAP (INIT => '0')
    PORT MAP(Q => READ_FROM_MSB, C => CLK, CE => ENABLE, R => RESET, D => READ_FROM_MSB_IN);
    
    -- count when the corresponing bit in the syndrome is set
    SYNDROME_DIN <= (2*B_WIDTH-1 DOWNTO OVERHANG+B_WIDTH => '0') & SYNDROME_B_DIN & SYNDROME_A_DIN(OVERHANG-1 DOWNTO 0) WHEN READ_FROM_MSB = '1' ELSE SYNDROME_B_DIN & SYNDROME_A_DIN;
    
    UPC_EN : FOR I IN 0 TO B_WIDTH-1 GENERATE
        CNT_UPC_EN(I)  <= '1' WHEN SYNDROME_DIN(TO_INTEGER(UNSIGNED(SK_BIT)+TO_UNSIGNED(I, B_WIDTH+1))) = '1' AND CNT_UPC_VALID = '1' ELSE '0';
    END GENERATE;
    
    SK_ROW  <= SK0_DIN(LOG2(R_BITS)-1 DOWNTO  0) WHEN SECOND_POLY = '0' ELSE SK1_DIN(LOG2(R_BITS)-1 DOWNTO  0);
    SK_ROW_HI <= SK0_DIN(31 DOWNTO  16) WHEN SECOND_POLY = '0' ELSE SK1_DIN(31 DOWNTO 16);  

    SK_ROW_ADD <= '0' & SK_ROW(LOG2(B_WIDTH)-1 DOWNTO 0);
    
    SK_REG : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => LOG2(B_WIDTH)+1)
    PORT MAP (CLK => CLK, EN => ENABLE, RST => RESET, D => SK_ROW_ADD, Q => SK_BIT);
            

    -- outputs for secret key
    SK0_RDEN <= SK_RDEN WHEN SECOND_POLY = '0' ELSE '0';
    SK1_RDEN <= SK_RDEN WHEN SECOND_POLY = '1' ELSE '0';
    
    SK0_WREN <= SK_WREN WHEN SECOND_POLY = '0' ELSE '0';
    SK1_WREN <= SK_WREN WHEN SECOND_POLY = '1' ELSE '0';
    
    -- increase key by B_WIDTH for the next iteration
    ROW_DEC <= STD_LOGIC_VECTOR(UNSIGNED('0' & SK_ROW) + TO_UNSIGNED(B_WIDTH, LOG2(R_BITS)+1));
    ROW_RED <= STD_LOGIC_VECTOR(UNSIGNED(ROW_DEC) - TO_UNSIGNED(R_BITS, LOG2(R_BITS)+1));
    ROW_FIN <= ROW_DEC WHEN ROW_RED(LOG2(R_BITS)) = '1' ELSE ROW_RED;
    
    -- if we are checking the last chunk of a polynomial, we have to reset the key to the original one
    -- when reading and storing the key, we duplicate it and store it the bits 31:16 - working bits are 15:0
    SK_DOUT <= SK_ROW_HI & SK_ROW_HI WHEN UNSIGNED(CNT_NCOL_OUT) = WORDS-1 OR CNT_NCOL_DONE = '1' ELSE SK_ROW_HI & (15 DOWNTO LOG2(R_BITS) => '0') & ROW_FIN(LOG2(R_BITS)-1 DOWNTO 0);
    ------------------------------------------------------------------------------
    
    
    -- FLIP ERROR ----------------------------------------------------------------
    E0_RDEN <= E_RDEN WHEN SECOND_POLY = '0' ELSE '0';
    E1_RDEN <= E_RDEN WHEN SECOND_POLY = '1' ELSE '0';
    
    E0_WREN <= E_WREN WHEN SECOND_POLY = '0' ELSE '0';
    E1_WREN <= E_WREN WHEN SECOND_POLY = '1' ELSE '0';
    
    E_ADDR      <= CNT_ERROR_OUT;
    
    -- ERROR OUT - SPECIAL CASE FOR MOST SIGNIFICANT CHUNK -----------------------
    E_DOUT_PRE  <= E_DOUT_FLIP WHEN MODE_SEL = "00" OR MODE_SEL = "11" ELSE E_DOUT_BG;
    E_DOUT      <= (B_WIDTH-1 DOWNTO OVERHANG => '0') & E_DOUT_PRE(OVERHANG-1 DOWNTO 0) WHEN CNT_ERROR_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) ELSE E_DOUT_PRE;
    
    E_IN        <= E0_DIN WHEN SECOND_POLY = '0' ELSE E1_DIN;
    E_XOR_BIT   <= E_IN XOR NEW_E_VEC;
    E_DOUT_FLIP <= E_XOR_BIT;
    
    E_CHUNK_BG : FOR I IN 0 TO B_WIDTH-1 GENERATE
        E_DOUT_BG(I)   <= E_XOR_BIT(I) WHEN MASK(I) = '1' ELSE E_IN(I);
    END GENERATE;
    
    -- select black/gray mask
    WITH MODE_SEL SELECT MASK <=
        BLACK_DIN       WHEN "01",
        GRAY_DIN        WHEN "10",
        (OTHERS => '0') WHEN OTHERS;
    
    -- determine new chunk for error vector
    E_CHUNK : FOR I IN 0 TO B_WIDTH-1 GENERATE
        NEW_E_VEC(I)    <= '1' WHEN CNT_UPC_OUT(I) >= TH ELSE '0';
        NEW_GRAY_VEC(I) <= '1' WHEN CNT_UPC_OUT(I) >= STD_LOGIC_VECTOR(UNSIGNED(TH) - TAU) AND CNT_UPC_OUT(I) < TH ELSE '0';
    END GENERATE;
    
    
    -- BLACK LIST
    BLACK0_RDEN <= E_RDEN WHEN SECOND_POLY = '0' AND (MODE_SEL = "00" OR MODE_SEL = "01") ELSE '0';
    BLACK1_RDEN <= E_RDEN WHEN SECOND_POLY = '1' AND (MODE_SEL = "00" OR MODE_SEL = "01") ELSE '0';
    
    BLACK0_WREN <= E_WREN WHEN SECOND_POLY = '0' AND MODE_SEL = "00" ELSE '0';
    BLACK1_WREN <= E_WREN WHEN SECOND_POLY = '1' AND MODE_SEL = "00" ELSE '0';
    
    BLACK_ADDR  <= CNT_ERROR_OUT; 
    BLACK_DOUT  <= NEW_E_VEC WHEN MODE_SEL = "00" ELSE (OTHERS => '0');
    BLACK_DIN   <= BLACK0_DIN WHEN SECOND_POLY = '0' ELSE BLACK1_DIN;
    
    -- GRAY LIST
    GRAY0_RDEN <= E_RDEN WHEN SECOND_POLY = '0' AND MODE_SEL = "00" ELSE E_RDEN WHEN SECOND_POLY = '0' AND MODE_SEL = "10" ELSE '0';
    GRAY1_RDEN <= E_RDEN WHEN SECOND_POLY = '1' AND MODE_SEL = "00" ELSE E_RDEN WHEN SECOND_POLY = '1' AND MODE_SEL = "10" ELSE '0';
    
    GRAY0_WREN <= E_WREN WHEN SECOND_POLY = '0' AND MODE_SEL = "00" ELSE '0';
    GRAY1_WREN <= E_WREN WHEN SECOND_POLY = '1' AND MODE_SEL = "00" ELSE '0';
        
    GRAY_ADDR  <= CNT_ERROR_OUT; 
    GRAY_DOUT  <= NEW_GRAY_VEC WHEN MODE_SEL = "00" ELSE (OTHERS => '0');
    GRAY_DIN   <= GRAY0_DIN WHEN SECOND_POLY = '0' ELSE GRAY1_DIN;
    ------------------------------------------------------------------------------
    
    
    -- FSM -----------------------------------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            -- GLOBAL ----------
            DONE                <= '0';
            
            -- COUNTER ---------
            CNT_CTR_RST         <= '1';
            CNT_CTR_EN          <= '0';

            CNT_UPC_RST         <= '1';
            
            CNT_COL_RST         <= '1';
            CNT_COL_EN          <= '0';
            
            -- CONTROL ---------
            CNT_UPC_VALID       <= '0';
            
            -- SYNDROM ---------
            SYNDROME_RDEN       <= '0';
            SYNDROME_WREN       <= '0';
            SYNDROME_INIT_RD    <= '0';
            SYNDROME_INIT_WR    <= '0';
                       
            -- SECRET KEY ------  
            SK_RDEN             <= '0';
            SK_WREN             <= '0';                

            -- ERROR -----------
            E_RDEN              <= '0';  
            E_WREN              <= '0'; 
            
            -- GRAY ------------
            GRAY_RDEN           <= '0';
            GRAY_WREN           <= '0';
            
            IF RESET = '1' THEN
                STATE <= S_RESET;            
            ELSE
                CASE STATE IS
                    
                    ----------------------------------------------
                    WHEN S_RESET            =>                                                                                    
                        -- TRANSITION ------
                        IF (ENABLE = '1') THEN
                            STATE           <= S_INIT0;
                        ELSE
                            STATE           <= S_RESET;
                        END IF;
                    ----------------------------------------------

                    ----------------------------------------------
                    WHEN S_INIT0            =>
                        -- SYNDROM ---------
                        SYNDROME_RDEN       <= '1';
                        
                        SYNDROME_INIT_RD    <= '1';
                                                                                                                            
                        -- TRANSITION ------
                        STATE               <= S_INIT1;
                    ----------------------------------------------

                    ----------------------------------------------
                    WHEN S_INIT1            =>
                        -- SYNDROM ---------
                        SYNDROME_RDEN       <= '1';
                        SYNDROME_WREN       <= '1';

                        SYNDROME_INIT_WR    <= '1';
                                                                                                                            
                        -- TRANSITION ------
                        STATE               <= S_CTR_READ_SK_INIT;
                    ----------------------------------------------
                                            
                    ----------------------------------------------
                    WHEN S_CTR_READ_SK_INIT  =>
                        -- COUNTER ---------
                        CNT_CTR_RST         <= '0';
                        CNT_CTR_EN          <= '1';
                        
                        CNT_UPC_RST         <= '1';
    
                        CNT_COL_RST         <= '0';
                                                       
                        -- SECRET KEY ------  
                        SK_RDEN             <= '1';
                        SK_WREN             <= '0';  
                                                                                                                            
                        -- TRANSITION ------
                        IF CNT_NCOL_DONE = '1' THEN
                            STATE           <= S_DONE;
                        ELSE
                            STATE           <= S_CTR_READ_SK;
                        END IF;
                    ----------------------------------------------
                    
                    ----------------------------------------------
                    WHEN S_CTR_READ_SK      =>
                        -- COUNTER ---------
                        CNT_CTR_RST         <= '0';
                        CNT_CTR_EN          <= '1';
    
                        CNT_UPC_RST         <= '0';
    
                        CNT_COL_RST         <= '0';

                        -- SYNDROM ---------
                        SYNDROME_RDEN       <= '1';
                                                       
                        -- SECRET KEY ------  
                        SK_RDEN             <= '1';
                        SK_WREN             <= '1';     
                                                                                                                            
                        -- TRANSITION ------
                        STATE               <= S_CTR_READ_S;
                    ----------------------------------------------
    
                    ----------------------------------------------
                    WHEN S_CTR_READ_S      =>
                        -- COUNTER ---------
                        CNT_CTR_RST         <= '0';
                        CNT_CTR_EN          <= '1';
    
                        CNT_UPC_RST         <= '0';
    
                        CNT_COL_RST         <= '0';
                        
                        -- CONTROL ---------
                        CNT_UPC_VALID       <= '1';
                        
                        -- SYNDROM ---------
                        SYNDROME_RDEN       <= '1';
                                                       
                        -- SECRET KEY ------  
                        SK_RDEN             <= '1';
                        SK_WREN             <= '1';    
                                                                                                                            
                        -- TRANSITION ------
                        IF CNT_CTR_DONE = '1' THEN
                            STATE           <= S_CTR_READ_LAST_S;
                        ELSE
                            STATE           <= S_CTR_READ_S;
                        END IF;
                    ----------------------------------------------
    
                    ----------------------------------------------
                    WHEN S_CTR_READ_LAST_S      =>
                        -- COUNTER ---------
                        CNT_UPC_RST         <= '0';
    
                        CNT_COL_RST         <= '0';
                        
                        -- CONTROL ---------
                        CNT_UPC_VALID       <= '1';
                        
                        -- SYNDROM ---------
                        SYNDROME_RDEN       <= '1';
                                                                                                                            
                        -- TRANSITION ------
                        STATE               <= S_CTR_READ_LAST_S2;
                    ----------------------------------------------
    
                    ----------------------------------------------
                    WHEN S_CTR_READ_LAST_S2      =>
                        -- COUNTER ---------
                        CNT_UPC_RST         <= '0';
        
                        CNT_COL_RST         <= '0';
                        
                        -- SYNDROM ---------
                        SYNDROME_RDEN       <= '0';  
                                                                                                                            
                        -- TRANSITION ------
                        STATE               <= S_CHECK_TH;
                    ----------------------------------------------
                                    
                    ----------------------------------------------
                    WHEN S_CHECK_TH         =>
                        -- GLOBAL ----------
                        DONE                <= '0';
                        
                        -- COUNTER ---------    
                        CNT_UPC_RST         <= '0';
    
                        CNT_COL_RST         <= '0';
                        
                                                                  
                        -- TRANSITION ------    
                        STATE               <= S_ERROR_READ;
                    ----------------------------------------------
    
                    ----------------------------------------------
                    WHEN S_ERROR_READ  =>
                        -- COUNTER ---------
                        CNT_COL_RST         <= '0';
                        CNT_COL_EN          <= '0';
    
                        -- CONTROL ---------
                        CNT_UPC_VALID       <= '0';
                        
                        -- COUNTER ---------    
                        CNT_UPC_RST         <= '0';
                        
                        -- ERROR -----------
                        E_RDEN              <= '1';  
                        E_WREN              <= '0';  

                                                                                                        
                        -- TRANSITION ------
                        STATE               <= S_ERROR_WRITE;
                    ----------------------------------------------
    
                    ----------------------------------------------
                    WHEN S_ERROR_WRITE  =>  
                        -- COUNTER ---------
                        CNT_COL_RST         <= '0';
                        CNT_COL_EN          <= '1';

                        -- ERROR -----------
                        E_RDEN              <= '1';  
                        E_WREN              <= '1';  
                        
                        -- COUNTER ---------    
                        CNT_UPC_RST         <= '0';

                                                                                                        
                        -- TRANSITION ------
                        STATE               <= S_CTR_READ_SK_INIT;
                    ----------------------------------------------
                                                                                                                    
                    ----------------------------------------------
                    WHEN S_DONE             =>
                        -- GLOBAL ----------
                        DONE                <= '1';
                                                                                    
                        -- TRANSITION ------
                        STATE               <= S_RESET;
                    ----------------------------------------------
                                                                                    
                END CASE;
            END IF;
        END IF;
    END PROCESS;    
    ------------------------------------------------------------------------------
    
END Behavioral;
