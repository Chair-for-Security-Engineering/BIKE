----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2020 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    08/05/2020
-- LAST CHANGES:            08/05/2020
-- MODULE NAME:			    BIKE_MUL_ADD
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
ENTITY BIKE_MUL_ADD IS
	PORT ( 
        CLK         : IN  STD_LOGIC; 
        EN          : IN  STD_LOGIC; 
        -- DATA PORTS ------------------
        DIN_A       : IN  STD_LOGIC_VECTOR(24 DOWNTO 0);
        DIN_B       : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);
        DIN_C       : IN  STD_LOGIC_VECTOR(47 DOWNTO 0);
        DOUT        : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
    );
END BIKE_MUL_ADD;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF BIKE_MUL_ADD IS 



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL A    : STD_LOGIC_VECTOR(29 DOWNTO 0);



-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
    
    -- DSP -----------------------------------------------------------------------
    A <= "00000" & DIN_A;
    
    -- DSP48E1: 48-bit Multi-Functional Arithmetic Block -------------------------
    -- 7 Series
    -- Xilinx HDL Libraries Guide, version 2012.2
    DSP48E1_INST : DSP48E1
    GENERIC MAP (
        -- Feature Control Attributes: Data Path Selection
        A_INPUT             => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
        B_INPUT             => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
        USE_DPORT           => FALSE, -- Select D port usage (TRUE or FALSE)
        USE_MULT            => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
        -- Pattern Detector Attributes: Pattern Detection Configuration
        AUTORESET_PATDET    => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
        MASK                => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
        PATTERN             => X"000000000000", -- 48-bit pattern match for pattern detect
        SEL_MASK            => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
        SEL_PATTERN         => "PATTERN", -- Select pattern value ("PATTERN" or "C")
        USE_PATTERN_DETECT  => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
        -- Register Control Attributes: Pipeline Register Configuration
        ACASCREG            => 0, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
        ADREG               => 0, -- Number of pipeline stages for pre-adder (0 or 1)
        ALUMODEREG          => 0, -- Number of pipeline stages for ALUMODE (0 or 1)
        AREG                => 0, -- Number of pipeline stages for A (0, 1 or 2)
        BCASCREG            => 0, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
        BREG                => 0, -- Number of pipeline stages for B (0, 1 or 2)
        CARRYINREG          => 0, -- Number of pipeline stages for CARRYIN (0 or 1)
        CARRYINSELREG       => 0, -- Number of pipeline stages for CARRYINSEL (0 or 1)
        CREG                => 0, -- Number of pipeline stages for C (0 or 1)
        DREG                => 0, -- Number of pipeline stages for D (0 or 1)
        INMODEREG           => 0, -- Number of pipeline stages for INMODE (0 or 1)
        MREG                => 0, -- Number of multiplier pipeline stages (0 or 1)
        OPMODEREG           => 0, -- Number of pipeline stages for OPMODE (0 or 1)
        PREG                => 1, -- Number of pipeline stages for P (0 or 1)
        USE_SIMD            => "ONE48" -- SIMD selection ("ONE48", "TWO24", "FOUR12")
    )
    port map (
        -- Cascade: 30-bit (each) output: Cascade Ports
        ACOUT           => OPEN, -- 30-bit output: A port cascade output
        BCOUT           => OPEN, -- 18-bit output: B port cascade output
        CARRYCASCOUT    => OPEN, -- 1-bit output: Cascade carry output
        MULTSIGNOUT     => OPEN, -- 1-bit output: Multiplier sign cascade output
        PCOUT           => OPEN, -- 48-bit output: Cascade output
        -- Control: 1-bit (each) output: Control Inputs/Status Bits
        OVERFLOW        => OPEN, -- 1-bit output: Overflow in add/acc output
        PATTERNBDETECT  => OPEN, -- 1-bit output: Pattern bar detect output
        PATTERNDETECT   => OPEN, -- 1-bit output: Pattern detect output
        UNDERFLOW       => OPEN, -- 1-bit output: Underflow in add/acc output
        -- Data: 4-bit (each) output: Data Ports
        CARRYOUT        => OPEN, -- 4-bit output: Carry output
        P               => DOUT, -- 48-bit output: Primary data output
        -- Cascade: 30-bit (each) input: Cascade Ports
        ACIN            => (OTHERS => '0'), -- 30-bit input: A cascade data input
        BCIN            => (OTHERS => '0'), -- 18-bit input: B cascade input
        CARRYCASCIN     => '0', -- 1-bit input: Cascade carry input
        MULTSIGNIN      => '0', -- 1-bit input: Multiplier sign input
        PCIN            => (OTHERS => '0'), -- 48-bit input: P cascade input
        -- Control: 4-bit (each) input: Control Inputs/Status Bits
        ALUMODE         => "0000",          -- 4-bit input: ALU control input
        CARRYINSEL      => "000",           -- 3-bit input: Carry select input
        CEINMODE        => '0',             -- 1-bit input: Clock enable input for INMODEREG
        CLK             => CLK,             -- 1-bit input: Clock input
        INMODE          => "00000",         -- 5-bit input: INMODE control input
        OPMODE          => "0110101",       -- 7-bit input: Operation mode input
        RSTINMODE       => '0',             -- 1-bit input: Reset input for INMODEREG
        -- Data: 30-bit (each) input: Data Ports
        A               => A,               -- 30-bit input: A data input
        B               => DIN_B,           -- 18-bit input: B data input
        C               => DIN_C,           -- 48-bit input: C data input
        CARRYIN         => '0',             -- 1-bit input: Carry input signal
        D               => (OTHERS => '0'), -- 25-bit input: D data input
        -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
        CEA1            => '0',             -- 1-bit input: Clock enable input for 1st stage AREG
        CEA2            => '0',             -- 1-bit input: Clock enable input for 2nd stage AREG
        CEAD            => '0',             -- 1-bit input: Clock enable input for ADREG
        CEALUMODE       => '0',             -- 1-bit input: Clock enable input for ALUMODERE
        CEB1            => '0',             -- 1-bit input: Clock enable input for 1st stage BREG
        CEB2            => '0',             -- 1-bit input: Clock enable input for 2nd stage BREG
        CEC             => '0',             -- 1-bit input: Clock enable input for CREG
        CECARRYIN       => '0',             -- 1-bit input: Clock enable input for CARRYINREG
        CECTRL          => '0',             -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
        CED             => '0',             -- 1-bit input: Clock enable input for DREG
        CEM             => '0',             -- 1-bit input: Clock enable input for MREG
        CEP             => EN,              -- 1-bit input: Clock enable input for PREG
        RSTA            => '0',             -- 1-bit input: Reset input for AREG
        RSTALLCARRYIN   => '0',             -- 1-bit input: Reset input for CARRYINREG
        RSTALUMODE      => '0',             -- 1-bit input: Reset input for ALUMODEREG
        RSTB            => '0',             -- 1-bit input: Reset input for BREG
        RSTC            => '0',             -- 1-bit input: Reset input for CREG
        RSTCTRL         => '0',             -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
        RSTD            => '0',             -- 1-bit input: Reset input for DREG and ADREG
        RSTM            => '0',             -- 1-bit input: Reset input for MREG
        RSTP            => '0'              -- 1-bit input: Reset input for PREG
    );
    ------------------------------------------------------------------------------
    
END Structural;
