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
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------    
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        ENCAPS_DONE     : OUT STD_LOGIC;
        -- RANDOMNESS ------------------
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

SIGNAL CNT_OUT_EN, CNT_OUT_RESET                    : STD_LOGIC;
SIGNAL CNT_OUT_OUT                                  : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

SIGNAL CNT_REG_EN, CNT_REG_RESET                    : STD_LOGIC;
SIGNAL CNT_REG_OUT                                  : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0);


-- REGISTER
SIGNAL M_REG_OUT                                    : WORD_ARRAY(7 DOWNTO 0);
SIGNAL M_REG_EN                                     : STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL C1_REG_IN                                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL C1_REG_OUT                                   : WORD_ARRAY(7 DOWNTO 0);
SIGNAL C1_REG_EN                                    : STD_LOGIC_VECTOR(7 DOWNTO 0);


-- SAMPLE M
SIGNAL M_SAMPLE_RESET                               : STD_LOGIC;
SIGNAL M_SAMPLE_ENABLE, M_SAMPLE_DONE               : STD_LOGIC;
SIGNAL M_SAMPLE_RDEN, M_SAMPLE_WREN                 : STD_LOGIC;
SIGNAL M_SAMPLE_ADDR                                : STD_LOGIC_VECTOR(LOG2(CEIL(L,32))-1 DOWNTO 0);
SIGNAL M_SAMPLE_DOUT                                : STD_LOGIC_VECTOR(31 DOWNTO 0);


-- SAMPLE ERROR
SIGNAL ERROR_SAMPLE_EN, ERROR_SAMPLE_DONE           : STD_LOGIC;
SIGNAL ERROR_SAMPLE_EN_GATED                        : STD_LOGIC;
SIGNAL ERROR0_SAMPLE_RDEN, ERROR0_SAMPLE_WREN       : STD_LOGIC;
SIGNAL ERROR1_SAMPLE_RDEN, ERROR1_SAMPLE_WREN       : STD_LOGIC;
SIGNAL ERROR_SAMPLE_ADDR                            : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL ERROR_SAMPLE_DOUT                            : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL ERROR0_SAMPLE_DIN, ERROR1_SAMPLE_DIN         : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL EC0_RDEN, EC0_WREN       					: STD_LOGIC;
SIGNAL Ec1_RDEN, EC1_WREN       					: STD_LOGIC;
SIGNAL EC0_ADDR, EC1_ADDR                           : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
SIGNAL EC0_DOUT, EC1_DOUT                           : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL EC0_DIN, EC1_DIN         					: STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL AES_KEY                                      : STD_LOGIC_VECTOR(255 DOWNTO 0);


-- ENCODE
SIGNAL ENCODE_RST, ENCODE_EN, ENCODE_DONE           : STD_LOGIC;
SIGNAL ERROR0_ENC_RDEN, ERROR1_ENC_RDEN             : STD_LOGIC;
SIGNAL ERROR0_ENC_WREN, ERROR1_ENC_WREN             : STD_LOGIC;
SIGNAL ERROR0_ENC_ADDR, ERROR1_ENC_ADDR             : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL ERROR0_ENC_DOUT, ERROR1_ENC_DOUT             : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0); 
SIGNAL ERROR0_ENC_DIN, ERROR1_ENC_DIN               : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0); 


-- PUBLIC KEY
SIGNAL PK_RDEN, PK_WREN                             : STD_LOGIC;
SIGNAL PK_ADDR                                      : STD_LOGIC_VECTOR(LOG2(WORDS)-1 DOWNTO 0);
SIGNAL PK_DIN, PK_DOUT                              : STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);


-- RANDOM ORACLES
SIGNAL HASH_SELECTION                               : STD_LOGIC_VECTOR(1 DOWNTO 0);

SIGNAL HASH_L_EN, HASH_L_RDY, HASH_L_VALID          : STD_LOGIC;
SIGNAL HASH_L_M                                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL HASH_K_EN, HASH_K_RDY, HASH_K_VALID          : STD_LOGIC;
SIGNAL HASH_K_M                                     : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL ERROR0_L_RDEN, ERROR1_L_RDEN					: STD_LOGIC;
SIGNAL ERROR0_L_ADDR, ERROR1_L_ADDR					: STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);


-- SHA
SIGNAL SHA_ENABLE, SHA_RESET, SHA_DONE              : STD_LOGIC;
SIGNAL SHA_M_RDY, SHA_M_VALID, SHA_HASH_VALID       : STD_LOGIC;
SIGNAL SHA_M, SHA_HASH                              : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SHA_HASH_ADDR                                : STD_LOGIC_VECTOR( 2 DOWNTO 0);
SIGNAL HASH_SIZE                                    : STD_LOGIC_VECTOR(19 DOWNTO 0);


-- OUTPUT
SIGNAL C_OUT_PRE                                    : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL OUTPUT_EN                                    : STD_LOGIC;
SIGNAL EN_OUT_C1                                    : STD_LOGIC;

SIGNAL C0_HASH_RDEN                                 : STD_LOGIC;
SIGNAL C0_HASH_ADDR                                 : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);

SIGNAL ERROR0_SAMPLE_RDEN_GATED                     : STD_LOGIC;
SIGNAL ERROR_SAMPLE_ADDR_GATED                      : STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_SAMPLE_M, S_SAMPLE_E, S_HASH_AND_ENCODE, S_ENCODE, S_HASH_K, S_OUTPUT_C0_INIT, S_OUTPUT_C0, S_OUTPUT_C1, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
    
    -- OUTPUT --------------------------------------------------------------------
    ERROR_SAMPLE_EN_GATED       <= '1' WHEN OUTPUT_EN = '1' ELSE ERROR_SAMPLE_EN WHEN HASH_K_EN = '0' ELSE C0_HASH_RDEN;
    ERROR0_SAMPLE_RDEN_GATED    <= '1' WHEN OUTPUT_EN = '1' ELSE ERROR0_SAMPLE_RDEN WHEN HASH_K_EN = '0' ELSE C0_HASH_RDEN;
    
    ERROR_SAMPLE_ADDR_GATED     <= CNT_OUT_OUT WHEN OUTPUT_EN = '1' ELSE ERROR_SAMPLE_ADDR WHEN HASH_K_EN = '0' ELSE C0_HASH_ADDR;
    
    OUTPUT_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(R_BLOCKS), MAX_VALUE => R_BLOCKS)
    PORT MAP(CLK => CLK, EN => CNT_OUT_EN, RST => CNT_OUT_RESET, CNT_OUT => CNT_OUT_OUT);

    OUTPUT_CNT_REG : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(CEIL(L,32)), MAX_VALUE => CEIL(L,32))
    PORT MAP(CLK => CLK, EN => CNT_REG_EN, RST => CNT_REG_RESET, CNT_OUT => CNT_REG_OUT);
        
    C_OUT_PRE   <= ERROR0_SAMPLE_DIN WHEN EN_OUT_C1 = '0' ELSE C1_REG_OUT(TO_INTEGER(UNSIGNED(CNT_REG_OUT)));
    C_OUT       <= C_OUT_PRE WHEN OUTPUT_EN = '1' ELSE (OTHERS => '0');
    ------------------------------------------------------------------------------


    -- SAMPLE MESSAGE ------------------------------------------------------------
    SAMPLE_M : ENTITY work.BIKE_SAMPLER_UNIFORM
    GENERIC MAP (
        SAMPLE_LENGTH   => L
    )
    PORT MAP (
        CLK             => CLK,
        -- CONTROL PORTS -----------   
        RESET           => M_SAMPLE_RESET,
        ENABLE          => M_SAMPLE_ENABLE,
        DONE            => M_SAMPLE_DONE,
        -- RAND --------------------
        NEW_RAND        => M_RAND,
        -- MEMORY I/O --------------
        RDEN            => M_SAMPLE_RDEN,
        WREN            => M_SAMPLE_WREN,
        ADDR            => M_SAMPLE_ADDR,
        DOUT            => M_SAMPLE_DOUT     
    );    
    
    -- we decided to go with registers here as L=256 and spending a BRAM would be overkill
    -- however, the registers can be easily repleased by memory if desired       
    EN_REG : FOR I IN 0 TO 7 GENERATE
    BEGIN
        M_REG_EN(I)  <= M_SAMPLE_WREN WHEN M_SAMPLE_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(I, LOG2(CEIL(L,32)))) ELSE '0';
        C1_REG_EN(I) <= SHA_HASH_VALID AND HASH_L_EN WHEN SHA_HASH_ADDR = STD_LOGIC_VECTOR(TO_UNSIGNED(I, LOG2(CEIL(L,32)))) ELSE '0';
    END GENERATE;  
    
    REG_M : ENTITY work.BIKE_REG_BANK GENERIC MAP(SIZE => 8)
    PORT MAP(CLK => CLK, RST => RESET, EN => M_REG_EN, DIN => M_SAMPLE_DOUT, DOUT => M_REG_OUT);
    
    
    C1_REG_IN <= M_REG_OUT(TO_INTEGER(UNSIGNED(SHA_HASH_ADDR))) XOR SHA_HASH;
     
    REG_C1 : ENTITY work.BIKE_REG_BANK GENERIC MAP(SIZE => 8)
    PORT MAP(CLK => CLK, RST => RESET, EN => C1_REG_EN, DIN => C1_REG_IN, DOUT => C1_REG_OUT);    
    ------------------------------------------------------------------------------
    

    -- SAMPLE ERROR VECTOR -------------------------------------------------------
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
        ENABLE          => ERROR_SAMPLE_EN,
        DONE            => ERROR_SAMPLE_DONE,
        -- RAND ------------------------
        AES_KEY         => AES_KEY,
        -- MEMORY I/O ------------------
        RDEN_1          => ERROR0_SAMPLE_RDEN,
        WREN_1          => ERROR0_SAMPLE_WREN,
        RDEN_2          => ERROR1_SAMPLE_RDEN,
        WREN_2          => ERROR1_SAMPLE_WREN,
        ADDR            => ERROR_SAMPLE_ADDR,
        DOUT            => ERROR_SAMPLE_DOUT,
        DIN_1           => ERROR0_SAMPLE_DIN,
        DIN_2           => ERROR1_SAMPLE_DIN
    );
    
    BRAM_E : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 1
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => ERROR_SAMPLE_EN_GATED,
        -- SAMPLING --------------------
        REN0_SAMP       => ERROR0_SAMPLE_RDEN_GATED,
        REN1_SAMP       => ERROR1_SAMPLE_RDEN,
        WEN0_SAMP       => ERROR0_SAMPLE_WREN,
        WEN1_SAMP       => ERROR1_SAMPLE_WREN,
        ADDR0_SAMP      => ERROR_SAMPLE_ADDR_GATED,
        ADDR1_SAMP      => ERROR_SAMPLE_ADDR,
        DOUT0_SAMP      => ERROR0_SAMPLE_DIN,
        DOUT1_SAMP      => ERROR1_SAMPLE_DIN,
        DIN0_SAMP       => ERROR_SAMPLE_DOUT,
        DIN1_SAMP       => ERROR_SAMPLE_DOUT,
        -- COMPUTATION -----------------
        WEN0            => ERROR0_ENC_WREN,
        WEN1            => '0',
        REN0            => ERROR0_ENC_RDEN,
        REN1            => ERROR1_ENC_RDEN,
        ADDR0           => ERROR0_ENC_ADDR,
        ADDR1           => ERROR1_ENC_ADDR,
        DOUT0           => ERROR0_ENC_DOUT,
        DOUT1           => ERROR1_ENC_DOUT,
        DIN0            => ERROR0_ENC_DIN,
        DIN1            => (OTHERS => '0')
    );
    ------------------------------------------------------------------------------    
    
    
    -- PUBLIC KEY ----------------------------------------------------------------
    BRAM_PK : ENTITY work.BIKE_BRAM_SP
    GENERIC MAP(OUTPUT_BRAM => 0)
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => PK_IN_VALID,
        -- SAMPLING --------------------
        REN_SAMP        => PK_IN_VALID,
        WEN_SAMP        => PK_IN_VALID,
        ADDR_SAMP       => PK_IN_ADDR,
        DOUT_SAMP       => OPEN,
        DIN_SAMP        => PK_IN_DIN,
        -- COMPUTATION -----------------
        WEN             => PK_WREN,
        REN             => PK_RDEN,
        ADDR            => PK_ADDR,
        DOUT            => PK_DOUT,
        DIN             => PK_DIN
    );
    ------------------------------------------------------------------------------
    
    
    -- ENCODING ------------------------------------------------------------------        
    ENCODE : ENTITY work.BIKE_MULTIPLIER
    PORT MAP ( 
        CLK             => CLK,
        -- CONTROL PORTS ---------------    
        RESET           => ENCODE_RST,
        ENABLE          => ENCODE_EN,
        DONE            => ENCODE_DONE,
        -- RESULT ----------------------
        RESULT_RDEN     => ERROR0_ENC_RDEN,
        RESULT_WREN     => ERROR0_ENC_WREN,
        RESULT_ADDR     => ERROR0_ENC_ADDR,
        RESULT_DOUT_0   => ERROR0_ENC_DIN,
        RESULT_DIN_0    => ERROR0_ENC_DOUT,
        -- PUBLIC KEY ------------------
        K_RDEN          => PK_RDEN,
        K_WREN          => PK_WREN,
        K_ADDR          => PK_ADDR,
        K_DOUT_0        => PK_DIN,
        K_DIN_0         => PK_DOUT,
        -- ERROR -----------------------
        M_RDEN          => ERROR1_ENC_RDEN,
        M_ADDR          => ERROR1_ENC_ADDR,
        M_DIN           => ERROR1_ENC_DOUT  
    );
    ------------------------------------------------------------------------------


    -- HASHING -------------------------------------------------------------------
    -- L-Function
    EC0_RDEN <= ERROR0_SAMPLE_RDEN WHEN ERROR_SAMPLE_EN = '1' ELSE ERROR0_L_RDEN;
    EC1_RDEN <= ERROR1_SAMPLE_RDEN WHEN ERROR_SAMPLE_EN = '1' ELSE ERROR1_L_RDEN;

    EC0_WREN <= ERROR0_SAMPLE_WREN WHEN ERROR_SAMPLE_EN = '1' ELSE '0';
    EC1_WREN <= ERROR1_SAMPLE_WREN WHEN ERROR_SAMPLE_EN = '1' ELSE '0';    
    
    EC0_ADDR <= ERROR_SAMPLE_ADDR WHEN ERROR_SAMPLE_EN = '1' ELSE ERROR0_L_ADDR; 
    EC1_ADDR <= ERROR_SAMPLE_ADDR WHEN ERROR_SAMPLE_EN = '1' ELSE ERROR1_L_ADDR; 
    
    EC0_DIN <= ERROR_SAMPLE_DOUT WHEN ERROR_SAMPLE_EN = '1' ELSE (OTHERS => '0'); 
    EC1_DIN <= ERROR_SAMPLE_DOUT WHEN ERROR_SAMPLE_EN = '1' ELSE (OTHERS => '0'); 
    
    BRAM_EC : ENTITY work.BIKE_BRAM
    GENERIC MAP (
        OUTPUT_BRAM     => 1
    )
    PORT MAP (
        -- CONTROL PORTS ----------------
        CLK             => CLK,     
        RESET           => RESET,
        SAMPLING        => '1',
        -- SAMPLING --------------------
        REN0_SAMP       => EC0_RDEN,
        REN1_SAMP       => EC1_RDEN,
        WEN0_SAMP       => EC0_WREN,
        WEN1_SAMP       => EC1_WREN,
        ADDR0_SAMP      => EC0_ADDR,
        ADDR1_SAMP      => EC1_ADDR,
        DOUT0_SAMP      => EC0_DOUT,
        DOUT1_SAMP      => EC1_DOUT,
        DIN0_SAMP       => EC0_DIN,
        DIN1_SAMP       => EC1_DIN,
        -- COMPUTATION -----------------
        WEN0            => '0',
        WEN1            => '0',
        REN0            => '0',
        REN1            => '0',
        ADDR0           => (OTHERS => '0'),
        ADDR1           => (OTHERS => '0'),
        DOUT0           => OPEN,
        DOUT1           => OPEN,
        DIN0            => (OTHERS => '0'),
        DIN1            => (OTHERS => '0')
    );
    
    HASH_ERROR : ENTITY work.BIKE_HASH_ERROR
    PORT MAP(
        CLK                 => CLK,
        -- CONTROL PORTS ---------------    
        RESET               => RESET,
        HASH_EN             => HASH_L_EN,
        HASH_DONE           => SHA_DONE,
        -- ERROR BRAM ------------------
        ERROR0_RDEN         => ERROR0_L_RDEN,
        ERROR1_RDEN         => ERROR1_L_RDEN,
        ERROR0_ADDR         => ERROR0_L_ADDR,
        ERROR1_ADDR         => ERROR1_L_ADDR,
        ERROR0_DIN          => EC0_DOUT,
        ERROR1_DIN          => EC1_DOUT,
        -- KECCAK ----------------------
        HASH_M              => HASH_L_M,
        HASH_VALID          => HASH_L_VALID,
        HASH_RDY            => HASH_L_RDY
    );

    -- K-Function
    HASH_MC : ENTITY work.BIKE_HASH_MC
    PORT MAP(
        CLK                 => CLK,
        -- CONTROL PORTS ---------------    
        RESET               => RESET,
        HASH_EN             => HASH_K_EN,
        -- DATA ------------------------
        MESSAGE             => M_REG_OUT,
        C1                  => C1_REG_OUT,
        C0_RDEN             => C0_HASH_RDEN,
        C0_ADDR             => C0_HASH_ADDR,
        C0                  => ERROR0_SAMPLE_DIN,
        -- HASH K ----------------------
        HASH_M              => HASH_K_M,
        HASH_VALID          => HASH_K_VALID,
        HASH_RDY            => HASH_K_RDY    
    );
        
    -- set hash size
    WITH HASH_SELECTION SELECT HASH_SIZE <=
        STD_LOGIC_VECTOR(TO_UNSIGNED(2*CEIL(R_BITS,8)*8,20))        WHEN "10",
        STD_LOGIC_VECTOR(TO_UNSIGNED(CEIL(R_BITS,8)*8 + 2*L,20))    WHEN "11",
        (OTHERS => '0')                                             WHEN OTHERS;
    
    -- assign correct input
    WITH HASH_SELECTION SELECT SHA_M <=
        HASH_L_M        WHEN "10",
        HASH_K_M        WHEN "11",
        (OTHERS => '0') WHEN OTHERS;

    WITH HASH_SELECTION SELECT SHA_M_VALID <=
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
    
    K_VALID <= SHA_HASH_VALID   WHEN HASH_K_EN = '1' ELSE '0';
    K_OUT   <= SHA_HASH         WHEN HASH_K_EN = '1' ELSE (OTHERS => '0'); 
    ------------------------------------------------------------------------------


    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET            =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';
                    
                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';
                    
                    HASH_L_EN           <= '0';
                    
                    HASH_K_EN           <= '0';  
                       
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0';   
                                        
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN
                        STATE           <= S_SAMPLE_M;
                    ELSE
                        STATE           <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_SAMPLE_M           =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '0';
                    M_SAMPLE_ENABLE     <= '1';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';
                    
                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';

                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0'; 
                                                            
                    -- TRANSITION ------
                    IF (M_SAMPLE_DONE = '1') THEN
                        STATE           <= S_SAMPLE_E;
                    ELSE
                        STATE           <= S_SAMPLE_M;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_SAMPLE_E           =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '1';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';

                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0'; 
                                                            
                    -- TRANSITION ------
                    IF (ERROR_SAMPLE_DONE = '1') THEN
                        STATE           <= S_HASH_AND_ENCODE;
                    ELSE
                        STATE           <= S_SAMPLE_E;
                    END IF;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_HASH_AND_ENCODE  =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '0';
                    ENCODE_EN           <= '1';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '0';
                    SHA_ENABLE          <= '1';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '1';
                    
                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "10";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0';
                                                            
                    -- TRANSITION ------
                    IF (SHA_DONE = '1') THEN
                        STATE           <= S_ENCODE; 
                    ELSE
                        STATE           <= S_HASH_AND_ENCODE;
                    END IF;
                ----------------------------------------------     
                                
                ----------------------------------------------
                WHEN S_ENCODE           =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '0';
                    ENCODE_EN           <= '1';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';

                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0';
                                                            
                    -- TRANSITION ------
                    IF (ENCODE_DONE = '1') THEN
                        STATE           <= S_HASH_K; 
                    ELSE
                        STATE           <= S_ENCODE;
                    END IF;
                ----------------------------------------------                

                ----------------------------------------------
                WHEN S_HASH_K           =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '0';
                    SHA_ENABLE          <= '1';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';
                    
                    HASH_K_EN           <= '1';     
                    HASH_SELECTION      <= "11";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0';
                                                            
                    -- TRANSITION ------
                    IF (SHA_DONE = '1') THEN  
                        STATE           <= S_OUTPUT_C0_INIT; 
                    ELSE
                        STATE           <= S_HASH_K;
                    END IF;
                ----------------------------------------------    

                ----------------------------------------------
                WHEN S_OUTPUT_C0_INIT =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';
                    
                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '0';
                    CNT_OUT_EN          <= '1';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '1'; 
                    EN_OUT_C1           <= '0';
                                        
                    -- TRANSITION ------
                    STATE               <= S_OUTPUT_C0;
                ----------------------------------------------
                                                                
                ----------------------------------------------
                WHEN S_OUTPUT_C0        =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '1';

                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';
                    
                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '0';
                    CNT_OUT_EN          <= '1';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '1'; 
                    EN_OUT_C1           <= '0';
                                        
                    -- TRANSITION ------
                    IF (CNT_OUT_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(R_BLOCKS-1, LOG2(R_BLOCKS)))) THEN
                        --STATE           <= S_DONE;
                        STATE           <= S_OUTPUT_C1;
                    ELSE
                        STATE           <= S_OUTPUT_C0;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_OUTPUT_C1        =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '1';
    
                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';
                    
                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '0';
                    CNT_REG_EN          <= '1';
                    
                    OUTPUT_EN           <= '1'; 
                    EN_OUT_C1           <= '1';
                                        
                    -- TRANSITION ------
                    IF (CNT_REG_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(6, LOG2(CEIL(L,32))))) THEN
                        STATE           <= S_DONE;
                    ELSE
                        STATE           <= S_OUTPUT_C1;
                    END IF;
                ----------------------------------------------
                                
                ----------------------------------------------
                WHEN S_DONE             =>
                    -- GLOBAL ----------
                    ENCAPS_DONE         <= '0';
    
                    -- SAMPLE ----------
                    M_SAMPLE_RESET      <= '1';
                    M_SAMPLE_ENABLE     <= '0';
                    ERROR_SAMPLE_EN     <= '0';
                    
                    -- ENCODE ----------
                    ENCODE_RST          <= '1';
                    ENCODE_EN           <= '0';
                    
                    -- HASH ------------                   
                    SHA_RESET           <= '1';
                    SHA_ENABLE          <= '0';

                    CNT_REGH_RST        <= '1';
                    CNT_REGH_EN         <= '0';                    
                    
                    HASH_L_EN           <= '0';
                    
                    HASH_K_EN           <= '0';     
                    HASH_SELECTION      <= "00";    
                    
                    -- OUTPUT
                    CNT_OUT_RESET       <= '1';
                    CNT_OUT_EN          <= '0';
                    
                    CNT_REG_RESET       <= '1';
                    CNT_REG_EN          <= '0';
                    
                    OUTPUT_EN           <= '0'; 
                    EN_OUT_C1           <= '0';
                                        
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
