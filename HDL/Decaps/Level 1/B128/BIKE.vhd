----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    23/04/2020
-- LAST CHANGES:            23/04/2020
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
END BIKE;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE IS 



-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_REGH_EN, CNT_REGH_RST                    : STD_LOGIC;
SIGNAL CNT_REGH_EN_GATED                            : STD_LOGIC;
SIGNAL CNT_REGH_OUT                                 : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0);

SIGNAL CNT_REG_EN, CNT_REG_RESET                    : STD_LOGIC;
SIGNAL CNT_REG_OUT                                  : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0);

SIGNAL CNT_HWTH_EN, CNT_HWTH_RST, CNT_HWTH_DONE     : STD_LOGIC;
SIGNAL CNT_HWTH_OUT                                 : STD_LOGIC_VECTOR(LOG2(LOG2(B_WIDTH)+2)-1 DOWNTO 0);

SIGNAL CNT_HW_EN, CNT_HW_RST, CNT_HW_DONE           : STD_LOGIC;
SIGNAL CNT_HW_OUT                                   : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);

SIGNAL CNT_NBITER_EN, CNT_NBITER_RST                : STD_LOGIC;
SIGNAL CNT_NBITER_DONE                              : STD_LOGIC;
SIGNAL CNT_NBITER_OUT                               : STD_LOGIC_VECTOR(LOG2(NbIter+1)-1 DOWNTO 0);

SIGNAL CNT_COMPE_EN, CNT_COMPE_RST, CNT_COMPE_DONE  : STD_LOGIC;
SIGNAL CNT_COMPE_OUT                                : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);


-- C0
SIGNAL C0_SAMP_SAMPLING                             : STD_LOGIC;
SIGNAL C0_SAMP_WREN, C0_SAMP_RDEN                   : STD_LOGIC;
SIGNAL C0_SAMP_ADDR                                 : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL C0_SAMP_DIN, C0_SAMP_DOUT                    : STD_LOGIC_VECTOR(31 DOWNTO 0);

-- REGISTER
SIGNAL H_REG_OUT                                    : WORD_ARRAY(7 DOWNTO 0);
SIGNAL H_REG_EN                                     : STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL M_REG_IN                                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL M_REG_OUT                                    : WORD_ARRAY(7 DOWNTO 0);
SIGNAL M_REG_EN                                     : STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL C1_REG_IN                                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL C1_REG_OUT                                   : WORD_ARRAY(7 DOWNTO 0);
SIGNAL C1_REG_EN                                    : STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL SIGMA_REG_IN                                 : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SIGMA_REG_OUT                                : WORD_ARRAY(7 DOWNTO 0);
SIGNAL SIGMA_REG_EN                                 : STD_LOGIC_VECTOR(7 DOWNTO 0);


-- SAMPLE ERROR
SIGNAL ERROR_SAMPLE_EN, ERROR_SAMPLE_DONE           : STD_LOGIC;

SIGNAL E0P_SAMPLE_RDEN, E0P_SAMPLE_WREN             : STD_LOGIC;
SIGNAL E1P_SAMPLE_RDEN, E1P_SAMPLE_WREN             : STD_LOGIC;
SIGNAL EP_SAMPLE_ADDR                               : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL EP_SAMPLE_DOUT                               : STD_LOGIC_VECTOR(31 DOWNTO 0);


-- ERROR PRIME PRIME
SIGNAL ERRORPP_SEL                                  : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL E0PP_RDEN, E0PP_WREN                         : STD_LOGIC;
SIGNAL E1PP_RDEN, E1PP_WREN                         : STD_LOGIC;
SIGNAL E0PP_ADDR, E1PP_ADDR                         : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL E0PP_DOUT, E1PP_DOUT                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL E0PP_DIN, E1PP_DIN                           : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


SIGNAL AES_KEY                                      : STD_LOGIC_VECTOR(255 DOWNTO 0);


-- CRYPTOGRAM
SIGNAL C0_WREN, C0_RDEN                             : STD_LOGIC;
SIGNAL C0_ADDR                                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL C0_DIN, C0_DOUT                              : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- SECRETE KEY
SIGNAL SK0_WREN, SK1_WREN                           : STD_LOGIC;
SIGNAL SK0_RDEN, SK1_RDEN                           : STD_LOGIC;
SIGNAL SK0_ADDR, SK1_ADDR                           : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SK0_DIN, SK1_DIN                             : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SK0_DOUT, SK1_DOUT                           : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SK_COMPACT_SAMPLING                          : STD_LOGIC;
SIGNAL SK0_COMPACT_WREN, SK1_COMPACT_WREN           : STD_LOGIC;
SIGNAL SK0_COMPACT_RDEN, SK1_COMPACT_RDEN           : STD_LOGIC;
SIGNAL SK0_COMPACT_ADDR, SK1_COMPACT_ADDR           : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL SK0_COMPACT_DIN, SK1_COMPACT_DIN             : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SK0_COMPACT_DOUT, SK1_COMPACT_DOUT           : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SK0_COMPACT_BRAM_DIN, SK1_COMPACT_BRAM_DIN   : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SK0_COMPACT_TRANS_DIN, SK1_COMPACT_TRANS_DIN : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);


-- SYNDROME
SIGNAL SYNDROME_SEL                                 : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL SNYDROME_SAMPLING                            : STD_LOGIC;
SIGNAL SYNDROME_A_WREN, SYNDROME_A_RDEN             : STD_LOGIC;
SIGNAL SYNDROME_A_ADDR                              : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROME_A_DIN, SYNDROME_A_DOUT              : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SYNDROME_B_WREN, SYNDROME_B_RDEN             : STD_LOGIC;
SIGNAL SYNDROME_B_ADDR                              : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROME_B_DIN, SYNDROME_B_DOUT              : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SYNDROME_INIT_WREN, SYNDROME_INIT_RDEN       : STD_LOGIC;
SIGNAL SYNDROME_INIT_ADDR                           : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROME_INIT_DIN, SYNDROME_INIT_DOUT        : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- MULTIPLICATION
SIGNAL MUL_ENABLE, MUL_RESET, MUL_DONE, MUL_VALID   : STD_LOGIC;
SIGNAL MUL_SEL                                      : STD_LOGIC;
SIGNAL SK_MUL_WREN, SK_MUL_RDEN                     : STD_LOGIC;
SIGNAL SK_MUL_ADDR                                  : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SK0_MUL_DOUT, SK1_MUL_DOUT                   : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SYNDROME_MUL_WREN, SYNDROME_MUL_RDEN         : STD_LOGIC;
SIGNAL SYNDROME_MUL_ADDR                            : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROME_MUL_DOUT, SYNDROME_MUL_DIN          : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL MUL_VEC_RDEN                                 : STD_LOGIC;
SIGNAL MUL_VEC_ADDR                                 : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL MUL_VEC0_DIN, MUL_VEC1_DIN                   : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL MUL_FIRST_COL                                : STD_LOGIC;


-- TRANSPOSITION
SIGNAL TRANSPOSE_ENABLE, TRANSPOSE_RESET            : STD_LOGIC;
SIGNAL TRANSPOSE_DONE                               : STD_LOGIC;
SIGNAL SYNDROMEA_TRANS_RDEN, SYNDROMEA_TRANS_WREN   : STD_LOGIC;
SIGNAL SYNDROMEA_TRANS_ADDR                         : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROMEA_TRANS_DOUT                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SYNDROMEB_TRANS_RDEN, SYNDROMEB_TRANS_WREN   : STD_LOGIC;
SIGNAL SYNDROMEB_TRANS_ADDR                         : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROMEB_TRANS_DOUT                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- HAMMING WEIGHT
SIGNAL HW_SEL                                       : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL HW_RST, HW_EN, HW_EN_D                       : STD_LOGIC;
SIGNAL HW_DIN, HW_MUL_DIN, HW_BFITER_DIN            : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL HW_DOUT                                      : STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0);
SIGNAL DECODER_RES_EN, DECODER_RES_RST              : STD_LOGIC;
SIGNAL DECODER_RES_IN, DECODER_RES_OUT              : STD_LOGIC;
SIGNAL HW_COMPARE_RST, HW_COMPARE_EN                : STD_LOGIC; 
SIGNAL HW_COMPARE_OUT                               : STD_LOGIC; 
SIGNAL HW_COMPE_DIN                                 : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL HW_E_IN, HW_E_OUT, HW_CHECK_E                : STD_LOGIC;


-- THRESHOLD
SIGNAL TH_EN                                        : STD_LOGIC;
SIGNAL TH_DIN                                       : STD_LOGIC_VECTOR(LOG2(R_BITS)-1 DOWNTO 0);
SIGNAL TH_DOUT                                      : STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0);


-- BFITER
SIGNAL BFITER_EN, BFITER_RST, BFITER_DONE           : STD_LOGIC;
SIGNAL BFITER_SEL                                   : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL TH_BFITER_IN                                 : STD_LOGIC_VECTOR(LOG2(W/2)-1 DOWNTO 0);
SIGNAL SK0_BFITER_RDEN, SK1_BFITER_RDEN             : STD_LOGIC;
SIGNAL SK0_BFITER_WREN, SK1_BFITER_WREN             : STD_LOGIC;
SIGNAL SK_BFITER_ADDR                               : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL SK_BFITER_DOUT                               : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL E0_BFITER_RDEN, E1_BFITER_RDEN               : STD_LOGIC;
SIGNAL E0_BFITER_WREN, E1_BFITER_WREN               : STD_LOGIC;
SIGNAL E_BFITER_ADDR                                : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL E_BFITER_DOUT                                : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

SIGNAL BLACK0_BFITER_RDEN, BLACK1_BFITER_RDEN       : STD_LOGIC;
SIGNAL BLACK0_BFITER_WREN, BLACK1_BFITER_WREN       : STD_LOGIC;
SIGNAL BLACK_BFITER_ADDR                            : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL BLACK_BFITER_DOUT                            : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);

SIGNAL GRAY0_BFITER_RDEN, GRAY1_BFITER_RDEN         : STD_LOGIC;
SIGNAL GRAY0_BFITER_WREN, GRAY1_BFITER_WREN         : STD_LOGIC;
SIGNAL GRAY_BFITER_ADDR                             : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL GRAY_BFITER_DOUT                             : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- BLACK
SIGNAL BLACK_SAMPLE_EN                              : STD_LOGIC;
SIGNAL BLACK0_RDEN, BLACK1_RDEN                     : STD_LOGIC;
SIGNAL BLACK0_WREN, BLACK1_WREN                     : STD_LOGIC;
SIGNAL BLACK0_ADDR, BLACK1_ADDR                     : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL BLACK0_DOUT, BLACK1_DOUT                     : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL BLACK0_DIN, BLACK1_DIN                       : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- GRAY
SIGNAL GRAY_SAMPLE_EN                               : STD_LOGIC;
SIGNAL GRAY0_RDEN, GRAY1_RDEN                       : STD_LOGIC;
SIGNAL GRAY0_WREN, GRAY1_WREN                       : STD_LOGIC;
SIGNAL GRAY0_ADDR, GRAY1_ADDR                       : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL GRAY0_DOUT, GRAY1_DOUT                       : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL GRAY0_DIN, GRAY1_DIN                         : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- E CONTROL
SIGNAL ECONTROL_SAMPLE_EN, ECONTROL_SAMPLE_DONE     : STD_LOGIC;
SIGNAL E0CONTROL_SAMPLE_RDEN, E0CONTROL_SAMPLE_WREN : STD_LOGIC;
SIGNAL E1CONTROL_SAMPLE_RDEN, E1CONTROL_SAMPLE_WREN : STD_LOGIC;
SIGNAL ECONTROL_SAMPLE_ADDR                         : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL ECONTROL_SAMPLE_DOUT                         : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL E0CONTROL_SAMPLE_DIN, E1CONTROL_SAMPLE_DIN   : STD_LOGIC_VECTOR(31 DOWNTO 0);


SIGNAL E0_COMPE_RDEN, E1_COMPE_RDEN                 : STD_LOGIC;
SIGNAL SEL_COMP_ERROR_POLY                          : STD_LOGIC;
SIGNAL COMPE_DINA, COMPE_DINB, COMPE_AND            : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- UPC
SIGNAL SYNDROME_UPC_RDEN, SYNDROME_UPC_WREN         : STD_LOGIC;
SIGNAL SYNDROME_UPC_A_ADDR, SYNDROME_UPC_B_ADDR     : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL SYNDROME_UPC_DOUT, SYNDROME_UPC_DIN          : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL SYNDROME_A_UPC_DOUT, SYNDROME_B_UPC_DOUT     : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- RANDOM ORACLES
SIGNAL HASH_SELECTION                               : STD_LOGIC_VECTOR(1 DOWNTO 0);

SIGNAL ERROR0_HASH_RDEN, ERROR1_HASH_RDEN           : STD_LOGIC;
SIGNAL ERROR0_HASH_ADDR, ERROR1_HASH_ADDR           : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

SIGNAL C0_HASH_RDEN                                 : STD_LOGIC;
SIGNAL C0_HASH_ADDR                                 : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

SIGNAL HASH_H_EN, HASH_H_VALID                      : STD_LOGIC;
SIGNAL HASH_H_M                                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL HASH_L_EN, HASH_L_RDY, HASH_L_VALID          : STD_LOGIC;
SIGNAL HASH_L_M                                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL HASH_K_EN, HASH_K_RDY, HASH_K_VALID          : STD_LOGIC;
SIGNAL HASH_K_M                                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL MESSAGE_K_IN                                 : WORD_ARRAY(7 DOWNTO 0);


-- SHA
SIGNAL SHA_ENABLE, SHA_RESET, SHA_DONE              : STD_LOGIC;
SIGNAL SHA_M_RDY, SHA_M_VALID, SHA_HASH_VALID       : STD_LOGIC;
SIGNAL SHA_M, SHA_HASH                              : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SHA_HASH_ADDR                                : STD_LOGIC_VECTOR( 2 DOWNTO 0);
SIGNAL HASH_SIZE                                    : STD_LOGIC_VECTOR(19 DOWNTO 0);


-- COMPARISON
SIGNAL E0_SAMPLED_DOUT, E1_SAMPLED_DOUT             : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
SIGNAL E0_DECODE_DOUT, E1_DECODE_DOUT               : STD_LOGIC_VECTOR(31 DOWNTO 0);


-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_COMPUTE_SYNDROME, S_RECOMPUTE_SYNDROME, S_HW_TH, S_BFITER_BG, S_BFITER_BLACK, S_BFITER_GRAY, S_BFITER, S_HAMMING_WEIGHT, S_HASH_L, S_SAMPLE_E, S_COMPARE_E0, S_COMPARE_E1, S_COMPARE_HW, S_HASH_K, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN   
    
    -- CRYPTOGRAM ----------------------------------------------------------------
    -- recieve cryptogram c0
    C0_SAMP_SAMPLING    <= '1' WHEN HASH_K_EN = '1' ELSE C0_IN_VALID;
    C0_SAMP_RDEN        <= C0_HASH_RDEN WHEN HASH_K_EN = '1' ELSE C0_IN_VALID;
    C0_SAMP_WREN        <= '0' WHEN HASH_K_EN = '1' ELSE C0_IN_VALID;
    C0_SAMP_ADDR        <= C0_HASH_ADDR WHEN HASH_K_EN = '1' ELSE C_IN_ADDR;
    C0_SAMP_DIN         <= (OTHERS => '0') WHEN HASH_K_EN = '1' ELSE C_IN_DIN;
    
    C0_RDEN <= MUL_VEC_RDEN;
    C0_ADDR <= MUL_VEC_ADDR;
    
    BRAM_C0 : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 1)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => C0_SAMP_SAMPLING,
        -- SAMPLING --------------------
        REN_SAMP        => C0_SAMP_RDEN,
        WEN_SAMP        => C0_SAMP_WREN,
        ADDR_SAMP       => C0_SAMP_ADDR,
        DOUT_SAMP       => C0_SAMP_DOUT,
        DIN_SAMP        => C0_SAMP_DIN,
        -- COMPUTATION -----------------
        WEN             => '0',
        REN             => C0_RDEN,
        ADDR            => C0_ADDR,
        DOUT            => C0_DOUT,
        DIN             => (OTHERS => '0')
    );
    
    -- Set enable signals for register banks
    EN_REG : FOR I IN 0 TO 7 GENERATE
    BEGIN
        C1_REG_EN(I)    <= C1_IN_VALID WHEN C_IN_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(I, LOG2(R_BLOCKS))) ELSE '0';
        M_REG_EN(I)     <= SHA_HASH_VALID AND HASH_L_EN WHEN SHA_HASH_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(I, LOG2(CEIL(L,32)))) ELSE '0';
        SIGMA_REG_EN(I) <= SIGMA_IN_VALID WHEN SIGMA_IN_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(I, LOG2(CEIL(L,32)))) ELSE '0';
    END GENERATE;
    
    -- recieve cryptogram C1
    C1_REG_IN <= C_IN_DIN;   
    REG_C1 : ENTITY work.BIKE_REG_BANK GENERIC MAP(SIZE => 8)
    PORT MAP(CLK => CLK, RST => RESET, EN => C1_REG_EN, DIN => C1_REG_IN, DOUT => C1_REG_OUT);  
    
    -- message
    M_REG_IN <= C1_REG_OUT(TO_INTEGER(UNSIGNED(SHA_HASH_ADDR))) XOR SHA_HASH;
    REG_M : ENTITY work.BIKE_REG_BANK GENERIC MAP(SIZE => 8)
    PORT MAP(CLK => CLK, RST => RESET, EN => M_REG_EN, DIN => M_REG_IN, DOUT => M_REG_OUT);
    
    -- sigma
    SIGMA_REG_IN <= SIGMA_IN_DIN WHEN SIGMA_IN_VALID = '1' ELSE (OTHERS => '0');
    REG_SIGMA : ENTITY work.BIKE_REG_BANK GENERIC MAP(SIZE => 8)
    PORT MAP(CLK => CLK, RST => RESET, EN => SIGMA_REG_EN, DIN => SIGMA_REG_IN, DOUT => SIGMA_REG_OUT);
    ------------------------------------------------------------------------------   
    
    
    -- SECRET KEY ----------------------------------------------------------------
    BRAM_SK : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 0
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => SK_IN_VALID,
        -- SAMPLING --------------------
        REN0_SAMP       => SK_IN_VALID,
        REN1_SAMP       => SK_IN_VALID,
        WEN0_SAMP       => SK_IN_VALID,
        WEN1_SAMP       => SK_IN_VALID,
        ADDR0_SAMP      => SK_IN_ADDR,
        ADDR1_SAMP      => SK_IN_ADDR,
        DOUT0_SAMP      => OPEN,
        DOUT1_SAMP      => OPEN,
        DIN0_SAMP       => SK0_IN_DIN,
        DIN1_SAMP       => SK1_IN_DIN,
        -- COMPUTATION -----------------
        WEN0            => SK_MUL_WREN,
        WEN1            => SK_MUL_WREN,
        REN0            => SK_MUL_RDEN,
        REN1            => SK_MUL_RDEN,
        ADDR0           => SK_MUL_ADDR,
        ADDR1           => SK_MUL_ADDR,
        DOUT0           => SK0_DOUT,
        DOUT1           => SK1_DOUT,
        DIN0            => SK0_MUL_DOUT,
        DIN1            => SK1_MUL_DOUT
    );
    
    -- the decoder can be realized more efficient when using the secret key in its compact representation    
    SK0_COMPACT_RDEN <= SK_COMPACT_IN_VALID WHEN SK_COMPACT_IN_VALID = '1' ELSE SK0_BFITER_RDEN;
    SK1_COMPACT_RDEN <= SK_COMPACT_IN_VALID WHEN SK_COMPACT_IN_VALID = '1' ELSE SK1_BFITER_RDEN;

    SK0_COMPACT_WREN <= SK_COMPACT_IN_VALID WHEN SK_COMPACT_IN_VALID = '1' ELSE SK0_BFITER_WREN;
    SK1_COMPACT_WREN <= SK_COMPACT_IN_VALID WHEN SK_COMPACT_IN_VALID = '1' ELSE SK1_BFITER_WREN;
    
    SK0_COMPACT_ADDR <= SK_COMPACT_IN_ADDR  WHEN SK_COMPACT_IN_VALID = '1' ELSE SK_BFITER_ADDR;
    SK1_COMPACT_ADDR <= SK_COMPACT_IN_ADDR  WHEN SK_COMPACT_IN_VALID = '1' ELSE SK_BFITER_ADDR;
    
    -- we store the secret key two times - in the bits 31:16 and in the bits 15:0
    -- the lower 16 bits are used as "working bits" and the upper 16 bits are used to restore the original key
    -- if R_BITS > 2^16-1 this needs to be adapted and a larger BRAM must be used
    SK0_COMPACT_DIN  <= (31 DOWNTO 16+LOG2(R_BITS) => '0') & SK0_COMPACT_IN_DIN & (15 DOWNTO LOG2(R_BITS) => '0') & SK0_COMPACT_IN_DIN WHEN SK_COMPACT_IN_VALID = '1' ELSE SK_BFITER_DOUT;
    SK1_COMPACT_DIN  <= (31 DOWNTO 16+LOG2(R_BITS) => '0') & SK1_COMPACT_IN_DIN & (15 DOWNTO LOG2(R_BITS) => '0') & SK1_COMPACT_IN_DIN WHEN SK_COMPACT_IN_VALID = '1' ELSE SK_BFITER_DOUT;
            
    BRAM_SK_COMPACT : ENTITY work.BIKE_BRAM_SAMP
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        -- SAMPLING --------------------
        REN0_SAMP       => SK0_COMPACT_RDEN,
        REN1_SAMP       => SK1_COMPACT_RDEN,
        WEN0_SAMP       => SK0_COMPACT_WREN,
        WEN1_SAMP       => SK1_COMPACT_WREN,
        ADDR0_SAMP      => SK0_COMPACT_ADDR,
        ADDR1_SAMP      => SK1_COMPACT_ADDR,
        DOUT0_SAMP      => SK0_COMPACT_DOUT,
        DOUT1_SAMP      => SK1_COMPACT_DOUT,
        DIN0_SAMP       => SK0_COMPACT_DIN,
        DIN1_SAMP       => SK1_COMPACT_DIN
    );
    ------------------------------------------------------------------------------


    -- SRESEULT H-FUNCTION -------------------------------------------------------
    BRAM_EP : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 1
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => ECONTROL_SAMPLE_EN,
        -- SAMPLING --------------------
        REN0_SAMP       => E0CONTROL_SAMPLE_RDEN,
        REN1_SAMP       => E1CONTROL_SAMPLE_RDEN,
        WEN0_SAMP       => E0CONTROL_SAMPLE_WREN,
        WEN1_SAMP       => E1CONTROL_SAMPLE_WREN,
        ADDR0_SAMP      => ECONTROL_SAMPLE_ADDR,
        ADDR1_SAMP      => ECONTROL_SAMPLE_ADDR,
        DOUT0_SAMP      => E0CONTROL_SAMPLE_DIN,
        DOUT1_SAMP      => E1CONTROL_SAMPLE_DIN,
        DIN0_SAMP       => ECONTROL_SAMPLE_DOUT,
        DIN1_SAMP       => ECONTROL_SAMPLE_DOUT,
        -- COMPUTATION -----------------
        WEN0            => '0',
        WEN1            => '0',
        REN0            => E0_COMPE_RDEN,
        REN1            => E1_COMPE_RDEN,
        ADDR0           => CNT_COMPE_OUT,
        ADDR1           => CNT_COMPE_OUT,
        DOUT0           => E0_SAMPLED_DOUT,
        DOUT1           => E1_SAMPLED_DOUT,
        DIN0            => (OTHERS => '0'),
        DIN1            => (OTHERS => '0')
    );
    ------------------------------------------------------------------------------    
        
    
    -- SYNDROME ------------------------------------------------------------------
    -- compute syndrome
    WITH MUL_SEL SELECT MUL_VEC0_DIN <=
        C0_DOUT         WHEN '0',
        E0PP_DOUT       WHEN '1',
        (OTHERS => '0') WHEN OTHERS;

    WITH MUL_SEL SELECT MUL_VEC1_DIN <=
        (OTHERS => '0') WHEN '0',
        E1PP_DOUT       WHEN '1',
        (OTHERS => '0') WHEN OTHERS;
        
    SYNDROME_MUL_DIN <= SYNDROME_INIT_DOUT WHEN MUL_FIRST_COL = '1' ELSE SYNDROME_A_DOUT;
            
    -- compute the syndrome
    -- note that the multiplier is slightly adapted to that used in the key gen and encaps
    -- this multiplier ensures that the "matrix"-input is written back to the memory in its original form
    COMPUTE_SYNDROME : ENTITY work.BIKE_SYNDROME
    PORT MAP ( 
        CLK             => CLK,
        -- CONTROL PORTS ---------------    
        RESET           => MUL_RESET,
        ENABLE          => MUL_ENABLE,
        DONE            => MUL_DONE,
        VALID           => MUL_VALID,
        FIRST           => MUL_FIRST_COL,
        -- RESULT ----------------------
        S_RDEN          => SYNDROME_MUL_RDEN,
        S_WREN          => SYNDROME_MUL_WREN,
        S_ADDR          => SYNDROME_MUL_ADDR,
        S_DOUT          => SYNDROME_MUL_DOUT,
        S_DIN           => SYNDROME_MUL_DIN,
        -- MATRIX ----------------------
        H_RDEN          => SK_MUL_RDEN,
        H_WREN          => SK_MUL_WREN,
        H_ADDR          => SK_MUL_ADDR,
        H_DOUT_0        => SK0_MUL_DOUT,
        H_DOUT_1        => SK1_MUL_DOUT,
        H_DIN_0         => SK0_DOUT,
        H_DIN_1         => SK1_DOUT,
        -- VECTOR ----------------------
        C_RDEN          => MUL_VEC_RDEN,
        C_ADDR          => MUL_VEC_ADDR,
        C_DIN_0         => MUL_VEC0_DIN,  
        C_DIN_1         => MUL_VEC1_DIN  
    );   


    SYNDROME_INIT_WREN <= SYNDROME_MUL_WREN AND NOT MUL_SEL;
    SYNDROME_INIT_RDEN <= SYNDROME_MUL_RDEN;
    SYNDROME_INIT_ADDR <= SYNDROME_MUL_ADDR;
    SYNDROME_INIT_DIN  <= SYNDROME_MUL_DOUT;
    
    -- we need to comput and store the syndrome s=c0*h0
    -- everytime we recompute the syndrome we compute
    -- s' = e0*h0 + e1*h1 + s
    BRAM_INIT_S : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 0)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => '0',
        -- SAMPLING --------------------
        REN_SAMP        => '0',
        WEN_SAMP        => '0',
        ADDR_SAMP       => (OTHERS => '0'),
        DOUT_SAMP       => OPEN,
        DIN_SAMP        => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN             => SYNDROME_INIT_WREN,
        REN             => SYNDROME_INIT_RDEN,
        ADDR            => SYNDROME_INIT_ADDR,
        DOUT            => SYNDROME_INIT_DOUT,
        DIN             => SYNDROME_INIT_DIN
    );
         
    -- BRAM to store syndrome
    WITH SYNDROME_SEL SELECT SYNDROME_A_WREN <=
        SYNDROME_MUL_WREN       WHEN "01",
        SYNDROME_UPC_WREN       WHEN "11",
        '0'                     WHEN OTHERS;

    WITH SYNDROME_SEL SELECT SYNDROME_A_RDEN <=
        SYNDROME_MUL_RDEN       WHEN "01",
        '1'                     WHEN "10",
        SYNDROME_UPC_RDEN       WHEN "11",
        '0'                     WHEN OTHERS;

    WITH SYNDROME_SEL SELECT SYNDROME_A_ADDR <=
        SYNDROME_MUL_ADDR       WHEN "01",
        CNT_HW_OUT              WHEN "10",
        SYNDROME_UPC_A_ADDR     WHEN "11",
        (OTHERS => '0')         WHEN OTHERS;
        
    WITH SYNDROME_SEL SELECT SYNDROME_A_DIN <=
        SYNDROME_MUL_DOUT       WHEN "01",
        SYNDROME_A_UPC_DOUT     WHEN "11",
        (OTHERS => '0')         WHEN OTHERS;

    WITH SYNDROME_SEL SELECT SYNDROME_B_WREN <=
        SYNDROME_MUL_WREN       WHEN "01",
        SYNDROME_UPC_WREN       WHEN "11",
        '0'                     WHEN OTHERS;

    WITH SYNDROME_SEL SELECT SYNDROME_B_RDEN <=
        SYNDROME_MUL_RDEN       WHEN "01",
        '1'                     WHEN "10",
        SYNDROME_UPC_RDEN       WHEN "11",
        '0'                     WHEN OTHERS;
        
    WITH SYNDROME_SEL SELECT SYNDROME_B_ADDR <=
        SYNDROME_MUL_ADDR       WHEN "01",
        CNT_HW_OUT              WHEN "10",
        SYNDROME_UPC_B_ADDR     WHEN "11",
        (OTHERS => '0')         WHEN OTHERS;
        
    WITH SYNDROME_SEL SELECT SYNDROME_B_DIN <=
        SYNDROME_MUL_DOUT       WHEN "01",
        SYNDROME_B_UPC_DOUT     WHEN "11",
        (OTHERS => '0')         WHEN OTHERS; 

    -- these two BRAMs store the updated syndromes s'
    -- we need two BRAMs since we require double the bus width i.e., 2*B_WIDTH
    -- As an example with B_WIDTH=4 and the key index p
    -- | O O O O | O O  O   O  | O   O  O O | O O O O | <- syndrome
    --                 p+3 p+2  p+1  p                           
    BRAM_S_A : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 0)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => '0',
        -- SAMPLING --------------------
        REN_SAMP        => '0',
        WEN_SAMP        => '0',
        ADDR_SAMP       => (OTHERS => '0'),
        DOUT_SAMP       => OPEN,
        DIN_SAMP        => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN             => SYNDROME_A_WREN,
        REN             => SYNDROME_A_RDEN,
        ADDR            => SYNDROME_A_ADDR,
        DOUT            => SYNDROME_A_DOUT,
        DIN             => SYNDROME_A_DIN
    );
    
    BRAM_S_B : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 0)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => '0',
        -- SAMPLING --------------------
        REN_SAMP        => '0',
        WEN_SAMP        => '0',
        ADDR_SAMP       => (OTHERS => '0'),
        DOUT_SAMP       => OPEN,
        DIN_SAMP        => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN             => SYNDROME_B_WREN,
        REN             => SYNDROME_B_RDEN,
        ADDR            => SYNDROME_B_ADDR,
        DOUT            => SYNDROME_B_DOUT,
        DIN             => SYNDROME_B_DIN
    );
    
    -- compute hamming weight
    CNT_HW_DONE <= '1' WHEN CNT_HW_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-1, LOG2(WORDS))) ELSE '0';
    CNT_HW : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP (CLK => CLK, EN => CNT_HW_EN, RST => CNT_HW_RST, CNT_OUT => CNT_HW_OUT);

    HW_MUL_DIN <= SYNDROME_A_DIN WHEN SYNDROME_A_WREN = '1' AND MUL_VALID = '1' ELSE (OTHERS => '0');       -- checks Hamming weight of the syndrome 
    HW_BFITER_DIN <= E_BFITER_DOUT WHEN E0_BFITER_WREN = '1' OR E1_BFITER_WREN = '1' ELSE (OTHERS => '0');  -- checks Hamming weight of the decoded error vector   
    HW_COMPE_DIN <= COMPE_AND; -- checks the Hamming weight of e' XOR e'' -> if zero they are equal
    
    WITH HW_SEL SELECT HW_DIN <=
        HW_MUL_DIN      WHEN "01",
        HW_BFITER_DIN   WHEN "10",
        HW_COMPE_DIN    WHEN "11",
        (OTHERS => '0') WHEN OTHERS;
    
    REG_HW_EN : FDE GENERIC MAP (INIT => '0')
    PORT MAP (Q => HW_EN_D, C => CLK, CE => '1', D => HW_EN);    
    
    HW : ENTITY work.BIKE_HAMMING_WEIGHT
    PORT MAP (
        CLK             => CLK,
        EN              => HW_EN_D,
        RST             => HW_RST,
        -- DATA PORTS ------------------
        DIN             => HW_DIN,
        DOUT            => HW_DOUT
    );
    
    -- indicates if the decoder succeded - if succeded DECODER_RES_OUT = '1'
    DECODER_RES_IN <= '1' WHEN HW_DOUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0,LOG2(R_BITS+1))) ELSE '0'; 
    REG_DECODER_RES : FDRE GENERIC MAP (INIT => '0')
    PORT MAP(Q => DECODER_RES_OUT, C => CLK, CE => DECODER_RES_EN, R => DECODER_RES_RST, D => DECODER_RES_IN);
    
    -- indicates if the Hamming weight of the decoded error vector is equal to T1 - if it is equal HW_E_OUT=1
    HW_E_IN <= '1' WHEN HW_DOUT = STD_LOGIC_VECTOR(TO_UNSIGNED(T1,LOG2(R_BITS+1))) ELSE '0'; 
    HW_E_RES : FDRE GENERIC MAP (INIT => '0')
    PORT MAP(Q => HW_E_OUT, C => CLK, CE => HW_CHECK_E, R => RESET, D => HW_E_IN);
    
    -- indicates if H(m')=(e0',e1') - if equal HW_COMPARE_OUT = '1' 
    REG_COMPARE_RES : FDRE GENERIC MAP (INIT => '0')
    PORT MAP(Q => HW_COMPARE_OUT, C => CLK, CE => HW_COMPARE_EN, R => HW_COMPARE_RST, D => DECODER_RES_IN);
    ------------------------------------------------------------------------------
    
    
    -- COMPUTE THRESHOLD ---------------------------------------------------------
    TH_DIN <= HW_DOUT;
    
    TH : ENTITY work.BIKE_COMPUTE_THRESHOLD
    PORT MAP(
        CLK             => CLK, 
        EN              => TH_EN,
        S               => TH_DIN,
        T               => TH_DOUT
    );
    
    -- counter is used to wait until all data has left the pipeline of the Hamming weight module 
    CNT_HWTH_DONE <= '1' WHEN CNT_HWTH_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(LOG2(B_WIDTH)-1, LOG2(LOG2(B_WIDTH)+2))) ELSE '0';
    CNT_HW_TH : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(LOG2(B_WIDTH)+2), MAX_VALUE => LOG2(B_WIDTH)+2)
    PORT MAP(CLK => CLK, EN => CNT_HWTH_EN, RST => CNT_HWTH_RST, CNT_OUT => CNT_HWTH_OUT);
    ------------------------------------------------------------------------------
    
    
    -- BFITER --------------------------------------------------------------------
    -- counts the number of iterations of the BGF decoder
    CNT_NBITER_DONE <= '1' WHEN CNT_NBITER_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(NbIter, LOG2(NbIter+1))) ELSE '0';
    CNT_NBITER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(NbIter+1), MAX_VALUE => NbIter)
    PORT MAP(CLK => CLK, EN => CNT_NBITER_EN, RST => CNT_NBITER_RST, CNT_OUT => CNT_NBITER_OUT);
    
    -- set threshold for BfIter 
    WITH BFITER_SEL SELECT TH_BFITER_IN <=
        TH_DOUT                                                 WHEN "00",
        STD_LOGIC_VECTOR(TO_UNSIGNED((W/2+1)/2+1, LOG2(W/2)))   WHEN "01",
        STD_LOGIC_VECTOR(TO_UNSIGNED((W/2+1)/2+1, LOG2(W/2)))   WHEN "10",
        TH_DOUT                                                 WHEN "11",
        (OTHERS => '0')                                         WHEN OTHERS;
        
    BFITER : ENTITY work.BIKE_BFITER
    PORT MAP (
        CLK                 => CLK,
        -- CONTROL PORTS ---------------
        RESET               => BFITER_RST,    
        ENABLE              => BFITER_EN,    
        DONE                => BFITER_DONE,
        MODE_SEL            => BFITER_SEL,
        -- THRESHOLD -------------------
        TH                  => TH_BFITER_IN,
        -- SYNDROME --------------------
        SYNDROME_RDEN       => SYNDROME_UPC_RDEN,  
        SYNDROME_WREN       => SYNDROME_UPC_WREN,  
        SYNDROME_A_ADDR     => SYNDROME_UPC_A_ADDR,  
        SYNDROME_A_DIN      => SYNDROME_A_DOUT,
        SYNDROME_A_DOUT     => SYNDROME_A_UPC_DOUT,
        SYNDROME_B_ADDR     => SYNDROME_UPC_B_ADDR,   
        SYNDROME_B_DIN      => SYNDROME_B_DOUT,
        SYNDROME_B_DOUT     => SYNDROME_B_UPC_DOUT,
        -- SECRET KEY ------------------
        SK0_RDEN            => SK0_BFITER_RDEN,  
        SK1_RDEN            => SK1_BFITER_RDEN,  
        SK0_WREN            => SK0_BFITER_WREN,
        SK1_WREN            => SK1_BFITER_WREN,
        SK_ADDR             => SK_BFITER_ADDR,
        SK_DOUT             => SK_BFITER_DOUT,
        SK0_DIN             => SK0_COMPACT_DOUT, 
        SK1_DIN             => SK1_COMPACT_DOUT, 
        -- ERROR -----------------------
        E0_RDEN             => E0_BFITER_RDEN,  
        E1_RDEN             => E1_BFITER_RDEN,  
        E0_WREN             => E0_BFITER_WREN,  
        E1_WREN             => E1_BFITER_WREN, 
        E_ADDR              => E_BFITER_ADDR,
        E_DOUT              => E_BFITER_DOUT,
        E0_DIN              => E0PP_DOUT,
        E1_DIN              => E1PP_DOUT,
        -- BLACK -----------------------
        BLACK0_RDEN         => BLACK0_BFITER_RDEN,
        BLACK1_RDEN         => BLACK1_BFITER_RDEN,
        BLACK0_WREN         => BLACK0_BFITER_WREN,
        BLACK1_WREN         => BLACK1_BFITER_WREN,
        BLACK_ADDR          => BLACK_BFITER_ADDR,
        BLACK_DOUT          => BLACK_BFITER_DOUT,
        BLACK0_DIN          => BLACK0_DOUT,
        BLACK1_DIN          => BLACK1_DOUT,
        -- GRAY -----------------------
        GRAY0_RDEN          => GRAY0_BFITER_RDEN,
        GRAY1_RDEN          => GRAY1_BFITER_RDEN,
        GRAY0_WREN          => GRAY0_BFITER_WREN,
        GRAY1_WREN          => GRAY1_BFITER_WREN,
        GRAY_ADDR           => GRAY_BFITER_ADDR,
        GRAY_DOUT           => GRAY_BFITER_DOUT,
        GRAY0_DIN           => GRAY0_DOUT,
        GRAY1_DIN           => GRAY1_DOUT
    );
    ------------------------------------------------------------------------------

    -- ERROR VECTOR --------------------------------------------------------------    
    WITH ERRORPP_SEL SELECT E0PP_RDEN <=
        E0_BFITER_RDEN          WHEN "00",
        MUL_VEC_RDEN            WHEN "10",
        E0_COMPE_RDEN           WHEN "11",
        '0'                     WHEN OTHERS;

    WITH ERRORPP_SEL SELECT E1PP_RDEN <=
        E1_BFITER_RDEN          WHEN "00",
        MUL_VEC_RDEN            WHEN "10",
        E1_COMPE_RDEN           WHEN "11",
        '0'                     WHEN OTHERS;

    WITH ERRORPP_SEL SELECT E0PP_WREN <=
        E0_BFITER_WREN          WHEN "00",
        '1'                     WHEN "01",
        '0'                     WHEN OTHERS;

    WITH ERRORPP_SEL SELECT E1PP_WREN <=
        E1_BFITER_WREN          WHEN "00",
        '0'                     WHEN OTHERS;

    WITH ERRORPP_SEL SELECT E0PP_ADDR <=
        E_BFITER_ADDR           WHEN "00",
        MUL_VEC_ADDR            WHEN "10",
        CNT_COMPE_OUT           WHEN "11",
        (OTHERS => '0')         WHEN OTHERS;

    WITH ERRORPP_SEL SELECT E1PP_ADDR <=
        E_BFITER_ADDR           WHEN "00",
        MUL_VEC_ADDR            WHEN "10",
        CNT_COMPE_OUT           WHEN "11",
        (OTHERS => '0')         WHEN OTHERS;
        
    WITH ERRORPP_SEL SELECT E0PP_DIN <=
        E_BFITER_DOUT           WHEN "00",
        (OTHERS => '0')         WHEN OTHERS;

    WITH ERRORPP_SEL SELECT E1PP_DIN <=
        E_BFITER_DOUT           WHEN "00",
        (OTHERS => '0')         WHEN OTHERS;


    BRAM_EPP : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 1
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => HASH_L_EN,
        -- SAMPLING --------------------
        REN0_SAMP       => ERROR0_HASH_RDEN,
        REN1_SAMP       => ERROR1_HASH_RDEN,
        WEN0_SAMP       => '0',
        WEN1_SAMP       => '0',
        ADDR0_SAMP      => ERROR0_HASH_ADDR,
        ADDR1_SAMP      => ERROR1_HASH_ADDR,
        DOUT0_SAMP      => E0_DECODE_DOUT,
        DOUT1_SAMP      => E1_DECODE_DOUT,
        DIN0_SAMP       => (OTHERS => '0'),
        DIN1_SAMP       => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN0            => E0PP_WREN,
        WEN1            => E1PP_WREN,
        REN0            => E0PP_RDEN,
        REN1            => E1PP_RDEN,
        ADDR0           => E0PP_ADDR,
        ADDR1           => E1PP_ADDR,
        DOUT0           => E0PP_DOUT,
        DOUT1           => E1PP_DOUT,
        DIN0            => E0PP_DIN,
        DIN1            => E1PP_DIN
    );
    ------------------------------------------------------------------------------     


    -- BLACK ---------------------------------------------------------------------   
    BRAM_BLACK : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 0
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => '0',
        -- SAMPLING --------------------
        REN0_SAMP       => '0',
        REN1_SAMP       => '0',
        WEN0_SAMP       => '0',
        WEN1_SAMP       => '0',
        ADDR0_SAMP      => (OTHERS => '0'),
        ADDR1_SAMP      => (OTHERS => '0'),
        DOUT0_SAMP      => OPEN,
        DOUT1_SAMP      => OPEN,
        DIN0_SAMP       => (OTHERS => '0'),
        DIN1_SAMP       => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN0            => BLACK0_BFITER_WREN,
        WEN1            => BLACK1_BFITER_WREN,
        REN0            => BLACK0_BFITER_RDEN,
        REN1            => BLACK1_BFITER_RDEN,
        ADDR0           => BLACK_BFITER_ADDR,
        ADDR1           => BLACK_BFITER_ADDR,
        DOUT0           => BLACK0_DOUT,
        DOUT1           => BLACK1_DOUT,
        DIN0            => BLACK_BFITER_DOUT,
        DIN1            => BLACK_BFITER_DOUT
    );
    ------------------------------------------------------------------------------   
    

    -- GRAY ----------------------------------------------------------------------
    BRAM_GRAY : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 0
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => '0',
        -- SAMPLING --------------------
        REN0_SAMP       => '0',
        REN1_SAMP       => '0',
        WEN0_SAMP       => '0',
        WEN1_SAMP       => '0',
        ADDR0_SAMP      => (OTHERS => '0'),
        ADDR1_SAMP      => (OTHERS => '0'),
        DOUT0_SAMP      => OPEN,
        DOUT1_SAMP      => OPEN,
        DIN0_SAMP       => (OTHERS => '0'),
        DIN1_SAMP       => (OTHERS => '0'),
        -- COMPUTATION -----------------
        WEN0            => GRAY0_BFITER_WREN,
        WEN1            => GRAY1_BFITER_WREN,
        REN0            => GRAY0_BFITER_RDEN,
        REN1            => GRAY1_BFITER_RDEN,
        ADDR0           => GRAY_BFITER_ADDR,
        ADDR1           => GRAY_BFITER_ADDR,
        DOUT0           => GRAY0_DOUT,
        DOUT1           => GRAY1_DOUT,
        DIN0            => GRAY_BFITER_DOUT,
        DIN1            => GRAY_BFITER_DOUT
    );
    ------------------------------------------------------------------------------          


    -- HASHING -------------------------------------------------------------------
    -- H-Function
    REG_HASH_VALID : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            HASH_H_VALID <= SHA_M_RDY;
        END IF;
    END PROCESS;
    
    CNT_REGH_EN_GATED <= CNT_REGH_EN AND HASH_H_VALID;
    REG_CNT : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(CEIL(L,32)), MAX_VALUE => CEIL(L,32))
    PORT MAP(CLK => CLK, EN => CNT_REGH_EN_GATED, RST => CNT_REGH_RST, CNT_OUT => CNT_REGH_OUT);
    
    HASH_H_M <= M_REG_OUT(TO_INTEGER(UNSIGNED(CNT_REGH_OUT)));
    
    
    -- L-Function
    HASH_ERROR : ENTITY work.BIKE_HASH_ERROR
    PORT MAP(
        CLK                 => CLK,
        -- CONTROL PORTS ---------------    
        RESET               => RESET,
        HASH_EN             => HASH_L_EN,
        HASH_DONE           => SHA_DONE,
        -- ERROR BRAM ------------------
        ERROR0_RDEN         => ERROR0_HASH_RDEN,
        ERROR1_RDEN         => ERROR1_HASH_RDEN,
        ERROR0_ADDR         => ERROR0_HASH_ADDR,
        ERROR1_ADDR         => ERROR1_HASH_ADDR,
        ERROR0_DIN          => E0_DECODE_DOUT,
        ERROR1_DIN          => E1_DECODE_DOUT,
        -- HASH K ----------------------
        HASH_M              => HASH_L_M,
        HASH_VALID          => HASH_L_VALID,
        HASH_RDY            => HASH_L_RDY    
    );

    -- K-Function
    MESSAGE_K_IN <= M_REG_OUT WHEN HW_COMPARE_OUT = '1' ELSE SIGMA_REG_OUT;
    HASH_MC : ENTITY work.BIKE_HASH_MC
    PORT MAP(
        CLK                 => CLK,
        -- CONTROL PORTS ---------------    
        RESET               => RESET,
        HASH_EN             => HASH_K_EN,
        -- DATA ------------------------
        MESSAGE             => MESSAGE_K_IN,
        C1                  => C1_REG_OUT,
        C0_RDEN             => C0_HASH_RDEN,
        C0_ADDR             => C0_HASH_ADDR,
        C0                  => C0_SAMP_DOUT,
        -- HASH K ----------------------
        HASH_M              => HASH_K_M,
        HASH_VALID          => HASH_K_VALID,
        HASH_RDY            => HASH_K_RDY    
    );
        
    -- set hash size
    WITH HASH_SELECTION SELECT HASH_SIZE <=
        STD_LOGIC_VECTOR(TO_UNSIGNED(L,20))                         WHEN "01",
        STD_LOGIC_VECTOR(TO_UNSIGNED(2*CEIL(R_BITS,8)*8,20))        WHEN "10",
        STD_LOGIC_VECTOR(TO_UNSIGNED(CEIL(R_BITS,8)*8 + 2*L,20))    WHEN "11",
        (OTHERS => '0')                                             WHEN OTHERS;
    
    -- assign correct input
    WITH HASH_SELECTION SELECT SHA_M <=
        HASH_H_M        WHEN "01",
        HASH_L_M        WHEN "10",
        HASH_K_M        WHEN "11",
        (OTHERS => '0') WHEN OTHERS;

    WITH HASH_SELECTION SELECT SHA_M_VALID <=
        HASH_H_VALID    WHEN "01",
        HASH_L_VALID    WHEN "10",
        HASH_K_VALID    WHEN "11",
        '0'             WHEN OTHERS;
    
    HASH_L_RDY  <= SHA_M_RDY;
    HASH_K_RDY  <= SHA_M_RDY;
    
    -- SHA core
    SHA : ENTITY work.SHA384_RETIMING_VAR_SIZE
    PORT MAP (
        CLK             => CLK, 
        -- CONTROL PORTS ---------------    
        RESET           => SHA_RESET,
        ENABLE          => SHA_ENABLE,
        DONE            => SHA_DONE,
        -- SIZE ------------------------
        SIZE            => HASH_SIZE,
        -- MESSAGE ---------------------
        M               => SHA_M,
        M_VALID         => SHA_M_VALID,
        M_RDY           => SHA_M_RDY,
        -- HASH ------------------------
        HASH            => SHA_HASH,
        HASH_ADDR       => SHA_HASH_ADDR,
        HASH_VALID      => SHA_HASH_VALID
    );
    
    -- Output - final decapsulated key
    K_VALID <= SHA_HASH_VALID   WHEN HASH_K_EN = '1' ELSE '0';
    K_OUT   <= SHA_HASH         WHEN HASH_K_EN = '1' ELSE (OTHERS => '0'); 
    ------------------------------------------------------------------------------


    -- SAMPLE ERROR VECTOR -------------------------------------------------------
    -- to validate the decoded error vector a reference error vector based on m_prime is sampled
    ARRAY2STD : FOR I IN 0 TO 7 GENERATE
        AES_KEY(32*(8-I)-1 DOWNTO 32*(7-I)) <= M_REG_OUT(I);
    END GENERATE;
    
    ERROR_SAMPLE : ENTITY work.BIKE_SAMPLER_ERROR
    GENERIC MAP (
        THRESHOLD       => T1
    )
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS ---------------    
        RESET           => RESET,
        ENABLE          => ECONTROL_SAMPLE_EN,
        DONE            => ECONTROL_SAMPLE_DONE,
        -- RAND ------------------------
        AES_KEY         => AES_KEY,
        -- MEMORY I/O ------------------
        RDEN_1          => E0CONTROL_SAMPLE_RDEN,
        WREN_1          => E0CONTROL_SAMPLE_WREN,
        RDEN_2          => E1CONTROL_SAMPLE_RDEN,
        WREN_2          => E1CONTROL_SAMPLE_WREN,
        ADDR            => ECONTROL_SAMPLE_ADDR,
        DOUT            => ECONTROL_SAMPLE_DOUT,
        DIN_1           => E0CONTROL_SAMPLE_DIN,
        DIN_2           => E1CONTROL_SAMPLE_DIN
    );
    
    -- counter is used to copy error vector and to read both error vectors in order to compare them
    CNT_COMPE_DONE <= '1' WHEN CNT_COMPE_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS-2, LOG2(WORDS))) ELSE '0';
    CNT_COMPE : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS-1)
    PORT MAP(CLK => CLK, EN => CNT_COMPE_EN, RST => CNT_COMPE_RST, CNT_OUT => CNT_COMPE_OUT);

    DELAY_SEL_E : FDRE GENERIC MAP (INIT => '0')
    PORT MAP(Q => SEL_COMP_ERROR_POLY, C => CLK, CE => '1', R => RESET, D => E0_COMPE_RDEN);
        
    COMPE_DINA <= E0_SAMPLED_DOUT WHEN SEL_COMP_ERROR_POLY = '1' ELSE E1_SAMPLED_DOUT;
    COMPE_DINB <= E0PP_DOUT WHEN SEL_COMP_ERROR_POLY = '1' ELSE E1PP_DOUT;    
    
    -- xor both words of the error vectors
    -- the result is used as input for the Hamming Weight module to save logic for a comperator
    COMPE_AND  <= COMPE_DINA XOR COMPE_DINB;
    ------------------------------------------------------------------------------    



    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            -- GLOBAL ----------
            DECAPS_DONE         <= '0';
            
            -- SELECTION -------
            SYNDROME_SEL        <= "00";
            ERRORPP_SEL         <= "00";
            HW_SEL              <= "00";
            
            -- SAMPLER ---------
            ERROR_SAMPLE_EN     <= '0';
            
            -- MULTIPLICATION --
            MUL_RESET           <= '1';
            MUL_ENABLE          <= '0';
            MUL_SEL             <= '0';
            
            -- BFITER ----------
            BFITER_RST          <= '1';
            BFITER_EN           <= '0';
            BFITER_SEL          <= "00";
            
            -- COUNTER ---------
            CNT_HWTH_RST        <= '1';
            CNT_HWTH_EN         <= '0';
    
            CNT_HW_RST          <= '1';                    
            CNT_HW_EN           <= '0';  
            
            CNT_NBITER_RST      <= '1';
            CNT_NBITER_EN       <= '0';
            
            CNT_COMPE_RST       <= '1';
            CNT_COMPE_EN        <= '0';
            
            -- THRESHOLD -------
            HW_RST              <= '1';
            HW_EN               <= '0';
            DECODER_RES_RST     <= '1';
            DECODER_RES_EN      <= '0';
            HW_COMPARE_RST      <= '1';  
            HW_COMPARE_EN       <= '0'; 
            TH_EN               <= '0';
            HW_CHECK_E          <= '0';
            
            -- COMP ERROR
            ECONTROL_SAMPLE_EN  <= '0'; 
            E0_COMPE_RDEN       <= '0';
            E1_COMPE_RDEN       <= '0';
                                         
            -- HASH ------------                   
            SHA_RESET           <= '1';
            SHA_ENABLE          <= '0';
            
            CNT_REGH_RST        <= '1';
            CNT_REGH_EN         <= '0';
            HASH_H_EN           <= '0';
            
            HASH_L_EN           <= '0';
            
            HASH_K_EN           <= '0';  
               
            HASH_SELECTION      <= "00";    
                     
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET            =>                                        
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN
                        STATE           <= S_COMPUTE_SYNDROME;
                    ELSE
                        STATE           <= S_RESET;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_COMPUTE_SYNDROME           =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "01";
                    HW_SEL              <= "01";
                                        
                    -- MULTIPLICATION --
                    MUL_RESET           <= '0';
                    MUL_ENABLE          <= '1'; 
                    MUL_SEL             <= '0';                  
                                        
                    -- THRESHOLD -------
                    HW_RST              <= '0';
                    HW_EN               <= '1';
                                                            
                    -- TRANSITION ------
                    IF (MUL_DONE = '1') THEN
                        STATE           <= S_HW_TH;
                    ELSE
                        STATE           <= S_COMPUTE_SYNDROME;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_RECOMPUTE_SYNDROME         =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "01";
                    HW_SEL              <= "01";
                    ERRORPP_SEL         <= "10";
                                        
                    -- MULTIPLICATION --
                    MUL_RESET           <= '0';
                    MUL_ENABLE          <= '1'; 
                    MUL_SEL             <= '1';                  
                                        
                    -- THRESHOLD -------
                    HW_RST              <= '0';
                    HW_EN               <= '1';
                    
                    -- COUNTER ---------
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0'; 
                                                            
                    -- TRANSITION ------
                    IF (MUL_DONE = '1') THEN
                        STATE           <= S_HW_TH;
                    ELSE
                        STATE           <= S_RECOMPUTE_SYNDROME;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_HW_TH            =>                                                                                
                    -- THRESHOLD -------
                    --HW_RST              <= '0';
                    HW_EN               <= '1';
                    DECODER_RES_RST     <= '0';                   
                    TH_EN               <= '1';     
                    
                    -- COUNTER ---------
                    CNT_HWTH_RST        <= '0';
                    CNT_HWTH_EN         <= '1'; 
                    
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0';                       
                                                            
                    -- TRANSITION ------
                    IF (CNT_HWTH_DONE = '1') THEN
                        CNT_NBITER_EN   <= '1';
                        DECODER_RES_EN  <= '1';
                        HW_RST              <= '1'; 
                        IF CNT_NBITER_DONE = '1' THEN
                            STATE       <= S_HASH_L;
                        ELSIF CNT_NBITER_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(NbIter+1))) THEN
                            STATE       <= S_BFITER_BG;
                        ELSIF CNT_NBITER_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(1, LOG2(NbIter+1))) THEN
                            STATE       <= S_BFITER_BLACK;
                        ELSIF CNT_NBITER_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(2, LOG2(NbIter+1))) THEN
                            STATE       <= S_BFITER_GRAY;                                                                        
                        ELSE
                            STATE       <= S_BFITER;
                        END IF;
                    ELSE
                        STATE           <= S_HW_TH;
                        HW_RST              <= '0';
                    END IF;
                ----------------------------------------------
                                
                ----------------------------------------------
                WHEN S_BFITER_BG              =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "11";
                    ERRORPP_SEL         <= "00";

                    -- BFITER ----------
                    BFITER_RST          <= '0';
                    BFITER_EN           <= '1';
                    BFITER_SEL          <= "00";
                                        
                    -- COUNTER ---------                 
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0';                                        
                                                            
                    -- TRANSITION ------
                    IF (BFITER_DONE = '1') THEN
                        STATE           <= S_RECOMPUTE_SYNDROME;
                    ELSE
                        STATE           <= S_BFITER_BG;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_BFITER_BLACK     =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "11";
                    ERRORPP_SEL         <= "00";

                    -- BFITER ----------
                    BFITER_RST          <= '0';
                    BFITER_EN           <= '1';
                    BFITER_SEL          <= "01";
                                        
                    -- COUNTER ---------
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0'; 
                                                                                                                        
                    -- TRANSITION ------
                    IF (BFITER_DONE = '1') THEN
                        STATE           <= S_RECOMPUTE_SYNDROME;
                    ELSE
                        STATE           <= S_BFITER_BLACK;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_BFITER_GRAY     =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "11";
                    ERRORPP_SEL         <= "00";

                    -- BFITER ----------
                    BFITER_RST          <= '0';
                    BFITER_EN           <= '1';
                    BFITER_SEL          <= "10";
                                        
                    -- COUNTER ---------
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0';                                         
                                                                                
                    -- TRANSITION ------
                    IF (BFITER_DONE = '1') THEN
                        STATE           <= S_RECOMPUTE_SYNDROME;
                    ELSE
                        STATE           <= S_BFITER_GRAY;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_BFITER           =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "11";
                    ERRORPP_SEL         <= "00";
                    HW_SEL              <= "10";

                    -- BFITER ----------
                    BFITER_RST          <= '0';
                    BFITER_EN           <= '1';
                    BFITER_SEL          <= "11";
                    
                    -- THRESHOLD -------
                    DECODER_RES_RST     <= '0'; 
                                        
                    -- COUNTER ---------
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0';  

                    -- HAMMING WEIGHT --
                    HW_RST              <= '0';
                    HW_EN               <= '1'; 
                    
                    -- TRANSITION ------
                    IF (BFITER_DONE = '1') THEN
                        STATE           <= S_HAMMING_WEIGHT;
                    ELSE
                        STATE           <= S_BFITER;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_HAMMING_WEIGHT     =>
                    -- SELECTION -------
                    HW_SEL              <= "10";      
                    
                    -- COUNTER ---------
                    CNT_HWTH_RST        <= '0';
                    CNT_HWTH_EN         <= '1';             

                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0';  
                    
                    -- HAMMING WEIGHT --
                    HW_EN               <= '1';
                    HW_CHECK_E          <= '1';
                                                            
                    -- TRANSITION ------
                    IF (CNT_HWTH_DONE = '1') THEN
                        HW_RST          <= '1';
                        STATE           <= S_RECOMPUTE_SYNDROME;
                    ELSE
                        HW_RST          <= '0';
                        STATE           <= S_HAMMING_WEIGHT;
                    END IF;
                ----------------------------------------------
                
--                ----------------------------------------------
--                WHEN S_COPY_E           =>
--                    -- SELECTION -------
--                    ERROR_SEL           <= "01";
--                    ERRORPP_SEL         <= "01";
                    
--                    -- COUNTER ---------
--                    CNT_COMPE_RST       <= '0';
--                    CNT_COMPE_EN        <= '1';
                    
--                    CNT_COPY_RST        <= '0';

--                    -- THRESHOLD -------
--                    DECODER_RES_RST     <= '0';
                                        
--                    IF CNT_COPY_DONE = '1' THEN
--                        STATE           <= S_HASH_L;
--                    ELSE
--                        STATE           <= S_COPY_E;
--                    END IF;
--                ----------------------------------------------

                ----------------------------------------------
                WHEN S_HASH_L  =>
                    -- SELECTION -------
                    SYNDROME_SEL        <= "00";
              
                    -- COUNTER ---------
                    CNT_NBITER_RST      <= '0';
                    CNT_NBITER_EN       <= '0';                
                    
                    -- HASH ------------                   
                    HASH_L_EN           <= '1';                      
                    HASH_SELECTION      <= "10";    

                    -- THRESHOLD -------
                    DECODER_RES_RST     <= '0';
                                                            
                    -- TRANSITION ------
                    IF (SHA_DONE = '1') THEN
                        SHA_RESET       <= '1';
                        SHA_ENABLE      <= '0';
                        
                        STATE           <= S_SAMPLE_E; 
                    ELSE
                        SHA_RESET       <= '0';
                        SHA_ENABLE      <= '1';  
                                          
                        STATE           <= S_HASH_L;
                    END IF;
                ---------------------------------------------- 

                ----------------------------------------------
                WHEN S_SAMPLE_E           => 
                    -- SELCTION --------
                    ERRORPP_SEL         <= "10";
                    
                    -- THRESHOLD -------
                    DECODER_RES_RST     <= '0';

                    -- COMP ERROR
                    ECONTROL_SAMPLE_EN  <= '1';
                                                            
                    -- TRANSITION ------
                    IF (ECONTROL_SAMPLE_DONE = '1') THEN
                        STATE           <= S_COMPARE_E0;
                    ELSE
                        STATE           <= S_SAMPLE_E;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_COMPARE_E0       => 
                    -- THRESHOLD -------
                    DECODER_RES_RST     <= '0';

                    -- SELECTION -------
                    ERRORPP_SEL         <= "11";
                    HW_SEL              <= "11";

                    -- THRESHOLD -------
                    HW_RST              <= '0';
                    HW_EN               <= '1';
                    
                    -- COUNTER ---------
                    CNT_COMPE_RST       <= '0';
                    CNT_COMPE_EN        <= '1';
                                        
                    -- COMP ERROR
                    E0_COMPE_RDEN       <= '1';
                                                            
                    -- TRANSITION ------
                    IF (CNT_COMPE_DONE = '1') THEN
                        STATE           <= S_COMPARE_E1;
                    ELSE
                        STATE           <= S_COMPARE_E0;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_COMPARE_E1       => 
                    -- THRESHOLD -------
                    DECODER_RES_RST     <= '0';
                
                    -- SELECTION -------
                    ERRORPP_SEL         <= "11";
                    HW_SEL              <= "11";

                    -- THRESHOLD -------
                    HW_RST              <= '0';
                    HW_EN               <= '1';

                    -- COUNTER ---------
                    CNT_COMPE_RST       <= '0';
                    CNT_COMPE_EN        <= '1';
                                                        
                    -- COMP ERROR
                    E1_COMPE_RDEN       <= '1';
                                                            
                    -- TRANSITION ------
                    IF (CNT_COMPE_DONE = '1') THEN
                        STATE           <= S_COMPARE_HW;
                    ELSE
                        STATE           <= S_COMPARE_E1;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_COMPARE_HW       =>                                                                                
                    -- THRESHOLD -------
                    HW_RST              <= '0';
                    HW_EN               <= '1'; 
                    DECODER_RES_RST     <= '0';
                    HW_COMPARE_RST      <= '0';  
                    HW_COMPARE_EN       <= '1';  
                    
                    -- COUNTER ---------
                    CNT_HWTH_RST        <= '0';
                    CNT_HWTH_EN         <= '1';                       
                                                            
                    -- TRANSITION ------
                    IF (CNT_HWTH_DONE = '1') THEN
                        STATE           <= S_HASH_K;
                    ELSE
                        STATE           <= S_COMPARE_HW;
                    END IF;
                ----------------------------------------------
                                                                                                
                ----------------------------------------------
                WHEN S_HASH_K           =>   
                    -- THRESHOLD -------
                    HW_COMPARE_RST      <= '0'; 
                    DECODER_RES_RST     <= '0';
                                
                    -- HASH ------------                   
                    SHA_RESET           <= '0';
                    SHA_ENABLE          <= '1';
                    
                    HASH_K_EN           <= '1';     
                    HASH_SELECTION      <= "11";    
                                                            
                    -- TRANSITION ------
                    IF (SHA_DONE = '1') THEN  
                        STATE           <= S_DONE; 
                    ELSE
                        STATE           <= S_HASH_K;
                    END IF;
                ----------------------------------------------                   
                                
                ----------------------------------------------
                WHEN S_DONE             =>
                    -- GLOBAL ----------
                    DECAPS_DONE         <= '1';
    
                    -- TRANSITION ------
                    IF (RESET = '1') THEN
                        STATE           <= S_RESET;
                    ELSE
                        STATE           <= S_DONE;
                    END IF;
                ----------------------------------------------
                                                                                
            END CASE;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------
    
END Structural;
