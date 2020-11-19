----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_MixSingleColumn
--
-- REVISION:				1.00 - File created
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or	if you have questions regarding the code
--							please contact Tim Gueneysu (tim.gueneysu@rub.de) and
--							Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
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



-- ENTITY
----------------------------------------------------------------------------------
ENTITY AES_MixSingleColumn IS
	PORT ( 
        COLUMN : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        RESULT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END AES_MixSingleColumn;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF AES_MixSingleColumn IS



-- CONSTANTS
----------------------------------------------------------------------------------
CONSTANT IRREDUCIBLE_POLYNOMIAL	: STD_LOGIC_VECTOR (7 DOWNTO 0) := X"1B";



-- ALIAS
----------------------------------------------------------------------------------
ALIAS S0 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS COLUMN(31 DOWNTO 24);
ALIAS S1 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS COLUMN(23 DOWNTO 16);
ALIAS S2 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS COLUMN(15 DOWNTO  8);
ALIAS S3 : STD_LOGIC_VECTOR (7 DOWNTO 0) IS COLUMN( 7 DOWNTO  0);



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL S0LS, S1LS, S2LS, S3LS : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL S0X2, S1X2, S2X2, S3X2 : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL S0X3, S1X3, S2X3, S3X3 : STD_LOGIC_VECTOR (7 DOWNTO 0);



-- DATAFLOW
----------------------------------------------------------------------------------
BEGIN
	
	-- LEFT SHIFT OF BYTES -------------------------------------------------------
	S0LS <= S0(6 DOWNTO 0) & "0";
	S1LS <= S1(6 DOWNTO 0) & "0";
	S2LS <= S2(6 DOWNTO 0) & "0";
	S3LS <= S3(6 DOWNTO 0) & "0";

	-- MULTIPLICATION BY 0x02 ----------------------------------------------------
	S0X2 <= S0LS XOR IRREDUCIBLE_POLYNOMIAL WHEN (S0(7) = '1') ELSE S0LS;
	S1X2 <= S1LS XOR IRREDUCIBLE_POLYNOMIAL WHEN (S1(7) = '1') ELSE S1LS;
	S2X2 <= S2LS XOR IRREDUCIBLE_POLYNOMIAL WHEN (S2(7) = '1') ELSE S2LS;
	S3X2 <= S3LS XOR IRREDUCIBLE_POLYNOMIAL WHEN (S3(7) = '1') ELSE S3LS;
	
	-- MULTIPLICATION BY 0x03 ----------------------------------------------------
	S0X3 <= S0X2 XOR S0;
	S1X3 <= S1X2 XOR S1;
	S2X3 <= S2X2 XOR S2;
	S3X3 <= S3X2 XOR S3;
	
	-- MIX COLUMNS ---------------------------------------------------------------
	RESULT(31 DOWNTO 24) <= S0X2 	XOR S1X3 XOR S2 	XOR S3;
	RESULT(23 DOWNTO 16) <= S0		XOR S1X2 XOR S2X3   XOR S3;
	RESULT(15 DOWNTO  8) <= S0		XOR S1 	 XOR S2X2   XOR S3X3;
	RESULT( 7 DOWNTO  0) <= S0X3 	XOR S1 	 XOR S2 	XOR S3X2;
	
END Dataflow;

