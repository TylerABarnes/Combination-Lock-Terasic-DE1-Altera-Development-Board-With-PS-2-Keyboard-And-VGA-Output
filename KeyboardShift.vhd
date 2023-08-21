library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--This code acts as a shift register where the PS/2 keyboard's clock pin acts as the shift clock and the PS/2 data pin acts as the serial data input
--It shifts the 11-bit scancode into a register then outputs it to the LEDs on the development board
--This file uses the pin assignments found in the DE1 CD-ROM Lab Exercises folder

entity KeyboardShift is
    Port ( ps2_dat    : in  STD_LOGIC;                     -- PS/2 data pin
           ps2_clk    : in  STD_LOGIC;                     -- PS/2 clock pin
           clock_50   : in  STD_LOGIC;                     -- 50 MHz system clock
           ledr       : out STD_LOGIC_VECTOR (9 downto 0); -- Red LEDs output (10 bits)
           ledg       : out STD_LOGIC_VECTOR (7 downto 0); -- Green LEDs output (8 bits)
           hex0       : out STD_LOGIC_VECTOR (6 downto 0)  -- 7-segment hex display
           );
end KeyboardShift;

architecture Behavioral of KeyboardShift is
    signal shift_reg          : STD_LOGIC_VECTOR (10 downto 0) := "00000000000";
    signal inverted_ps2_clock : STD_LOGIC;                                       -- Inverted PS/2 clock signal
    signal synchronized_shift_reg : STD_LOGIC_VECTOR (10 downto 0);              -- Shift register content synchronized with the system clock

    function decode_scan_code(code: STD_LOGIC_VECTOR(10 downto 0)) return STD_LOGIC_VECTOR is
    begin
        case code is
				--Top Row Of Numbers
            when "01010001001" => return "1000000"; -- 0
            when "00110100001" => return "1111001"; -- 1
            when "00111100011" => return "0100100"; -- 2
            when "00110010001" => return "0110000"; -- 3
            when "01010010001" => return "0011001"; -- 4
            when "00111010011" => return "0010010"; -- 5
            when "00110110011" => return "0000010"; -- 6
            when "01011110001" => return "1111000"; -- 7
            when "00111110001" => return "0000000"; -- 8
            when "00110001001" => return "0010000"; -- 9
				
				--Key Pad
            when "00000111001" => return "1000000"; -- 0
            when "01001011011" => return "1111001"; -- 1
            when "00100111011" => return "0100100"; -- 2
            when "00101111001" => return "0110000"; -- 3
            when "01101011001" => return "0011001"; -- 4
            when "01100111001" => return "0010010"; -- 5
            when "00010111011" => return "0000010"; -- 6
            when "00011011011" => return "1111000"; -- 7
            when "01010111001" => return "0000000"; -- 8
            when "01011111011" => return "0010000"; -- 9
            when others => return "1111111";        -- Default (blank display)
        end case;
    end function decode_scan_code;
    
begin

inverted_ps2_clock <= not ps2_clk;                                               -- Invert the PS/2 clock signal

process(inverted_ps2_clock)
begin
    if rising_edge(inverted_ps2_clock) then                                      -- Detect rising edge of inverted PS/2 clock
        shift_reg <= shift_reg(9 downto 0) & ps2_dat;                            -- Shift and concatenate new data bit
    end if;
end process;

process(clock_50)
begin
    if rising_edge(clock_50) then                                                -- Capture the shift register's content on the rising edge of the 50 MHz system clock
        synchronized_shift_reg <= shift_reg;
    end if;
end process;

ledr <= synchronized_shift_reg(9 downto 0);                                      -- Output the first 10 bits of the synchronized data to the red LEDs
ledg(7) <= synchronized_shift_reg(10);                                           -- Output the 11th bit to the green LED (ledg7)

hex0 <= decode_scan_code(synchronized_shift_reg);                                -- Decode the 11-bit scan code and display on right most 7-segment hex display

end Behavioral;