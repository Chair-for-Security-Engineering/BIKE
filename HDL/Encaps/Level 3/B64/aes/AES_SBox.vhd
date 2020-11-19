----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    06/05/2020
-- LAST CHANGES:            06/05/2020
-- MODULE NAME:			    AES_SBox
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
ENTITY AES_SBox IS
	PORT ( 
        S_IN    : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
        S_OUT	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END AES_SBox;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF AES_SBox IS



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

	-- PROCESS -------------------------------------------------------------------
	SBox : PROCESS(S_IN)
	BEGIN
		CASE S_IN IS
			WHEN X"00"	=> S_OUT <= X"63";
			WHEN X"01"  => S_OUT <= X"7C";
			WHEN X"02"  => S_OUT <= X"77";
			WHEN X"03"  => S_OUT <= X"7B";
			WHEN X"04"  => S_OUT <= X"F2";
			WHEN X"05"  => S_OUT <= X"6B";
			WHEN X"06"  => S_OUT <= X"6F";
			WHEN X"07"  => S_OUT <= X"C5";
			WHEN X"08"  => S_OUT <= X"30";
			WHEN X"09"  => S_OUT <= X"01";
			WHEN X"0A"  => S_OUT <= X"67";
			WHEN X"0B"  => S_OUT <= X"2B";
			WHEN X"0C"  => S_OUT <= X"FE";
			WHEN X"0D"  => S_OUT <= X"D7";
			WHEN X"0E"  => S_OUT <= X"AB";
			WHEN X"0F"  => S_OUT <= X"76";
			WHEN X"10"  => S_OUT <= X"CA";
			WHEN X"11"  => S_OUT <= X"82";
			WHEN X"12"  => S_OUT <= X"C9";
			WHEN X"13"  => S_OUT <= X"7D";
			WHEN X"14"  => S_OUT <= X"FA";
			WHEN X"15"  => S_OUT <= X"59";
			WHEN X"16"  => S_OUT <= X"47";
			WHEN X"17"  => S_OUT <= X"F0";
			WHEN X"18"  => S_OUT <= X"AD";
			WHEN X"19"  => S_OUT <= X"D4";
			WHEN X"1A"  => S_OUT <= X"A2";
			WHEN X"1B"  => S_OUT <= X"AF";
			WHEN X"1C"  => S_OUT <= X"9C";
			WHEN X"1D"  => S_OUT <= X"A4";
			WHEN X"1E"  => S_OUT <= X"72";
			WHEN X"1F"  => S_OUT <= X"C0";
			WHEN X"20"  => S_OUT <= X"B7";
			WHEN X"21"  => S_OUT <= X"FD";
			WHEN X"22"  => S_OUT <= X"93";
			WHEN X"23"  => S_OUT <= X"26";
			WHEN X"24"  => S_OUT <= X"36";
			WHEN X"25"  => S_OUT <= X"3F";
			WHEN X"26"  => S_OUT <= X"F7";
			WHEN X"27"  => S_OUT <= X"CC";
			WHEN X"28"  => S_OUT <= X"34";
			WHEN X"29"  => S_OUT <= X"A5";
			WHEN X"2A"  => S_OUT <= X"E5";
			WHEN X"2B"  => S_OUT <= X"F1";
			WHEN X"2C"  => S_OUT <= X"71";
			WHEN X"2D"  => S_OUT <= X"D8";
			WHEN X"2E"  => S_OUT <= X"31";
			WHEN X"2F"  => S_OUT <= X"15";
			WHEN X"30"  => S_OUT <= X"04";
			WHEN X"31"  => S_OUT <= X"C7";
			WHEN X"32"  => S_OUT <= X"23";
			WHEN X"33"  => S_OUT <= X"C3";
			WHEN X"34"  => S_OUT <= X"18";
			WHEN X"35"  => S_OUT <= X"96";
			WHEN X"36"  => S_OUT <= X"05";
			WHEN X"37"  => S_OUT <= X"9A";
			WHEN X"38"  => S_OUT <= X"07";
			WHEN X"39"  => S_OUT <= X"12";
			WHEN X"3A"  => S_OUT <= X"80";
			WHEN X"3B"  => S_OUT <= X"E2";
			WHEN X"3C"  => S_OUT <= X"EB";
			WHEN X"3D"  => S_OUT <= X"27";
			WHEN X"3E"  => S_OUT <= X"B2";
			WHEN X"3F"  => S_OUT <= X"75";
			WHEN X"40"  => S_OUT <= X"09";
			WHEN X"41"  => S_OUT <= X"83";
			WHEN X"42"  => S_OUT <= X"2C";
			WHEN X"43"  => S_OUT <= X"1A";
			WHEN X"44"  => S_OUT <= X"1B";
			WHEN X"45"  => S_OUT <= X"6E";
			WHEN X"46"  => S_OUT <= X"5A";
			WHEN X"47"  => S_OUT <= X"A0";
			WHEN X"48"  => S_OUT <= X"52";
			WHEN X"49"  => S_OUT <= X"3B";
			WHEN X"4A"  => S_OUT <= X"D6";
			WHEN X"4B"  => S_OUT <= X"B3";
			WHEN X"4C"  => S_OUT <= X"29";
			WHEN X"4D"  => S_OUT <= X"E3";
			WHEN X"4E"  => S_OUT <= X"2F";
			WHEN X"4F"  => S_OUT <= X"84";
			WHEN X"50"  => S_OUT <= X"53";
			WHEN X"51"  => S_OUT <= X"D1";
			WHEN X"52"  => S_OUT <= X"00";
			WHEN X"53"  => S_OUT <= X"ED";
			WHEN X"54"  => S_OUT <= X"20";
			WHEN X"55"  => S_OUT <= X"FC";
			WHEN X"56"  => S_OUT <= X"B1";
			WHEN X"57"  => S_OUT <= X"5B";
			WHEN X"58"  => S_OUT <= X"6A";
			WHEN X"59"  => S_OUT <= X"CB";
			WHEN X"5A"  => S_OUT <= X"BE";
			WHEN X"5B"  => S_OUT <= X"39";
			WHEN X"5C"  => S_OUT <= X"4A";
			WHEN X"5D"  => S_OUT <= X"4C";
			WHEN X"5E"  => S_OUT <= X"58";
			WHEN X"5F"  => S_OUT <= X"CF";
			WHEN X"60"  => S_OUT <= X"D0";
			WHEN X"61"  => S_OUT <= X"EF";
			WHEN X"62"  => S_OUT <= X"AA";
			WHEN X"63"  => S_OUT <= X"FB";
			WHEN X"64"  => S_OUT <= X"43";
			WHEN X"65"  => S_OUT <= X"4D";
			WHEN X"66"  => S_OUT <= X"33";
			WHEN X"67"  => S_OUT <= X"85";
			WHEN X"68"  => S_OUT <= X"45";
			WHEN X"69"  => S_OUT <= X"F9";
			WHEN X"6A"  => S_OUT <= X"02";
			WHEN X"6B"  => S_OUT <= X"7F";
			WHEN X"6C"  => S_OUT <= X"50";
			WHEN X"6D"  => S_OUT <= X"3C";
			WHEN X"6E"  => S_OUT <= X"9F";
			WHEN X"6F"  => S_OUT <= X"A8";
			WHEN X"70"  => S_OUT <= X"51";
			WHEN X"71"  => S_OUT <= X"A3";
			WHEN X"72"  => S_OUT <= X"40";
			WHEN X"73"  => S_OUT <= X"8F";
			WHEN X"74"  => S_OUT <= X"92";
			WHEN X"75"  => S_OUT <= X"9D";
			WHEN X"76"  => S_OUT <= X"38";
			WHEN X"77"  => S_OUT <= X"F5";
			WHEN X"78"  => S_OUT <= X"BC";
			WHEN X"79"  => S_OUT <= X"B6";
			WHEN X"7A"  => S_OUT <= X"DA";
			WHEN X"7B"  => S_OUT <= X"21";
			WHEN X"7C"  => S_OUT <= X"10";
			WHEN X"7D"  => S_OUT <= X"FF";
			WHEN X"7E"  => S_OUT <= X"F3";
			WHEN X"7F"  => S_OUT <= X"D2";
			WHEN X"80"  => S_OUT <= X"CD";
			WHEN X"81"  => S_OUT <= X"0C";
			WHEN X"82"  => S_OUT <= X"13";
			WHEN X"83"  => S_OUT <= X"EC";
			WHEN X"84"  => S_OUT <= X"5F";
			WHEN X"85"  => S_OUT <= X"97";
			WHEN X"86"  => S_OUT <= X"44";
			WHEN X"87"  => S_OUT <= X"17";
			WHEN X"88"  => S_OUT <= X"C4";
			WHEN X"89"  => S_OUT <= X"A7";
			WHEN X"8A"  => S_OUT <= X"7E";
			WHEN X"8B"  => S_OUT <= X"3D";
			WHEN X"8C"  => S_OUT <= X"64";
			WHEN X"8D"  => S_OUT <= X"5D";
			WHEN X"8E"  => S_OUT <= X"19";
			WHEN X"8F"  => S_OUT <= X"73";
			WHEN X"90"  => S_OUT <= X"60";
			WHEN X"91"  => S_OUT <= X"81";
			WHEN X"92"  => S_OUT <= X"4F";
			WHEN X"93"  => S_OUT <= X"DC";
			WHEN X"94"  => S_OUT <= X"22";
			WHEN X"95"  => S_OUT <= X"2A";
			WHEN X"96"  => S_OUT <= X"90";
			WHEN X"97"  => S_OUT <= X"88";
			WHEN X"98"  => S_OUT <= X"46";
			WHEN X"99"  => S_OUT <= X"EE";
			WHEN X"9A"  => S_OUT <= X"B8";
			WHEN X"9B"  => S_OUT <= X"14";
			WHEN X"9C"  => S_OUT <= X"DE";
			WHEN X"9D"  => S_OUT <= X"5E";
			WHEN X"9E"  => S_OUT <= X"0B";
			WHEN X"9F"  => S_OUT <= X"DB";
			WHEN X"A0"  => S_OUT <= X"E0";
			WHEN X"A1"  => S_OUT <= X"32";
			WHEN X"A2"  => S_OUT <= X"3A";
			WHEN X"A3"  => S_OUT <= X"0A";
			WHEN X"A4"  => S_OUT <= X"49";
			WHEN X"A5"  => S_OUT <= X"06";
			WHEN X"A6"  => S_OUT <= X"24";
			WHEN X"A7"  => S_OUT <= X"5C";
			WHEN X"A8"  => S_OUT <= X"C2";
			WHEN X"A9"  => S_OUT <= X"D3";
			WHEN X"AA"  => S_OUT <= X"AC";
			WHEN X"AB"  => S_OUT <= X"62";
			WHEN X"AC"  => S_OUT <= X"91";
			WHEN X"AD"  => S_OUT <= X"95";
			WHEN X"AE"  => S_OUT <= X"E4";
			WHEN X"AF"  => S_OUT <= X"79";
			WHEN X"B0"  => S_OUT <= X"E7";
			WHEN X"B1"  => S_OUT <= X"C8";
			WHEN X"B2"  => S_OUT <= X"37";
			WHEN X"B3"  => S_OUT <= X"6D";
			WHEN X"B4"  => S_OUT <= X"8D";
			WHEN X"B5"  => S_OUT <= X"D5";
			WHEN X"B6"  => S_OUT <= X"4E";
			WHEN X"B7"  => S_OUT <= X"A9";
			WHEN X"B8"  => S_OUT <= X"6C";
			WHEN X"B9"  => S_OUT <= X"56";
			WHEN X"BA"  => S_OUT <= X"F4";
			WHEN X"BB"  => S_OUT <= X"EA";
			WHEN X"BC"  => S_OUT <= X"65";
			WHEN X"BD"  => S_OUT <= X"7A";
			WHEN X"BE"  => S_OUT <= X"AE";
			WHEN X"BF"  => S_OUT <= X"08";
			WHEN X"C0"  => S_OUT <= X"BA";
			WHEN X"C1"  => S_OUT <= X"78";
			WHEN X"C2"  => S_OUT <= X"25";
			WHEN X"C3"  => S_OUT <= X"2E";
			WHEN X"C4"  => S_OUT <= X"1C";
			WHEN X"C5"  => S_OUT <= X"A6";
			WHEN X"C6"  => S_OUT <= X"B4";
			WHEN X"C7"  => S_OUT <= X"C6";
			WHEN X"C8"  => S_OUT <= X"E8";
			WHEN X"C9"  => S_OUT <= X"DD";
			WHEN X"CA"  => S_OUT <= X"74";
			WHEN X"CB"  => S_OUT <= X"1F";
			WHEN X"CC"  => S_OUT <= X"4B";
			WHEN X"CD"  => S_OUT <= X"BD";
			WHEN X"CE"  => S_OUT <= X"8B";
			WHEN X"CF"  => S_OUT <= X"8A";
			WHEN X"D0"  => S_OUT <= X"70";
			WHEN X"D1"  => S_OUT <= X"3E";
			WHEN X"D2"  => S_OUT <= X"B5";
			WHEN X"D3"  => S_OUT <= X"66";
			WHEN X"D4"  => S_OUT <= X"48";
			WHEN X"D5"  => S_OUT <= X"03";
			WHEN X"D6"  => S_OUT <= X"F6";
			WHEN X"D7"  => S_OUT <= X"0E";
			WHEN X"D8"  => S_OUT <= X"61";
			WHEN X"D9"  => S_OUT <= X"35";
			WHEN X"DA"  => S_OUT <= X"57";
			WHEN X"DB"  => S_OUT <= X"B9";
			WHEN X"DC"  => S_OUT <= X"86";
			WHEN X"DD"  => S_OUT <= X"C1";
			WHEN X"DE"  => S_OUT <= X"1D";
			WHEN X"DF"  => S_OUT <= X"9E";
			WHEN X"E0"  => S_OUT <= X"E1";
			WHEN X"E1"  => S_OUT <= X"F8";
			WHEN X"E2"  => S_OUT <= X"98";
			WHEN X"E3"  => S_OUT <= X"11";
			WHEN X"E4"  => S_OUT <= X"69";
			WHEN X"E5"  => S_OUT <= X"D9";
			WHEN X"E6"  => S_OUT <= X"8E";
			WHEN X"E7"  => S_OUT <= X"94";
			WHEN X"E8"  => S_OUT <= X"9B";
			WHEN X"E9"  => S_OUT <= X"1E";
			WHEN X"EA"  => S_OUT <= X"87";
			WHEN X"EB"  => S_OUT <= X"E9";
			WHEN X"EC"  => S_OUT <= X"CE";
			WHEN X"ED"  => S_OUT <= X"55";
			WHEN X"EE"  => S_OUT <= X"28";
			WHEN X"EF"  => S_OUT <= X"DF";
			WHEN X"F0"  => S_OUT <= X"8C";
			WHEN X"F1"  => S_OUT <= X"A1";
			WHEN X"F2"  => S_OUT <= X"89";
			WHEN X"F3"  => S_OUT <= X"0D";
			WHEN X"F4"  => S_OUT <= X"BF";
			WHEN X"F5"  => S_OUT <= X"E6";
			WHEN X"F6"  => S_OUT <= X"42";
			WHEN X"F7"  => S_OUT <= X"68";
			WHEN X"F8"  => S_OUT <= X"41";
			WHEN X"F9"  => S_OUT <= X"99";
			WHEN X"FA"  => S_OUT <= X"2D";
			WHEN X"FB"  => S_OUT <= X"0F";
			WHEN X"FC"  => S_OUT <= X"B0";
			WHEN X"FD"  => S_OUT <= X"54";
			WHEN X"FE"  => S_OUT <= X"BB";
			WHEN X"FF"  => S_OUT <= X"16";
			WHEN OTHERS => S_OUT <= "XXXXXXXX";
		END CASE;
	 
	END PROCESS;
	------------------------------------------------------------------------------
	
END Behavioral;

