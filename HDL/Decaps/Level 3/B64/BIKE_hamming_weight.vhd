----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    08/05/2020
-- LAST CHANGES:            08/05/2020
-- MODULE NAME:			    BIKE_HAMMING_WEIGHT
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
ENTITY BIKE_HAMMING_WEIGHT IS
	PORT ( 
        CLK         : IN  STD_LOGIC; 
        EN          : IN  STD_LOGIC; 
        RST         : IN  STD_LOGIC; 
        -- DATA PORTS ------------------
        DIN         : IN  STD_LOGIC_VECTOR(B_WIDTH-1 DOWNTO 0);
        DOUT        : OUT STD_LOGIC_VECTOR(LOG2(R_BITS+1)-1 DOWNTO 0)
    );
END BIKE_HAMMING_WEIGHT;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE_HAMMING_WEIGHT IS 



-- TYPES
----------------------------------------------------------------------------------
TYPE OUT_ARRAY IS ARRAY (INTEGER RANGE<>) OF STD_LOGIC_VECTOR(48*CEIL(B_WIDTH,48)-1 DOWNTO 0); 



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL DIN_A, DIN_B                 : OUT_ARRAY(LOG2(B_WIDTH)-1 DOWNTO 0);
SIGNAL ADD_OUT                      : OUT_ARRAY(LOG2(B_WIDTH) DOWNTO 0);
SIGNAL DIN_A_FINAL, DIN_B_FINAL     : STD_LOGIC_VECTOR(47 DOWNTO 0);
SIGNAL DOUT_FINAL                   : STD_LOGIC_VECTOR(47 DOWNTO 0);




-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
    
    -- HAMMING WEIGHT ------------------------------------------------------------
    -- init vector with input data   
    ADD_OUT(0) <= (48*CEIL(B_WIDTH,48)-1 DOWNTO B_WIDTH => '0') & DIN;
    
    TREE : FOR T IN 0 TO LOG2(B_WIDTH)-1 GENERATE
        -- split data
        L0 : FOR I IN 0 TO B_WIDTH/(2**(T+1))-1 GENERATE
            DIN_A(T)(I*(T+2)+T DOWNTO I*(T+2))  <= ADD_OUT(T)((T+1)*(I+1)-1 DOWNTO I*(T+1));
            DIN_A(T)(I*(T+2)+T+1)               <= '0';
            DIN_B(T)(I*(T+2)+T DOWNTO I*(T+2))  <= ADD_OUT(T)((T+1)*(I+1)-1+(B_WIDTH/(2**T)*(T+1)/2) DOWNTO I*(T+1)+(B_WIDTH/(2**T)*(T+1)/2));
            DIN_B(T)(I*(T+2)+T+1)               <= '0';
        END GENERATE;
        
        -- padding with zeros
        DIN_A(T)(48*CEIL(B_WIDTH,48)-1 DOWNTO (T+2)*(B_WIDTH/2**(T+1))) <= (OTHERS => '0');
        DIN_B(T)(48*CEIL(B_WIDTH,48)-1 DOWNTO (T+2)*(B_WIDTH/2**(T+1))) <= (OTHERS => '0');
        
        -- DSPs
        DSP0 : FOR I IN 0 TO CEIL(B_WIDTH/2**(T+1)*(T+2),48)-1 GENERATE
            ADD : ENTITY work.BIKE_ADD
            PORT MAP(CLK => CLK, EN => EN, RST => RST, DIN_A => DIN_A(T)(48*(I+1)-1 DOWNTO 48*I), DIN_B => DIN_B(T)(48*(I+1)-1 DOWNTO 48*I), DOUT => ADD_OUT(T+1)(48*(I+1)-1 DOWNTO 48*I));
        END GENERATE;
    END GENERATE;

    -- final adder
    DIN_A_FINAL <= (47 DOWNTO LOG2(B_WIDTH+1) => '0') & ADD_OUT(LOG2(B_WIDTH))(LOG2(B_WIDTH+1)-1 DOWNTO 0);
    DIN_B_FINAL <= DOUT_FINAL;
    
    ADD_FINAL : ENTITY work.BIKE_ADD
    PORT MAP(CLK => CLK, EN => EN, RST => RST, DIN_A => DIN_A_FINAL, DIN_B => DIN_B_FINAL, DOUT => DOUT_FINAL);
    
    DOUT <= DOUT_FINAL(LOG2(R_BITS+1)-1 DOWNTO 0);
    ------------------------------------------------------------------------------
    
END Structural;










