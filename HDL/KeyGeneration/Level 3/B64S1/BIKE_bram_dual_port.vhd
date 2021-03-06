----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2019 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATE:			    14/03/2019
-- LAST CHANGES:            14/03/2019
-- MODULE NAME:			    BIKE_BRAM_DUAL_PORT
--
-- REVISION:				1.00 - File created.
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or	if you have questions regarding the code
--							please contact Tim G�neysu (tim.gueneysu@rub.de) and
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
    USE UNISIM.vcomponents.ALL;
LIBRARY UNIMACRO;
    USE unimacro.Vcomponents.ALL;

LIBRARY work;
    USE work.BIKE_SETTINGS.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY BIKE_BRAM_DUAL_PORT IS
	PORT ( 
	   -- CONTROL PORTS ----------------
        CLK             : IN  STD_LOGIC; 	
        RESET           : IN  STD_LOGIC;
        WEN_A           : IN  STD_LOGIC;
        WEN_B           : IN  STD_LOGIC;
        REN_A           : IN  STD_LOGIC;
        REN_B           : IN  STD_LOGIC;
        -- I/O -------------------------
        ADDR_A          : IN  STD_LOGIC_VECTOR( 9 DOWNTO 0);
        ADDR_B          : IN  STD_LOGIC_VECTOR( 9 DOWNTO 0);
        DOUT_A          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DOUT_B          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN_A           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        DIN_B           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END BIKE_BRAM_DUAL_PORT;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF BIKE_BRAM_DUAL_PORT IS



-- SIGNALS
----------------------------------------------------------------------------------
SIGNAL WENB             : STD_LOGIC_VECTOR( 7 DOWNTO 0);
SIGNAL WENA             : STD_LOGIC_VECTOR( 3 DOWNTO 0);
SIGNAL ADDRA, ADDRB     : STD_LOGIC_VECTOR(15 DOWNTO 0);



-- BEHAVIORAL
----------------------------------------------------------------------------------
BEGIN

    -- INPUT MULTIPLEXING --------------------------------------------------------
    WENA <=          WEN_A & WEN_A & WEN_A & WEN_A;
    WENB <= "0000" & WEN_B & WEN_B & WEN_B & WEN_B;
    
    -- EXTEND ADDRESSES ----------------
    ADDRA <= '0' & ADDR_A & "00000";
    ADDRB <= '0' & ADDR_B & "00000";
    ------------------------------------------------------------------------------
    

    -- TRUE DUAL BRAM ------------------------------------------------------------
    RAMB36E1_inst : RAMB36E1
    generic map (
        -- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
        RDADDR_COLLISION_HWCONFIG   => "DELAYED_WRITE",
        -- Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
        SIM_COLLISION_CHECK         => "ALL",
        -- DOA_REG, DOB_REG: Optional output register (0 or 1)
        DOA_REG                     => 0,
        DOB_REG                     => 0,
        EN_ECC_READ                 => FALSE, -- Enable ECC decoder, -- FALSE, TRUE
        EN_ECC_WRITE                => FALSE, -- Enable ECC encoder, -- FALSE, TRUE
        -- INIT_A, INIT_B: Initial values on output ports
        INIT_A                      => X"000000000",
        INIT_B                      => X"000000000",
        -- Initialization File: RAM initialization file
        INIT_FILE                   => "NONE",
        -- RAM Mode: "SDP" or "TDP"
        RAM_MODE                    => "TDP",
        -- RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
        RAM_EXTENSION_A             => "NONE",
        RAM_EXTENSION_B             => "NONE",
        -- READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port (inlcudes redundancy for ECC)
        READ_WIDTH_A                => 36, -- 0-72
        READ_WIDTH_B                => 36, -- 0-36
        WRITE_WIDTH_A               => 36, -- 0-36
        WRITE_WIDTH_B               => 36, -- 0-72
        -- RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
        RSTREG_PRIORITY_A           => "RSTREG",
        RSTREG_PRIORITY_B           => "RSTREG",
        -- SRVAL_A, SRVAL_B: Set/reset value for output
        SRVAL_A                     => X"000000000",
        SRVAL_B                     => X"000000000",
        -- Simulation Device: Must be set to "7SERIES" for simulation behavior
        SIM_DEVICE                  => "7SERIES",
        -- WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        WRITE_MODE_A                => "READ_FIRST", -- write first to target address and read back the written value
        WRITE_MODE_B                => "READ_FIRST", 
        --INIT_00 => X"0000000000000000000000000018fec9fff072f0a13fb955376c105e7493474c",
        --INIT_00 => X"000000000005324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- odd (r=211)
        --INIT_00 => X"0000000000000000001c31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- even (r=181)
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=373)
        --INIT_01 => X"000000000000000000000000000000000000c0316d49494d48ff3ab256b99f07", -- (r=373)
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=389)
        --INIT_01 => X"000000000000000000000000000000140140c0316d49494d48ff3ab256b99f07", -- (r=389)
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=419)
        --INIT_01 => X"000000000000000000000000c1d8a8540140c0316d49494d48ff3ab256b99f07", -- (r=419)
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=461)
        --INIT_01 => X"000000000000191888af0108c1d8a8540140c0316d49494d48ff3ab256b99f07", -- (r=461)
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=701)
        --INIT_01 => X"43225a581829191888af0108c1d8a8540140c0316d49494d48ff3ab256b99f07",
        --INIT_02 => X"00000000000000001621ec171d4bdd4493f7045fe10f87a97387abe6f2513a5e",
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=709)
        --INIT_01 => X"43225a581829191888af0108c1d8a8540140c0316d49494d48ff3ab256b99f07",
        --INIT_02 => X"00000000000000193621ec171d4bdd4493f7045fe10f87a97387abe6f2513a5e",
        --INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=1019)
        --INIT_01 => X"43225a581829191888af0108c1d8a8540140c0316d49494d48ff3ab256b99f07",
        --INIT_02 => X"8f6a695fad55db393621ec171d4bdd4493f7045fe10f87a97387abe6f2513a5e",
        --INIT_03 => X"07e02c9f9926023491f964b8db30e0d628787fabdf6198423cc3b5c279655125",
--        INIT_00 => X"8822617954bd324078bc31f32eb8fec9fff072f0a13fb955376c105e7493474c", -- (r=11779)
--        INIT_01 => X"43225a581829191888af0108c1d8a8540140c0316d49494d48ff3ab256b99f07", 
--        INIT_02 => X"8f6a695fad55db393621ec171d4bdd4493f7045fe10f87a97387abe6f2513a5e",
--        INIT_03 => X"afe02c9f9926023491f964b8db30e0d628787fabdf6198423cc3b5c279655125",
--        INIT_04 => X"f54e411010f36460462f7f523cc24d3e62aa1d29ea36091750865a59767c680a",
--        INIT_05 => X"30ef3dcdccf47b304595ce27cc2395f786e13352072d848824af6be5d32e95b7",
--        INIT_06 => X"52007dc24b1d1671a9caf49944fc539d8bad7acc1a3f398fd2057ac4360314da",
--        INIT_07 => X"d6cae54a040ac4c17e346ae5fa927b2be8082a3dc6ef1baf9e59283dd84f0e19",
--        INIT_08 => X"8f40679bb39eafa2be9bf26ce2fba4ecaea2f878c07cbb02019dc4f4ff5b3079",
--        INIT_09 => X"cc5ca2b926371b79c14b38a1ae1defd676a8aa9320f4c3af9097cf71cddfb7be",
--        INIT_0a => X"5e7c9ee964d4a3cc3b0cb47d240791f5ef04a425f70b24414fc1b2a0d1b46f86",
--        INIT_0b => X"07451dac8cccca402bb14bf0f220c289d309ad2400d66a19656611e6f22fe182",
--        INIT_0c => X"db8ab82d16cfe878cee2602140ea256cb045272ce8aa59d5079be16e5cb28cd5",
--        INIT_0d => X"d9fd5bd93ff576e79280f2eecc9f1ee21437ab4fdb89e329bc9c22d88f46cb16",
--        INIT_0e => X"13d02d7e9730af2451125374356e60998edd5af5a6847f2f5cf5c4dc09b6c189",
--        INIT_0f => X"64cffcf545da09b56943a909b3f91507f8101e71afc2b111a786bed928319d1c",
--        INIT_10 => X"c6b0a3c29784c5b65fd04526430a5dd6218a1afd6ec0d358b803f9adaa705a54",
--        INIT_11 => X"a2d417edac605d2f3e9a62301f565516529601fe6db34596a68b117c434212e7",
--        INIT_12 => X"33d09dc93baf0e40241c0064e9bbe29ab31cc90b46300ec2e584fd3e1a2677fb",
--        INIT_13 => X"6d7665d5cc8aafa593b58eec0041142f77762e870d0f2ee27eddef44ea5047ca",
--        INIT_14 => X"fc2f33bead26d751c517a8485a96f31415f3d11f3b020c5b44b66520aa41952e",
--        INIT_15 => X"4b850b5c7683fece1854ab1c9ac2f56eefefc81e3e3d3798f293817f2a9e214b",
--        INIT_16 => X"de962fba5dc82e21914af86c900b8103be5dc7c080ca001ebc8eccb9f2e361c6",
--        INIT_17 => X"e2c559a92f83367e9ea199d128ffa87489ee861d21d17e799e8c10f40a84e540",
--        INIT_18 => X"f1598116f4850df6a685db63d39dc4d544152cc51730fd435316ce0037f8f25e",
--        INIT_19 => X"e4b30227b5c21f2f721e51ee225893726144f4a381594ca249ad6dc40832b333",
--        INIT_1a => X"72063e1d336c31f9741b1b6b8f360cdd07d562e05d0efbf9f5fa116b1f72450a",
--        INIT_1b => X"ac0e0775043a4812c59f2274823c118e3350ffb11888338d638a2a0c759bfd95",
--        INIT_1c => X"1f7e6da84c12c456a7657618aaf8cd747051f2d32853bb333495e510dcbb1e3a",
--        INIT_1d => X"967cb496754e695bbd9f54b60fd28c96a851a01ff2e96a481b45cbd3366319d6",
--        INIT_1e => X"0a33d5ae8e2687e3a52f800931ed54ca0b2517ab655db53ab061f414b46f4eb9",
--        INIT_1f => X"e63c21d41ed67d0ae2d21276120a2b0c0b77b800f2daefef7f0c9702d2860e57",
--        INIT_20 => X"e28d699d64ee907efee669a5acc7d5a7e3999b7276dc212e9ed9f00d290b1a4c",
--        INIT_21 => X"f93f4faef7d7b8108fc438f3f84f2b84037f495075d69360183544f93465e9af",
--        INIT_22 => X"8b5b3b65f59d3b9b9a8ade225b08b2fa87f05839ac35e4a6b2b22eebaac83064",
--        INIT_23 => X"944d8eb612651948def8475715dabb46888c86da7a4039141d1a0a2c27f6adcf",
--        INIT_24 => X"542890bb68098665ea477e8b328078b43ba49d29a3223d1d3d870dc4763ade35",
--        INIT_25 => X"0f4e6f5a9a8a3b88f47546fc7a89d3049a7c4f7ad500f1a94a8cb1caad06c86c",
--        INIT_26 => X"42706a37903054f8630e0de5b5a7b9c2c70cb2b13ac756af554ca5bc1d70a62c",
--        INIT_27 => X"ff2004a901acece9cd4e969ff7dec9db922d47a61ff0b33cba298a1ea7beba53",
--        INIT_28 => X"d937bc663d2061610294760e5cea622c526a564b66ad5abcce76f24ae2360002",
--        INIT_29 => X"1f3691c268790bd35f39bbc2c06174d77f6ab46b0f72a4a9fb780752bb1ea494",
--        INIT_2a => X"883127a2a7b0a985006940e27ba9149088d036a8aeff43b167d8dc147d8f697b",
--        INIT_2b => X"4c1330638a68beece73b8bf65d93dae6c2314d3ba51acac680ef2ed7a6a4665e",
--        INIT_2c => X"1ef5ea11ac6abb6d929cb306c9456986ab083bddc8734dd4e8e235e17c021d1c",
--        INIT_2d => X"56d344f0ea03f1297813082e25b70a21fb4fc13badabbc4d4e3af5350655b5e3",
--        INIT_2e => X"0000000000000000000000000000000000000000000000000000000000000001",
        INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
        -- The next set of INIT_xx are valid when configured as 36Kb
        INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000"
    )
    port map (
        -- Cascade Signals: 1-bit (each) output: BRAM cascade ports (to create 64kx1)
        CASCADEOUTA     => open,    -- 1-bit output: A port cascade
        CASCADEOUTB     => open,    -- 1-bit output: B port cascade
        -- ECC Signals: 1-bit (each) output: Error Correction Circuitry ports
        DBITERR         => open,    -- 1-bit output: Double bit error status
        ECCPARITY       => open,    -- 8-bit output: Generated error correction parity
        RDADDRECC       => open,    -- 9-bit output: ECC read address
        SBITERR         => open,    -- 1-bit output: Single bit error status
        -- Cascade Signals: 1-bit (each) input: BRAM cascade ports (to create 64kx1)
        CASCADEINA      => '0',     -- 1-bit input: A port cascade
        CASCADEINB      => '0',     -- 1-bit input: B port cascade
        -- ECC Signals: 1-bit (each) input: Error Correction Circuitry ports
        INJECTDBITERR   => '0',     -- 1-bit input: Inject a double bit error
        INJECTSBITERR   => '0',     -- 1-bit input: Inject a single bit error
                
        -- Port A Data: 32-bit (each) output: Port A data
        DOADO           => DOUT_A,  -- 32-bit output: A port data/LSB data
        DOPADOP         => OPEN,    -- 4-bit output: A port parity/LSB parity
        
        -- Port B Data: 32-bit (each) output: Port B data
        DOBDO           => DOUT_B,  -- 32-bit output: B port data/MSB data
        DOPBDOP         => OPEN,    -- 4-bit output: B port parity/MSB parity
        

        -- Port A Address/Control Signals: 16-bit (each) input: Port A address and control signals (read port when RAM_MODE="SDP")
        ADDRARDADDR     => ADDRA,   -- 16-bit input: A port address/Read address
        CLKARDCLK       => CLK,     -- 1-bit input: A port clock/Read clock
        ENARDEN         => REN_A,     -- 1-bit input: A port enable/Read enable
        REGCEAREGCE     => REN_A,     -- 1-bit input: A port register enable/Register enable
        RSTRAMARSTRAM   => RESET,   -- 1-bit input: A port set/reset
        RSTREGARSTREG   => RESET,   -- 1-bit input: A port register set/reset
        WEA             => WENA,    -- 4-bit input: A port write enable
        -- Port A Data: 32-bit (each) input: Port A data
        DIADI           => DIN_A,   -- 32-bit input: A port data/LSB data
        DIPADIP         => "0000",  -- 4-bit input: A port parity/LSB parity
        
        -- Port B Address/Control Signals: 16-bit (each) input: Port B address and control signals (write port when RAM_MODE="SDP")
        ADDRBWRADDR     => ADDRB,   -- 16-bit input: B port address/Write address
        CLKBWRCLK       => CLK,     -- 1-bit input: B port clock/Write clock
        ENBWREN         => REN_B,     -- 1-bit input: B port enable/Write enable
        REGCEB          => REN_B,     -- 1-bit input: B port register enable
        RSTRAMB         => RESET,   -- 1-bit input: B port set/reset
        RSTREGB         => RESET,   -- 1-bit input: B port register set/reset
        WEBWE           => WENB,    -- 8-bit input: B port write enable/Write enable
        -- Port B Data: 32-bit (each) input: Port B data
        DIBDI           => DIN_B,   -- 32-bit input: B port data/MSB data
        DIPBDIP         => "0000"   -- 4-bit input: B port parity/MSB parity     
    );
    ------------------------------------------------------------------------------

END Behavioral;
