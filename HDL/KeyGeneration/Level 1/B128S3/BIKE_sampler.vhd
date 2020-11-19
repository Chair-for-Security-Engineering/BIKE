----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2019 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    27/02/2019
-- LAST CHANGES:            01/03/2019
-- MODULE NAME:			    BIKE_SAMPLER
--
-- REVISION:				1.10 - Adapted FSM.
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
ENTITY BIKE_SAMPLER IS
    GENERIC (
        THRESHOLD       : INTEGER := 10;
        SIZE            : INTEGER := 14
    );
	PORT (  
        CLK             : IN  STD_LOGIC;
        -- CONTROL PORTS ---------------	
        RESET           : IN  STD_LOGIC;
        ENABLE          : IN  STD_LOGIC;
        DONE            : OUT STD_LOGIC;
        -- RAND ------------------------
        NEW_POSITION    : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
        -- MEMORY I/O ------------------
        RDEN            : OUT STD_LOGIC;
        WREN            : OUT STD_LOGIC;
        ADDR            : OUT STD_LOGIC_VECTOR(LOG2(CEIL(R_BITS,32))-1 DOWNTO 0);
        DOUT            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN             : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END BIKE_SAMPLER;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_SAMPLER IS



-- SIGNALS
----------------------------------------------------------------------------------
-- COUNTER
SIGNAL CNT_RESET, CNT_ENABLE, CNT_VALID : STD_LOGIC;
SIGNAL CNT_OUT                          : STD_LOGIC_VECTOR(LOG2(THRESHOLD+1)-1 DOWNTO 0);

SIGNAL BIT_POSITION, BIT_POSITION_D     : STD_LOGIC_VECTOR( 4 DOWNTO 0);
SIGNAL NEW_BIT                          : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL VALID_RAND                       : STD_LOGIC;



-- STATES
----------------------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_SAMPLE_READ, S_SAMPLE_WRITE, S_DONE);
SIGNAL STATE : STATES := S_RESET;



-- Behavioral
----------------------------------------------------------------------------------
BEGIN

    -- SAMPLER -------------------------------------------------------------------    
    BIT_POSITION    <= NEW_POSITION(4 DOWNTO 0);
    
    DOUT            <= DIN XOR NEW_BIT WHEN DIN(to_integer(unsigned(BIT_POSITION_D(4 DOWNTO 0)))) = '0' ELSE DIN;
    
    ADDR            <= (LOG2(CEIL(R_BITS,32))-1 DOWNTO SIZE-5 => '0') & NEW_POSITION(SIZE-1 DOWNTO 5); -- first bit sets the lower or higher part of the BRAM to distinguish e0 and e1
    
    VALID_RAND      <= '0' WHEN NEW_POSITION(SIZE-1 DOWNTO 0) >= STD_LOGIC_VECTOR(TO_UNSIGNED(R_BITS, LOG2(R_BITS+1))) ELSE '1';
    
    -- REGISTER   
    REG_POS : ENTITY work.RegisterFDRE GENERIC MAP(SIZE => 5)
    PORT MAP(D => BIT_POSITION, Q => BIT_POSITION_D, CLK => CLK, EN => ENABLE, RST => RESET);
    
    -- UGLY LUT SOLUTION 
    SHIFT_LUT : PROCESS(BIT_POSITION_D)
    BEGIN
        CASE BIT_POSITION_D IS
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
    CNT_ENABLE <= '1' WHEN ((DIN(to_integer(unsigned(BIT_POSITION_D(4 DOWNTO 0)))) = '0') AND (CNT_VALID = '1') AND (VALID_RAND = '1')) ELSE '0';
    
    COUNTER : ENTITY work.BIKE_COUNTER_INC_STOP GENERIC MAP(SIZE => LOG2(THRESHOLD+1), MAX_VALUE => THRESHOLD)
    PORT MAP(CLK => CLK, EN => CNT_ENABLE, RST => CNT_RESET, CNT_OUT => CNT_OUT);
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
                    
                    -- TRANSITION ------
                    IF (ENABLE = '1') THEN
                        RDEN        <= '1';
                        WREN        <= '0';
                        
                        STATE       <= S_SAMPLE_READ;
                    ELSE
                        RDEN        <= '0';
                        WREN        <= '0';
                    
                        STATE       <= S_RESET;
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
                
                        -- BRAM --------
                        RDEN        <= '0';
                        WREN        <= '0';                       
                    ELSE
                        -- TRANSITION --
                        STATE       <= S_SAMPLE_WRITE;
                        
                        -- GLOBAL ------
                        DONE        <= '0';
                        
                        -- COUNTER -----
                        CNT_VALID   <= '1';
                        CNT_RESET   <= '0';  
                        
                        -- BRAM --------
                        RDEN        <= '1';
                        WREN        <= '1' AND VALID_RAND;                                              
                    END IF;
                ----------------------------------------------
                               
                ----------------------------------------------
                WHEN S_SAMPLE_WRITE =>
                    -- TRANSITION --
                    STATE           <= S_SAMPLE_READ;
                    
                    -- GLOBAL ------
                    DONE            <= '0';
                    
                    -- COUNTER -----
                    CNT_VALID       <= '0';
                    CNT_RESET       <= '0';   
                    
                    -- BRAM --------
                    RDEN            <= '1';
                    WREN            <= '0';                                              
                ----------------------------------------------
                
                ----------------------------------------------
                WHEN S_DONE         =>
                    -- GLOBAL ----------
                    DONE            <= '1';
                    
                    -- COUNTER ---------
                    CNT_RESET       <= '1';
                    CNT_VALID       <= '0';
                    
                    -- TRANSITION ------
                    IF RESET = '1' THEN
                        STATE           <= S_RESET;
                    ELSE 
                        STATE           <= S_DONE;
                    END IF;
                ----------------------------------------------
                                
            END CASE;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------

END Behavioral;
