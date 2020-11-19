-- IMPORTS
-------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.MATH_REAL.ALL;
    USE IEEE.NUMERIC_STD.ALL;
    USE IEEE.STD_LOGIC_1164.ALL;

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;


-- ENTITY
-------------------------------------------------------------------------------
ENTITY BIKE_SYNDROME IS
    PORT (
        CLK      : IN  STD_LOGIC;
        -- CONTROL PORTS
        RESET    : IN  STD_LOGIC;
        ENABLE   : IN  STD_LOGIC;
        DONE     : OUT STD_LOGIC;
        VALID    : OUT STD_LOGIC;
        FIRST    : OUT STD_LOGIC;
        -- CRYPTOGRAM
        C_RDEN   : OUT STD_LOGIC; -- Vector
        C_ADDR   : OUT STD_LOGIC_VECTOR(LOG2(WORDS) - 1 DOWNTO 0);
        C_DIN_0  : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        C_DIN_1  : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        -- ERROR
--        E_RDEN   : OUT STD_LOGIC;
--        E_ADDR   : OUT STD_LOGIC_VECTOR(LOG2(WORDS) - 1 DOWNTO 0);
--        E_DIN_0  : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
--        E_DIN_1  : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        -- PRIVATE KEY
        H_RDEN   : OUT STD_LOGIC; -- Matrix
        H_WREN   : OUT STD_LOGIC;
        H_ADDR   : OUT STD_LOGIC_VECTOR(LOG2(WORDS) - 1 DOWNTO 0);
        H_DOUT_0 : OUT STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        H_DOUT_1 : OUT STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        H_DIN_0  : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        H_DIN_1  : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        -- SYNDROME
        S_RDEN   : OUT STD_LOGIC; -- Result
        S_WREN   : OUT STD_LOGIC;
        S_ADDR   : OUT STD_LOGIC_VECTOR(LOG2(WORDS) - 1 DOWNTO 0);
        S_DOUT   : OUT STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
        S_DIN    : IN  STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0)
    );
END ENTITY;


-- ARCHITECTURE
-------------------------------------------------------------------------------
ARCHITECTURE DEFAULT OF BIKE_SYNDROME IS
    -- CONSTANTS --------------------------------------------------------------
    CONSTANT WORDS    : NATURAL := CEIL(R_BITS, B_WIDTH);
    CONSTANT OVERHANG : NATURAL := R_BITS - B_WIDTH * (WORDS - 1);

    -- INPUT BUFFERING --------------------------------------------------------
    SIGNAL RST, EN            : STD_LOGIC;
    SIGNAL C_DINBUF_0         : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL C_DINBUF_1         : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL E_DINBUF_0         : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL E_DINBUF_1         : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL H_DINBUF_0         : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL H_DINBUF_1         : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL S_DINBUF           : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);

    -- CONTROL ----------------------------------------------------------------
    SIGNAL WRITE_LAST         : STD_LOGIC;
    SIGNAL WRITE_LASTCOL      : STD_LOGIC;
    SIGNAL WRITE_LASTOH       : STD_LOGIC;
    SIGNAL WRITE_FRAC         : STD_LOGIC;
    SIGNAL SEL_ADD            : STD_LOGIC;
    SIGNAL SEL_LOW, SEL_LOW_D : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- COUNTER ----------------------------------------------------------------
    SIGNAL CNT_ROW_EN, CNT_ROW_RST                 : STD_LOGIC;
    SIGNAL CNT_COL_EN, CNT_COL_RST                 : STD_LOGIC;
    SIGNAL CNT_SHIFT_EN, CNT_SHIFT_RST             : STD_LOGIC;
    SIGNAL CNT_ROW_OUT, CNT_COL_OUT, CNT_SHIFT_OUT : STD_LOGIC_VECTOR(LOG2(WORDS) - 1 DOWNTO 0);

    -- KEY --------------------------------------------------------------------
    SIGNAL H_ADDR_INT                               : STD_LOGIC_VECTOR(LOG2(WORDS) - 1 DOWNTO 0);
    SIGNAL H_PREV_0, H_PREV_1                       : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL H_LASTOH_0, H_LASTOH_1                   : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);

    -- INTERMEDIATE REGISTER --------------------------------------------------
    SIGNAL INT_IN_0, INT_OUT_0                      : STD_LOGIC_VECTOR(B_WIDTH-2 DOWNTO 0);
    SIGNAL INT_IN_1, INT_OUT_1                      : STD_LOGIC_VECTOR(B_WIDTH-2 DOWNTO 0);

    -- MULTIPLIER -------------------------------------------------------------
    SIGNAL RESULT_SUBARRAY_0, RESULT_SUBARRAY_1     : STD_LOGIC_VECTOR(B_WIDTH * B_WIDTH - 1 DOWNTO 0);
    SIGNAL RESULT_UPPER_SUBARRAY_REORDERED_0        : STD_LOGIC_VECTOR(B_WIDTH * (B_WIDTH + 1) / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_UPPER_SUBARRAY_REORDERED_1        : STD_LOGIC_VECTOR(B_WIDTH * (B_WIDTH + 1) / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_0        : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_1        : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_INIT1_0  : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_INIT1_1  : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0  : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RESULT_LOWER_SUBARRAY_REORDERED_INIT2_1  : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RESULT_TRAPEZOIDAL_UPPER_ADDITION_0      : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL RESULT_TRAPEZOIDAL_UPPER_ADDITION_1      : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL RESULT_UPPER_INT_ADD_0                   : STD_LOGIC_VECTOR(B_WIDTH * (B_WIDTH + 1) / 2 - 1 DOWNTO 0); 
    SIGNAL RESULT_UPPER_INT_ADD_1                   : STD_LOGIC_VECTOR(B_WIDTH * (B_WIDTH + 1) / 2 - 1 DOWNTO 0); 
    SIGNAL RESULT_LOWER_SUBARRAY_ADD_IN_0           : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_LOWER_SUBARRAY_ADD_IN_1           : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_TRAPEZOIDAL_LOWER_ADDITION_0      : STD_LOGIC_VECTOR(B_WIDTH - 2 DOWNTO 0);
    SIGNAL RESULT_TRAPEZOIDAL_LOWER_ADDITION_1      : STD_LOGIC_VECTOR(B_WIDTH - 2 DOWNTO 0);
    SIGNAL RESULT_LOWER_INT_ADD_0                   : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_LOWER_INT_ADD_1                   : STD_LOGIC_VECTOR((B_WIDTH - 1) * B_WIDTH / 2 - 1 DOWNTO 0);
    SIGNAL RESULT_DOUT_0                            : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL RESULT_DOUT_1                            : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL RESULT_DOUT_ADD                          : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL RESULT_DOUT                              : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL S_PREV                                   : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    SIGNAL S_DOUT_PREV, S_DOUT_PREV_GATED           : STD_LOGIC_VECTOR(B_WIDTH - 1 DOWNTO 0);
    
    -- VALID
    SIGNAL VALID_IN, VALID_OUT : STD_LOGIC;

    -- STATES -----------------------------------------------------------------
    TYPE STATES IS (S_RESET, S_READ_SECOND_LAST, S_READ_LAST, S_FIRST_COLUMN, S_COLUMN, S_SWITCH_COLUMN, S_READ_LASTCOL, S_WRITE_LASTCOL, S_ALMOST_DONE, S_DONE);
    SIGNAL STATE : STATES;
BEGIN
    -- INPUT BUFFERING --------------------------------------------------------
    RST        <= RESET;
    EN         <= ENABLE;
    C_DINBUF_0 <= C_DIN_0;
    C_DINBUF_1 <= C_DIN_1;
    --E_DINBUF_0 <= E_DIN_0;
    --E_DINBUF_1 <= E_DIN_1;
    H_DINBUF_0 <= H_DIN_0;
    H_DINBUF_1 <= H_DIN_1;
    S_DINBUF   <= S_DIN;


    -- PRIVATE KEY ------------------------------------------------------------
    H_DOUT_0 <= H_DINBUF_0(OVERHANG - 1 DOWNTO 0) & H_PREV_0(B_WIDTH - 1 DOWNTO OVERHANG) WHEN WRITE_LAST = '1' ELSE
                H_DINBUF_0(B_WIDTH - OVERHANG - 1 DOWNTO 0) & H_PREV_0(B_WIDTH - 1 DOWNTO B_WIDTH - OVERHANG) WHEN WRITE_LASTCOL = '1' ELSE
                H_LASTOH_0 WHEN WRITE_LASTOH = '1' ELSE
                H_DINBUF_0;
    H_DOUT_1 <= H_DINBUF_1(OVERHANG - 1 DOWNTO 0) & H_PREV_1(B_WIDTH - 1 DOWNTO OVERHANG) WHEN WRITE_LAST = '1' ELSE
                H_DINBUF_1(B_WIDTH - OVERHANG - 1 DOWNTO 0) & H_PREV_1(B_WIDTH - 1 DOWNTO B_WIDTH - OVERHANG) WHEN WRITE_LASTCOL = '1' ELSE
                H_LASTOH_1 WHEN WRITE_LASTOH = '1' ELSE
                H_DINBUF_1;

    H_LASTOH_0(B_WIDTH - 1 DOWNTO OVERHANG) <= (OTHERS => '0');
    H_LASTOH_0(OVERHANG - 1 DOWNTO 0)       <= H_PREV_0(B_WIDTH - 1 DOWNTO B_WIDTH - OVERHANG);
    H_LASTOH_1(B_WIDTH - 1 DOWNTO OVERHANG) <= (OTHERS => '0');
    H_LASTOH_1(OVERHANG - 1 DOWNTO 0)       <= H_PREV_0(B_WIDTH - 1 DOWNTO B_WIDTH - OVERHANG);

    -- REGISTER ---------------------------------------------------------------
    REG_H0_MSBs : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH)
    PORT MAP (D => H_DINBUF_0, Q => H_PREV_0, CLK => CLK, EN => EN, RST => RST);

    REG_H1_MSBs : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH)
    PORT MAP (D => H_DINBUF_1, Q => H_PREV_1, CLK => CLK, EN => EN, RST => RST);

    -- ADDRESSES --------------------------------------------------------------
    C_ADDR <= CNT_COL_OUT;
    --E_ADDR <= CNT_COL_OUT;
    H_ADDR <= (OTHERS => '0') WHEN WRITE_LAST = '1' ELSE (H_ADDR_INT);
    S_ADDR <= CNT_SHIFT_OUT;

    WITH SEL_LOW SELECT H_ADDR_INT <=
        (OTHERS => '0') WHEN "00",
        STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS - 2, LOG2(WORDS))) WHEN "01",
        STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS - 1, LOG2(WORDS))) WHEN "10",
        CNT_ROW_OUT WHEN "11",
        (OTHERS => '0') WHEN OTHERS;

    -- MULTIPLIER -------------------------------------------------------------
    L_MULT : FOR I IN 0 TO B_WIDTH - 1
    GENERATE
        --RESULT_SUBARRAY_0((I + 1) * B_WIDTH - 1 DOWNTO I * B_WIDTH) <= H_DINBUF_0 WHEN (C_DINBUF_0(I) XOR E_DINBUF_0(I)) = '1' ELSE (OTHERS => '0');
        RESULT_SUBARRAY_0((I + 1) * B_WIDTH - 1 DOWNTO I * B_WIDTH) <= H_DINBUF_0 WHEN C_DINBUF_0(I) = '1' ELSE (OTHERS => '0');
        --RESULT_SUBARRAY_1((I + 1) * B_WIDTH - 1 DOWNTO I * B_WIDTH) <= H_DINBUF_1 WHEN (C_DINBUF_1(I) XOR E_DINBUF_1(I)) = '1' ELSE (OTHERS => '0');
        RESULT_SUBARRAY_1((I + 1) * B_WIDTH - 1 DOWNTO I * B_WIDTH) <= H_DINBUF_1 WHEN C_DINBUF_1(I) = '1' ELSE (OTHERS => '0');
    END GENERATE;

    -- REORDERING -------------------------------------------------------------
    -- UPPER REGULAR TRIANGLE
    L_RE_UP0 : FOR R IN 0 TO B_WIDTH - 1
    GENERATE
        L_RE_UP1 : FOR C IN 0 TO R
        GENERATE
            RESULT_UPPER_SUBARRAY_REORDERED_0(R * (R + 1) / 2 + C) <= RESULT_SUBARRAY_0(C * B_WIDTH + R - C);
            RESULT_UPPER_SUBARRAY_REORDERED_1(R * (R + 1) / 2 + C) <= RESULT_SUBARRAY_1(C * B_WIDTH + R - C);
        END GENERATE;
    END GENERATE;

    -- LOWER REGULAR TRIANGLE
    L_RE_LOW0 : FOR R IN 0 TO B_WIDTH - 2
    GENERATE
        L_RE_LOW1 : FOR C IN 0 TO B_WIDTH - 2 - R
        GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2 + C) <= RESULT_SUBARRAY_0((B_WIDTH -1 - C) * B_WIDTH + R + C + 1);
            RESULT_LOWER_SUBARRAY_REORDERED_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2 + C) <= RESULT_SUBARRAY_1((B_WIDTH -1 - C) * B_WIDTH + R + C + 1);
        END GENERATE;
    END GENERATE;

    -- GENERATE UPPER TRIANGLE FOR INITIAL PHASE
    L_RE_INIT0 : FOR R IN 0 TO B_WIDTH - OVERHANG - 2
    GENERATE
        L_RE_INIT1 : FOR C IN 0 TO B_WIDTH - OVERHANG - 2 - R
        GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_INIT1_0(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2) + C) <= RESULT_LOWER_SUBARRAY_REORDERED_0((B_WIDTH - 1) * (B_WIDTH) / 2 - (B_WIDTH - OVERHANG - 1 - R) * (B_WIDTH - OVERHANG - R) / 2 + C);
            RESULT_LOWER_SUBARRAY_REORDERED_INIT1_1(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2) + C) <= RESULT_LOWER_SUBARRAY_REORDERED_1((B_WIDTH - 1) * (B_WIDTH) / 2 - (B_WIDTH - OVERHANG - 1 - R) * (B_WIDTH - OVERHANG - R) / 2 + C);
        END GENERATE;
    END GENERATE;

    -- GENERATE LOWER TRAPEZOID FOR INITIAL PHASE
    L_RE_INIT2 : FOR R IN 0 TO B_WIDTH - OVERHANG - 2
    GENERATE
        L_RE_INIT3 : FOR C IN B_WIDTH - 1 - R - OVERHANG TO B_WIDTH - 2 - R
        GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2) + C) <= RESULT_SUBARRAY_0((C - (B_WIDTH - 1 - R - OVERHANG)) + B_WIDTH * (OVERHANG + (B_WIDTH - 1 - OVERHANG - C)));
            RESULT_LOWER_SUBARRAY_REORDERED_INIT2_1(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2) + C) <= RESULT_SUBARRAY_1((C - (B_WIDTH - 1 - R - OVERHANG)) + B_WIDTH * (OVERHANG + (B_WIDTH - 1 - OVERHANG - C)));
        END GENERATE;
    END GENERATE;

    L_RE_INIT4 : FOR R IN B_WIDTH - OVERHANG - 1 TO B_WIDTH - 2
    GENERATE
        L_RE_INIT5 : FOR C IN 0 TO B_WIDTH - 2 - R
        GENERATE
            RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2) + C) <= RESULT_SUBARRAY_0((C - (B_WIDTH - 1 - R - OVERHANG)) + B_WIDTH * (OVERHANG + (B_WIDTH - 1 - OVERHANG - C)));
            RESULT_LOWER_SUBARRAY_REORDERED_INIT2_1(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2) + C) <= RESULT_SUBARRAY_1((C - (B_WIDTH - 1 - R - OVERHANG)) + B_WIDTH * (OVERHANG + (B_WIDTH - 1 - OVERHANG - C)));
        END GENERATE;
    END GENERATE;

    L_RE_INIT6 : FOR R IN 0 TO B_WIDTH - OVERHANG - 2
    GENERATE
        RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2)) <= INT_OUT_0(R);
        RESULT_LOWER_SUBARRAY_REORDERED_INIT2_1(((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - R) * (B_WIDTH - R) / 2)) <= INT_OUT_1(R);
    END GENERATE;

    -- ADDITION ---------------------------------------------------------------
    -- UPPER ADDITION
    RESULT_TRAPEZOIDAL_UPPER_ADDITION_0(0) <= RESULT_UPPER_SUBARRAY_REORDERED_0(0); 
    RESULT_TRAPEZOIDAL_UPPER_ADDITION_1(0) <= RESULT_UPPER_SUBARRAY_REORDERED_1(0); 

    RESULT_UPPER_INT_ADD_0(0) <= '0'; -- never used
    RESULT_UPPER_INT_ADD_1(0) <= '0'; -- never used

    L_UPPER_ADD : FOR I IN 1 TO B_WIDTH - 1
    GENERATE
        RESULT_UPPER_INT_ADD_0(I * (I + 1) / 2) <= RESULT_UPPER_SUBARRAY_REORDERED_0(I * (I + 1) / 2);
        RESULT_UPPER_INT_ADD_1(I * (I + 1) / 2) <= RESULT_UPPER_SUBARRAY_REORDERED_1(I * (I + 1) / 2);
        LO : FOR R IN 1 TO I
        GENERATE
            RESULT_UPPER_INT_ADD_0(I * (I + 1) / 2 + R) <= RESULT_UPPER_INT_ADD_0(I * (I + 1) / 2 + R - 1) XOR RESULT_UPPER_SUBARRAY_REORDERED_0(I * (I + 1) / 2 + R);
            RESULT_UPPER_INT_ADD_1(I * (I + 1) / 2 + R) <= RESULT_UPPER_INT_ADD_1(I * (I + 1) / 2 + R - 1) XOR RESULT_UPPER_SUBARRAY_REORDERED_1(I * (I + 1) / 2 + R);
        END GENERATE;
        RESULT_TRAPEZOIDAL_UPPER_ADDITION_0(I) <= RESULT_UPPER_INT_ADD_0(I * (I + 1) / 2 + I);
        RESULT_TRAPEZOIDAL_UPPER_ADDITION_1(I) <= RESULT_UPPER_INT_ADD_1(I * (I + 1) / 2 + I);
    END GENERATE;

    -- LOWER ADDITION
    SEL_REG : ENTITY work.RegisterFDRE GENERIC MAP (SIZE => 2)
    PORT MAP (D => SEL_LOW, Q => SEL_LOW_D, CLK => CLK, EN => EN, RST => RST);

    WITH SEL_LOW_D SELECT RESULT_LOWER_SUBARRAY_ADD_IN_0 <=
        (OTHERS => '0') WHEN "00",
        RESULT_LOWER_SUBARRAY_REORDERED_INIT1_0 WHEN "01",
        RESULT_LOWER_SUBARRAY_REORDERED_INIT2_0 WHEN "10",
        RESULT_LOWER_SUBARRAY_REORDERED_0 WHEN "11",
        (OTHERS => '0') WHEN OTHERS;

    WITH SEL_LOW_D SELECT RESULT_LOWER_SUBARRAY_ADD_IN_1 <=
        (OTHERS => '0') WHEN "00",
        RESULT_LOWER_SUBARRAY_REORDERED_INIT1_1 WHEN "01",
        RESULT_LOWER_SUBARRAY_REORDERED_INIT2_1 WHEN "10",
        RESULT_LOWER_SUBARRAY_REORDERED_1 WHEN "11",
        (OTHERS => '0') WHEN OTHERS;

    RESULT_TRAPEZOIDAL_LOWER_ADDITION_0(B_WIDTH - 2) <= RESULT_LOWER_SUBARRAY_ADD_IN_0((B_WIDTH - 1) * (B_WIDTH) / 2 - 1);
    RESULT_TRAPEZOIDAL_LOWER_ADDITION_1(B_WIDTH - 2) <= RESULT_LOWER_SUBARRAY_ADD_IN_1((B_WIDTH - 1) * (B_WIDTH) / 2 - 1);

    RESULT_LOWER_INT_ADD_0((B_WIDTH - 1) * (B_WIDTH) / 2 - 1) <= '0';
    RESULT_LOWER_INT_ADD_1((B_WIDTH - 1) * (B_WIDTH) / 2 - 1) <= '0';

    L_LOWER_ADD : FOR I IN 0 TO B_WIDTH - 3 GENERATE
        RESULT_LOWER_INT_ADD_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2) <= RESULT_LOWER_SUBARRAY_ADD_IN_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2);
        RESULT_LOWER_INT_ADD_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2) <= RESULT_LOWER_SUBARRAY_ADD_IN_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2);
        L_LOWERO : FOR R IN 1 TO B_WIDTH - 2 - I GENERATE
            RESULT_LOWER_INT_ADD_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + R) <= RESULT_LOWER_INT_ADD_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + R - 1) XOR RESULT_LOWER_SUBARRAY_ADD_IN_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + R);
            RESULT_LOWER_INT_ADD_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + R) <= RESULT_LOWER_INT_ADD_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + R - 1) XOR RESULT_LOWER_SUBARRAY_ADD_IN_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + R);
        END GENERATE;
        RESULT_TRAPEZOIDAL_LOWER_ADDITION_0(I) <= RESULT_LOWER_INT_ADD_0((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + B_WIDTH - 2 - I);
        RESULT_TRAPEZOIDAL_LOWER_ADDITION_1(I) <= RESULT_LOWER_INT_ADD_1((B_WIDTH - 1) * B_WIDTH / 2 - (B_WIDTH - 1 - (I)) * (B_WIDTH - (I)) / 2 + B_WIDTH - 2 - I);
    END GENERATE;

    -- FINAL ADDITION 
    WRITE_FRAC <= '1' WHEN CNT_ROW_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS, LOG2(WORDS))) ELSE '0';

    --S_PREV <= (OTHERS => '0') WHEN CNT_COL_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(WORDS))) ELSE S_DINBUF;
    S_PREV <= S_DINBUF;
    RESULT_DOUT_0 <= RESULT_TRAPEZOIDAL_UPPER_ADDITION_0 XOR ('0' & INT_OUT_0);
    RESULT_DOUT_1 <= RESULT_TRAPEZOIDAL_UPPER_ADDITION_1 XOR ('0' & INT_OUT_1);
    
    --RESULT_DOUT_ADD <= S_PREV XOR RESULT_DOUT_0; -- XOR RESULT_DOUT_1;
    RESULT_DOUT_ADD <= S_PREV XOR RESULT_DOUT_0 XOR RESULT_DOUT_1;
    
    -- RESULT_DOUT_ADD <= S_DINBUF XOR RESULT_DOUT_0 XOR RESULT_DOUT_1;
    RESULT_DOUT <= RESULT_DOUT_ADD WHEN WRITE_FRAC = '0' ELSE (B_WIDTH-1 DOWNTO OVERHANG => '0') & RESULT_DOUT_ADD(OVERHANG-1 DOWNTO 0);
    
    S_DOUT_PREV_GATED <= S_DOUT_PREV WHEN WRITE_FRAC = '0' ELSE (B_WIDTH-1 DOWNTO OVERHANG => '0') & S_DOUT_PREV(OVERHANG-1 DOWNTO 0);
    S_DOUT <= S_DOUT_PREV_GATED WHEN WRITE_LASTCOL = '1' OR WRITE_LASTOH = '1' ELSE RESULT_DOUT;
    --S_DOUT <= S_DOUT_PREV WHEN WRITE_LASTCOL = '1' OR WRITE_LASTOH = '1' ELSE RESULT_DOUT;
    
    VALID_IN <= '1' WHEN WRITE_LASTCOL = '1' OR WRITE_LASTOH = '1' ELSE '0';
    VALID <= VALID_IN AND VALID_OUT;
    
    FIRST <= '1' WHEN CNT_COL_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(WORDS))) ELSE '0';

    REG_VALID : FDRE GENERIC MAP (INIT => '0')
    PORT MAP (Q	=> VALID_OUT, C	=> CLK, CE => EN, R => RST, D => VALID_IN);
    

    REG_S : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH)
    PORT MAP (D => RESULT_DOUT, Q => S_DOUT_PREV, CLK => CLK, EN => EN, RST => RST);

    -- WRITE INTERMEDIATE RESULT TO REGISTER
    INT_IN_0 <= RESULT_TRAPEZOIDAL_LOWER_ADDITION_0;
    INT_IN_1 <= RESULT_TRAPEZOIDAL_LOWER_ADDITION_1;

    -- INTERMEDIATE REGISTER --------------------------------------------------
    INTERMEDIATE_REG_LO_0 : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH - 1)
    PORT MAP(D => INT_IN_0, Q => INT_OUT_0, CLK => CLK, EN => EN, RST => RST);

    INTERMEDIATE_REG_LO_1 : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => B_WIDTH - 1)
    PORT MAP(D => INT_IN_1, Q => INT_OUT_1, CLK => CLK, EN => EN, RST => RST);

    -- COUNTER ----------------------------------------------------------------
    -- COUNTS THE NUMBER OF FINISHED ROWS (PRIVATE KEY COUNTER)
    ROW_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP(CLK => CLK, EN => CNT_ROW_EN, RST => CNT_ROW_RST, CNT_OUT => CNT_ROW_OUT);

    -- COUNTS THE NUMBER OF FINISHED COLUMNS
    ROL_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS)
    PORT MAP(CLK => CLK, EN => CNT_COL_EN, RST => CNT_COL_RST, CNT_OUT => CNT_COL_OUT);

    -- TRACKS AND COUNTS THE LEAST SIGNIFICANT WORD OD THE RESULT
    SHIFT_COUNTER : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => LOG2(WORDS), MAX_VALUE => WORDS - 1)
    PORT MAP(CLK => CLK, EN => CNT_SHIFT_EN, RST => CNT_SHIFT_RST, CNT_OUT => CNT_SHIFT_OUT);

    -- FINITE STATE MACHINE PROCESS -------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            -- GLOBAL
            DONE          <= '0';

            -- CONTROL
            SEL_LOW       <= "00";
            SEL_ADD       <= '0';
            WRITE_LAST    <= '0';
            WRITE_LASTCOL <= '0';
            WRITE_LASTOH  <= '0';

            -- CRYPTOGRAM
            C_RDEN        <= '0';
            -- ERROR
            --E_RDEN        <= '0';
            -- PRIVATE KEY
            H_RDEN        <= '0';
            H_WREN        <= '0';
            -- SYNDROME
            S_RDEN        <= '0';
            S_WREN        <= '0';

            -- COUNTER
            CNT_ROW_EN    <= '0';
            CNT_ROW_RST   <= '0';
            CNT_COL_EN    <= '0';
            CNT_COL_RST   <= '0';
            CNT_SHIFT_EN  <= '0';
            CNT_SHIFT_RST <= '0';

            IF RST = '1' THEN
                -- COUNTER
                CNT_ROW_RST   <= '1';
                CNT_COL_RST   <= '1';
                CNT_SHIFT_RST <= '1';

                -- STATE
                STATE         <= S_RESET;
            ELSE
                CASE STATE IS
                    WHEN S_RESET =>
                        -- COUNTER
                        CNT_ROW_RST   <= '1';
                        CNT_COL_RST   <= '1';
                        CNT_SHIFT_RST <= '1';

                        -- TRANSITION
                        IF (EN = '1') THEN
                            STATE     <= S_READ_SECOND_LAST;
                        END IF;


                    WHEN S_READ_SECOND_LAST =>
                        -- CONTROL
                        SEL_LOW       <= "01";

                        -- CRYPTOGRAM
                        C_RDEN        <= '1';
                        -- ERROR
                        --E_RDEN        <= '1';
                        -- PRIVATE KEY
                        H_RDEN        <= '1';

                        -- TRANSITION
                        STATE         <= S_READ_LAST;


                    WHEN S_READ_LAST =>
                        -- CONTROL
                        SEL_LOW       <= "10";

                        -- CRYPTOGRAM
                        C_RDEN        <= '1';
                        -- ERROR
                        --E_RDEN        <= '1';
                        -- PRIVATE KEY
                        H_RDEN        <= '1';

                        -- TRANSITION
                        STATE         <= S_FIRST_COLUMN;


                    WHEN S_FIRST_COLUMN =>
                        -- CONTROL
                        SEL_LOW       <= "11";

                        -- CRYPTOGRAM
                        C_RDEN        <= '1';
                        -- ERROR
                        --E_RDEN        <= '1';
                        -- PRIVATE KEY
                        H_RDEN        <= '1';
                        H_WREN        <= '1';
                        -- SYNDROME
                        S_RDEN        <= '1';
                        S_WREN        <= '1';

                        -- COUNTER
                        CNT_ROW_EN    <= '1';
                        CNT_SHIFT_EN  <= '1';

                        -- TRANSITION
                        IF (CNT_COL_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS - 1, LOG2(WORDS)))) THEN
                            STATE     <= S_READ_LASTCOL;
                        ELSE
                            STATE     <= S_COLUMN;
                        END IF;


                    WHEN S_COLUMN =>
                        -- CONTROL
                        SEL_LOW         <= "11";

                        -- CRYPTOGRAM
                        C_RDEN          <= '1';
                        -- ERROR
                        --E_RDEN          <= '1';
                        -- PRIVATE KEY
                        H_RDEN          <= '1';
                        H_WREN          <= '1';
                        -- SYNDROME
                        S_RDEN          <= '1';
                        S_WREN          <= '1';

                        -- COUNTER
                        CNT_ROW_EN      <= '1';
                        CNT_SHIFT_EN    <= '1';

                        -- TRANSITION
                        IF (CNT_ROW_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS - 2, LOG2(WORDS)))) THEN
                            STATE       <= S_SWITCH_COLUMN;
                        ELSE
                            STATE       <= S_COLUMN;
                        END IF;


                    WHEN S_SWITCH_COLUMN =>
                        -- CONTROL
                        SEL_LOW       <= "11";
                        WRITE_LAST    <= '1';

                        -- CRYPTOGRAM
                        C_RDEN        <= '1';
                        -- ERROR
                        --E_RDEN        <= '1';
                        -- PRIVATE KEY
                        H_RDEN        <= '1';
                        H_WREN        <= '1';
                        -- SYNDROME
                        S_RDEN        <= '1';
                        S_WREN        <= '1';

                        -- COUNTER
                        CNT_ROW_RST   <= '1';
                        CNT_COL_EN    <= '1';
                        CNT_SHIFT_EN  <= '1';

                        -- TRANSITION
                        STATE         <= S_READ_SECOND_LAST;


                    WHEN S_READ_LASTCOL =>
                        -- CONTROL
                        SEL_LOW       <= "11";
                        SEL_ADD       <= '1';
                        WRITE_LASTCOL <= '1';

                        -- CRYPTOGRAM
                        C_RDEN        <= '1';
                        -- ERROR
                        --E_RDEN        <= '1';
                        -- PRIVATE KEY
                        H_RDEN        <= '1';
                        -- SYNDROME
                        S_RDEN        <= '1';
                        S_WREN        <= '1';

                        -- TRANSITION
                        STATE         <= S_WRITE_LASTCOL;


                    WHEN S_WRITE_LASTCOL =>
                        -- CONTROL
                        SEL_LOW       <= "11";
                        SEL_ADD       <= '1';
                        WRITE_LASTCOL <= '1';

                        -- CRYPTOGRAM
                        C_RDEN        <= '1';
                        -- ERROR
                        --E_RDEN        <= '1';
                        -- PRIVATE KEY
                        H_RDEN        <= '1';
                        H_WREN        <= '1';
                        -- SYNDROME
                        S_RDEN        <= '1';
                        IF (CNT_SHIFT_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(0, LOG2(WORDS)))) THEN
                            S_WREN    <= '1';
                        END IF;

                        -- COUNTER
                        CNT_ROW_EN    <= '1';
                        CNT_SHIFT_EN  <= '1';

                        -- TRANSITION
                        IF (CNT_ROW_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(WORDS - 1, LOG2(WORDS)))) THEN
                            STATE     <= S_ALMOST_DONE;
                        ELSE
                            STATE     <= S_READ_LASTCOL;
                        END IF;


                    WHEN S_ALMOST_DONE =>
                        -- CONTROL
                        WRITE_LASTOH  <= '1';

                        -- SYNDROME
                        S_RDEN        <= '1';
                        S_WREN        <= '1';

                        -- TRANSITION
                        STATE         <= S_DONE;


                    WHEN S_DONE =>
                        -- GLOBAL
                        DONE          <= '1';
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;

