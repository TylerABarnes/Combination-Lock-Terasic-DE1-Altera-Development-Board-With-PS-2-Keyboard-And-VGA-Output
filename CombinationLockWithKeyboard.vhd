library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.StatePackage.all;

--This is the main file
entity CombinationLockWithKeyboardAndVGA is
    port(
        key                     : in std_logic_vector(3 downto 0);
        ps2_dat                 : in std_logic;
        ps2_clk                 : in std_logic;
        hex3, hex2, hex1, hex0  : out std_logic_vector(0 to 6);
        clock_50                : in std_logic;
	ledr                    : out STD_LOGIC_VECTOR (9 downto 0);
	ledg                    : out STD_LOGIC_VECTOR (7 downto 0);
	reset                   : in  STD_LOGIC;
        Hsync                   : out STD_LOGIC;
        Vsync                   : out STD_LOGIC;
        vga_r                   : out STD_LOGIC_VECTOR (11 downto 0);
        vga_g                   : out STD_LOGIC_VECTOR (11 downto 0);
        vga_b                   : out STD_LOGIC_VECTOR (11 downto 0);
        vga_hs                  : out STD_LOGIC;
        vga_vs                  : out STD_LOGIC
    );
end entity;

package StatePackage is
    type state is (ready, ok1, ok2, ok3, yes, err1, err2, err3, fail);
end StatePackage;

architecture rtl of CombinationLockWithKeyboardAndVGA is

--Takes integer and converts to 7-segment LED
function hex_digit(x:integer; hide_zero:boolean := true)
return std_logic_vector is
begin	
	case x is
		when 0 =>
			if hide_zero then
				return "1111111";
			else
				return "0000001";
			end if;
		when 1 => return "1001111";
		when 2 => return "0010010";
		when 3 => return "0000110";
		when 4 => return "1001100";
		when 5 => return "0100100";
		when 6 => return "0100000";
		when 7 => return "0001111";
		when 8 => return "0000000";
		when 9 => return "0000100";
		when others => return "1111111";
	end case;
end function;

type state is (ready, ok1, ok2, ok3, yes, err1, err2, err3, fail);
signal current_state, next_state : state := ready;

signal last_key : std_logic_vector(3 downto 0) := "1111";    --Remember 1's == not pressed

subtype door_digit is integer range 0 to 4; 
type door_code_type is array(0 to 3) of door_digit;

constant unlock_code : door_code_type := (4, 3, 2, 1);       --Correct combination
signal entered_digits : door_code_type := (0, 0, 0, 0); 

--Remember we can't have a process which is sensitive to each of the four buttons, so we made digit_entered which combines them all
signal digit_entered : integer := -1; --Assigned User hasn't pressed any digit at all yet
signal entry_position, next_entry_position : integer := 0;

    -- Keyboard shift component
    component KeyboardShift
        Port (
            ps2_dat  : in STD_LOGIC;
            ps2_clk  : in STD_LOGIC;
            clock_50 : in STD_LOGIC;
            ledr     : out STD_LOGIC_VECTOR(9 downto 0);
            ledg     : out STD_LOGIC_VECTOR(7 downto 0);
            hex0     : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    signal keyboard_hex : std_logic_vector(6 downto 0);
    signal keyboard_digit : integer := -1; -- A variable to hold the digit entered from the keyboard
	 signal keyboard_digit_handled : boolean := false;
	 
	  -- VGA40 component
	 component VGA40 is
        Port ( 
		     clock_50      : in  STD_LOGIC;
           reset         : in  STD_LOGIC;
           Hsync         : out STD_LOGIC;
           Vsync         : out STD_LOGIC;
           vga_r         : out STD_LOGIC_VECTOR (11 downto 0);
           vga_g         : out STD_LOGIC_VECTOR (11 downto 0);
           vga_b         : out STD_LOGIC_VECTOR (11 downto 0);
           vga_hs        : out STD_LOGIC;
           vga_vs        : out STD_LOGIC;
			  current_state : in state
		  );
    end component;
	 
begin

		  --Different options depending on the state
hex3 <= "1111110" when current_state = ready
			else "0011000" when current_state =  yes --P
			else "0111000" when current_state = fail -- F
			else hex_digit(entered_digits(0));
hex2 <= "1111110" when current_state = ready
			else "0001000" when current_state = yes  --A
			else "0001000" when current_state = fail -- A
			else hex_digit(entered_digits(1));
hex1 <= "1111110" when current_state = ready
			else "0100100" when current_state = yes  --S
			else "1001111" when current_state = fail -- I
			else hex_digit(entered_digits(2));
hex0 <= "1111110" when current_state = ready
			else "0100100" when current_state = yes  --S
			else "1110001" when current_state = fail -- L
			else hex_digit(entered_digits(3));
			
    -- Instantiate the KeyboardShift component
    keyShift : KeyboardShift
        port map (
            ps2_dat => ps2_dat,
            ps2_clk => ps2_clk,
            clock_50 => clock_50,
            ledr => ledr, 
            ledg => ledg, 
            hex0 => keyboard_hex  --11-bit scan code is assigned to hex in orignal PS/2 file
        );

    -- Process to detect the digit entered from the keyboard
    process(clock_50)
    begin
        if rising_edge(clock_50) then
            -- Decode the 7-segment hex display to obtain the digit
            case keyboard_hex is
                when "1000000" => keyboard_digit <= 0;
                when "1111001" => keyboard_digit <= 1;
                when "0100100" => keyboard_digit <= 2;
                when "0110000" => keyboard_digit <= 3;
                when "0011001" => keyboard_digit <= 4;
                when "0010010" => keyboard_digit <= 5;
                when "0000010" => keyboard_digit <= 6;
                when "1111000" => keyboard_digit <= 7;
                when "0000000" => keyboard_digit <= 8;
                when "0010000" => keyboard_digit <= 9;
                when others => keyboard_digit <= -1; -- No valid digit
            end case;
        end if;
    end process;

	 -- Instantiate the VGA40 component
	 vgaDisplay : VGA40
    port map (
        clock_50      => clock_50,
        reset         => reset,
        Hsync         => Hsync,
        Vsync         => Vsync,
        vga_r         => vga_r,
        vga_g         => vga_g,
        vga_b         => vga_b,
        vga_hs        => vga_hs,
        vga_vs        => vga_vs,
		  current_state => current_state
    );

--Process to detect that some digit has been entered
-- State Transition Logic
process(clock_50) is
begin
    if rising_edge(clock_50) then
        if digit_entered /= -1 then --If someone actually entered a valid digit
            --Write the entered digit
            entered_digits(entry_position) <= digit_entered;
            
            --Error states propagate always (can't escape the error state)
            if current_state = err1 then    
                next_state <= err2;
            elsif current_state = err2 then
                next_state <= err3;
            elsif current_state = err3 then
                next_state <= fail;
                entered_digits <= (0, 0, 0, 0);
            else --If not in error state, then check 
                if digit_entered = unlock_code(entry_position) then
                    if current_state = ready or current_state = fail or current_state = yes then
                        next_state <= ok1;
                    elsif current_state = ok1 then
                        next_state <= ok2;
                    elsif current_state = ok2 then
                        next_state <= ok3;
                    elsif current_state = ok3 then
                        next_state <= yes;
                        entered_digits <= (0, 0, 0, 0);
                    end if;
                else 
                    if current_state = ready or current_state = fail or current_state = yes then
                        next_state <= err1;
                    elsif current_state = ok1 then
                        next_state <= err2;
                    elsif current_state = ok2 then
                        next_state <= err3;
                    elsif current_state = ok3 then
                        next_state <= fail;
                        entered_digits <= (0, 0, 0, 0);
                    end if;
                end if;
            end if;

            next_entry_position <= (entry_position + 1) rem 4; --A counter that tells you which position to write the number into
            entry_position <= next_entry_position; -- update entry position
            
            -- Update current state
            current_state <= next_state;
        end if;
    end if;
end process;

    -- Modify the Button Input Handling process
    -- to include the keyboard_digit signal as well
process(clock_50)
begin
----------------------To Switch From Keyboard Input To Button Input, Press A Non-Numerical Key Then Try Using The Buttons Again--------------------------
    if rising_edge(clock_50) then

        if key(3) = '1' and last_key(3) = '0' then	
            digit_entered <= 1;
            keyboard_digit_handled <= false; -- Reset the flag when a new key is pressed
        elsif key(2) = '1' and last_key(2) = '0' then
            digit_entered <= 2;
            keyboard_digit_handled <= false; -- Reset the flag when a new key is pressed
        elsif key(1) = '1' and last_key(1) = '0' then
            digit_entered <= 3;
            keyboard_digit_handled <= false; -- Reset the flag when a new key is pressed
        elsif key(0) = '1' and last_key(0) = '0' then
            digit_entered <= 4;
            keyboard_digit_handled <= false; -- Reset the flag when a new key is pressed
        elsif keyboard_digit /= -1 and not keyboard_digit_handled then
            digit_entered <= keyboard_digit; -- Include the digit from the keyboard
            keyboard_digit_handled <= true; -- Set the flag to true, so the value won't be assigned again
        else
            digit_entered <= -1;
            if keyboard_digit = -1 then
                keyboard_digit_handled <= false; -- Reset the flag only if no keyboard digit is detected
            end if;
        end if;

        last_key <= key;  -- A snapshot of the keys that have been pressed last time round
    end if;
end process;

end architecture;
