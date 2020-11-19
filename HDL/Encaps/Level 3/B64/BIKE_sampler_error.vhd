----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    BIKE_SAMPLER_ERROR
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

LIBRARY UNISIM;
    USE UNISIM.VCOMPONENTS.ALL;
    
LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_SAMPLER_ERROR IS
    GENERIC (
        THRESHOLD       : INTEGER := 10
    );
	PORT (  
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        DONE            : OUT STD_LOGIC;
        -- RAND ------------------------
        AES_KEY         : IN  STD_LOGIC_VECTOR(255 DOWNTO 0);
        -- MEMORY I/O ------------------
        RDEN_1          : OUT STD_LOGIC;
        WREN_1          : OUT STD_LOGIC;
        RDEN_2          : OUT STD_LOGIC;
        WREN_2          : OUT STD_LOGIC;
        ADDR            : OUT STD_LOGIC_VECTOR(LOG2(R_BLOCKS)-1 DOWNTO 0);
        DOUT            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN_1           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN_2           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END BIKE_SAMPLER_ERROR;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_SAMPLER_ERROR IS



-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_RESET, CNT_ENABLE, CNT_VALID : STD_LOGIC;
SIGNAL CNT_OUT                          : STD_LOGIC_VECTOR(LOG2(THRESHOLD+1)-1 DOWNTO 0);

SIGNAL CNT_AES_RST, CNT_AES_EN          : STD_LOGIC;
SIGNAL CNT_AES_OUT                      : STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL CNT_RND_RST, CNT_RND_EN          : STD_LOGIC;
SIGNAL CNT_RND_OUT                      : STD_LOGIC_VECTOR( 2 DOWNTO 0);


-- SAMPLER
SIGNAL NEW_RAND                         : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL NEW_POSITION, NEW_POSITION_DIFF  : STD_LOGIC_VECTOR(LOG2(N_BITS)-1 DOWNTO 0);
SIGNAL BIT_POSITION                     : STD_LOGIC_VECTOR( 4 DOWNTO 0);
SIGNAL NEW_BIT                          : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL VALID_RAND                       : STD_LOGIC;
SIGNAL DIN                              : STD_LOGIC_VECTOR(31 DOWNTO 0);


-- AES
SIGNAL AES_EN, AES_DONE                 : STD_LOGIC;
SIGNAL AES_IN, AES_OUT                  : STD_LOGIC_VECTOR(127 DOWNTO 0);


-- FSM
SIGNAL WREN, RDEN                       : STD_LOGIC;



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_AES_INIT, S_AES, S_SAMPLE_READ, S_SAMPLE_WRITE, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- Behavioral
----------------------------------------------------------------------------------
BEGIN

    -- PRNG ----------------------------------------------------------------------
    AES256: ENTITY work.AES256
    PORT MAP (
        CLK                 => CLK,
        RESET               => RESET,
        -- CONTROL PORTS ---------------
        DATA_AVAIL          => AES_EN,
        DATA_READY          => AES_DONE,
        -- DATA PORZS ------------------
        KEY                 => AES_KEY,
        DATA_IN             => AES_IN,
        DATA_OUT            => AES_OUT
    );
    
    -- permute counter output to match reference implementation
    AES_IN <= CNT_AES_OUT(7 DOWNTO 0) & CNT_AES_OUT(15 DOWNTO 8) & CNT_AES_OUT(23 DOWNTO 16) & CNT_AES_OUT(31 DOWNTO 24) & (95 DOWNTO 0 => '0'); 
    
    -- counter for CNTR-MODE
    CNT_AES : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => 32, MAX_VALUE => 2**31-1)
    PORT MAP(CLK => CLK, EN => CNT_AES_EN, RST => CNT_AES_RST, CNT_OUT => CNT_AES_OUT);
    
    -- AES output is divided into fout 32-bit blocks of randomness
    WITH CNT_RND_OUT SELECT NEW_RAND <=
        AES_OUT(103 DOWNTO 96) & AES_OUT(111 DOWNTO 104) & AES_OUT(119 DOWNTO 112) & AES_OUT(127 DOWNTO 120) WHEN "000",
        AES_OUT( 71 DOWNTO 64) & AES_OUT( 79 DOWNTO  72) & AES_OUT( 87 DOWNTO  80) & AES_OUT( 95 DOWNTO  88) WHEN "001",
        AES_OUT( 39 DOWNTO 32) & AES_OUT( 47 DOWNTO  40) & AES_OUT( 55 DOWNTO  48) & AES_OUT( 63 DOWNTO  56) WHEN "010",
        AES_OUT(  7 DOWNTO  0) & AES_OUT( 15 DOWNTO   8) & AES_OUT( 23 DOWNTO  16) & AES_OUT( 31 DOWNTO  24) WHEN "011",
        (OTHERS => '0')                                                                                      WHEN OTHERS;
    
    -- mask randomness and subtract R_BITS (is used for sampling e1)
    NEW_POSITION        <= NEW_RAND(LOG2(N_BITS)-1 DOWNTO 0);
    NEW_POSITION_DIFF   <= STD_LOGIC_VECTOR(UNSIGNED(NEW_POSITION) - R_BITS);
    ------------------------------------------------------------------------------

    -- SAMPLER -------------------------------------------------------------------    
    -- IO
    DOUT            <= DIN XOR NEW_BIT WHEN DIN(to_integer(unsigned(BIT_POSITION(4 DOWNTO 0)))) = '0' ELSE DIN;
    
    -- select correct input 
    DIN             <= DIN_1 WHEN NEW_POSITION_DIFF(LOG2(N_BITS)-1) = '1' ELSE DIN_2; 
    
    -- ADDRESS
    ADDR            <= NEW_POSITION(LOG2(N_BITS)-2 DOWNTO 5) WHEN NEW_POSITION_DIFF(LOG2(N_BITS)-1) = '1' ELSE NEW_POSITION_DIFF(LOG2(N_BITS)-2 DOWNTO 5);

    -- READ/WRITE CONTROL
    RDEN_1          <= NEW_POSITION_DIFF(LOG2(N_BITS)-1) AND RDEN; -- the msb of the difference selects e0/e1
    WREN_1          <= NEW_POSITION_DIFF(LOG2(N_BITS)-1) AND WREN;  
    RDEN_2          <= (NOT NEW_POSITION_DIFF(LOG2(N_BITS)-1)) AND RDEN;
    WREN_2          <= (NOT NEW_POSITION_DIFF(LOG2(N_BITS)-1)) AND WREN;
    
    -- check if randomness >= N_BITS
    VALID_RAND      <= '0' WHEN NEW_POSITION >= STD_LOGIC_VECTOR(TO_UNSIGNED(N_BITS, LOG2(N_BITS))) ELSE '1';
    
    BIT_POSITION    <= NEW_POSITION(4 DOWNTO 0) WHEN NEW_POSITION_DIFF(LOG2(N_BITS)-1) = '1' ELSE NEW_POSITION_DIFF(4 DOWNTO 0);
    
    -- ONE-HOT ENCODING
    SHIFT_LUT : PROCESS(BIT_POSITION)
    BEGIN
        CASE BIT_POSITION IS
            WHEN "00000" => NEW_BIT <= X"00000001";
            WHEN "00001" => NEW_BIT <= X"00000002";
            WHEN "00010" => NEW_BIT <= X"00000004";
            WHEN "00011" => NEW_BIT <= X"00000008";
            WHEN "00100" => NEW_BIT <= X"00000010";
            WHEN "00101" => NEW_BIT <= X"00000020";
            WHEN "00110" => NEW_BIT <= X"00000040";
            WHEN "00111" => NEW_BIT <= X"00000080";
            WHEN "01000" => NEW_BIT <= X"00000100";
            WHEN "01001" => NEW_BIT <= X"00000200";
            WHEN "01010" => NEW_BIT <= X"00000400";
            WHEN "01011" => NEW_BIT <= X"00000800";
            WHEN "01100" => NEW_BIT <= X"00001000";
            WHEN "01101" => NEW_BIT <= X"00002000";
            WHEN "01110" => NEW_BIT <= X"00004000";
            WHEN "01111" => NEW_BIT <= X"00008000";
            WHEN "10000" => NEW_BIT <= X"00010000";
            WHEN "10001" => NEW_BIT <= X"00020000";
            WHEN "10010" => NEW_BIT <= X"00040000";
            WHEN "10011" => NEW_BIT <= X"00080000";
            WHEN "10100" => NEW_BIT <= X"00100000";
            WHEN "10101" => NEW_BIT <= X"00200000";
            WHEN "10110" => NEW_BIT <= X"00400000";
            WHEN "10111" => NEW_BIT <= X"00800000";
            WHEN "11000" => NEW_BIT <= X"01000000";
            WHEN "11001" => NEW_BIT <= X"02000000";
            WHEN "11010" => NEW_BIT <= X"04000000";
            WHEN "11011" => NEW_BIT <= X"08000000";
            WHEN "11100" => NEW_BIT <= X"10000000";
            WHEN "11101" => NEW_BIT <= X"20000000";
            WHEN "11110" => NEW_BIT <= X"40000000";
            WHEN "11111" => NEW_BIT <= X"80000000";
            WHEN OTHERS  => NEW_BIT <= X"00000000";
        END CASE;
    END PROCESS;
    ------------------------------------------------------------------------------
     
     
    -- COUNTER -------------------------------------------------------------------
    CNT_ENABLE <= '1' WHEN ((DIN(to_integer(unsigned(BIT_POSITION(4 DOWNTO 0)))) = '0') AND (CNT_VALID = '1') AND (VALID_RAND = '1')) ELSE '0';
    
    COUNTER : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(THRESHOLD+1), MAX_VALUE => THRESHOLD)
    PORT MAP(CLK => CLK, EN => CNT_ENABLE, RST => CNT_RESET, CNT_OUT => CNT_OUT);
    
    CNT_RND : ENTITY work.BIKE_COUNTER_INC GENERIC MAP(SIZE => 3, MAX_VALUE => 4)
    PORT MAP(CLK => CLK, EN => CNT_RND_EN, RST => CNT_RND_RST, CNT_OUT => CNT_RND_OUT);
    ------------------------------------------------------------------------------
    


    -- FINITE STATE MACHINE PROCESS ----------------------------------------------
    FSM : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            CASE STATE IS
                
                ----------------------------------------------
                WHEN S_RESET        =>
                    -- GLOBAL ----------
                    DONE            <= '0';
                    
                    -- COUNTER ---------
                    CNT_RESET       <= '1';
                    CNT_VALID       <= '0';
                    
                    CNT_RND_RST     <= '1';
                    CNT_RND_EN      <= '0';
                    
                    CNT_AES_RST     <= '1';
                    CNT_AES_EN      <= '0';
                    
                    -- BRAM ------------
                    RDEN            <= '0';
                    WREN            <= '0';    
                    
                    -- AES -------------
                    AES_EN          <= '0'; 
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN
                        STATE       <= S_AES_INIT;
                    ELSE
                        STATE       <= S_RESET;
                    END IF;
                ----------------------------------------------

                ----------------------------------------------
                WHEN S_AES_INIT        =>
                    -- GLOBAL ----------
                    DONE            <= '0';
                    
                    -- COUNTER ---------
                    CNT_RESET       <= '0';
                    CNT_VALID       <= '0';

                    CNT_RND_RST     <= '1';
                    CNT_RND_EN      <= '0';
                    
                    CNT_AES_RST     <= '0';
                    CNT_AES_EN      <= '0';
                                        
                    -- BRAM ------------
                    RDEN            <= '0';
                    WREN            <= '0';    

                    -- AES -------------
                    AES_EN          <= '1';
                                        
                    -- TRANSITION ------
                    STATE           <= S_AES;
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_AES        =>
                    -- GLOBAL ----------
                    DONE            <= '0';
                    
                    -- COUNTER ---------
                    CNT_RESET       <= '0';
                    CNT_VALID       <= '0';

                    CNT_RND_RST     <= '1';
                    CNT_RND_EN      <= '0';
                    
                    CNT_AES_RST     <= '0';
                    CNT_AES_EN      <= '0';  

                    -- AES -------------
                    AES_EN          <= '0';
                                        
                    -- TRANSITION ------
                    IF (AES_DONE = '1') THEN
                        RDEN        <= '1';
                        WREN        <= '0'; 
                    
                        STATE       <= S_SAMPLE_READ;
                    ELSE
                        RDEN        <= '0';
                        WREN        <= '0'; 
                                        
                        STATE       <= S_AES;
                    END IF;
                ----------------------------------------------
                 
                ----------------------------------------------
                WHEN S_SAMPLE_READ  =>
                    IF (CNT_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(THRESHOLD, LOG2(THRESHOLD+1)))) THEN
                        -- TRANSITION --
                        STATE       <= S_DONE;
                
                        -- GLOBAL ------
                        DONE        <= '1';
                
                        -- COUNTER -----
                        CNT_VALID   <= '0';
                        CNT_RESET   <= '1';

                        CNT_RND_RST <= '0';
                        CNT_RND_EN  <= '0';
                        
                        CNT_AES_RST <= '0';
                        CNT_AES_EN  <= '0';
                                    
                        -- BRAM --------
                        RDEN        <= '0';
                        WREN        <= '0';   
                        
                        -- AES -------------
                        AES_EN      <= '0';                    
                    ELSE
                        -- TRANSITION --
                        STATE       <= S_SAMPLE_WRITE;
                        
                        -- GLOBAL ------
                        DONE        <= '0';
                        
                        -- COUNTER -----
                        CNT_VALID   <= '1';
                        CNT_RESET   <= '0';  
                        
                        CNT_RND_RST <= '0';
                        CNT_RND_EN  <= '1';
                        
                        CNT_AES_RST <= '0';
                        CNT_AES_EN  <= '0'; 
                                               
                        -- BRAM --------
                        RDEN        <= '1';
                        WREN        <= '1' AND VALID_RAND;        
                        
                        -- AES -------------
                        AES_EN      <= '0';                                      
                    END IF;
                ----------------------------------------------
                               
                ----------------------------------------------
                WHEN S_SAMPLE_WRITE =>
                    -- TRANSITION --
                    IF (CNT_RND_OUT = STD_LOGIC_VECTOR(TO_UNSIGNED(3 ,3))) THEN
                        CNT_AES_EN  <= '1';
                        STATE       <= S_AES_INIT;
                    ELSE
                        CNT_AES_EN  <= '0';
                        STATE       <= S_SAMPLE_READ;
                    END IF;
                    
                    -- GLOBAL ------
                    DONE            <= '0';
                    
                    -- COUNTER -----
                    CNT_VALID       <= '0';
                    CNT_RESET       <= '0';   
                    
                    CNT_RND_RST     <= '0';
                    CNT_RND_EN      <= '0';
                    
                    CNT_AES_RST     <= '0';
                    --CNT_AES_EN      <= '0';
                    
                    -- BRAM --------
                    RDEN            <= '1';
                    WREN            <= '0';   
                    
                    -- AES -------------
                    AES_EN          <= '0';                                           
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- GLOBAL ----------
                    DONE            <= '1';
                    
                    -- COUNTER ---------
                    CNT_RESET       <= '1';
                    CNT_VALID       <= '0';
                    
                    CNT_RND_RST     <= '1';
                    CNT_RND_EN      <= '0';
                    
                    CNT_AES_RST     <= '1';
                    CNT_AES_EN      <= '0';

                    -- BRAM --------
                    RDEN            <= '0';
                    WREN            <= '0';  
                                        
                    -- AES -------------
                    AES_EN          <= '0';
                    
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

END Behavioral;
