LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY motor_control IS
    PORT (
        i_clk             : IN std_logic;
        i_control         : IN std_logic_vector(2 DOWNTO 0);
        o_pd1_left        : OUT std_logic;
        o_pd2_left        : OUT std_logic;
        o_motor_pwm_left  : OUT std_logic;
        o_pd1_right       : OUT std_logic;
        o_pd2_right       : OUT std_logic;
        o_motor_pwm_right : OUT std_logic
    );
END motor_control;

ARCHITECTURE rtl OF motor_control IS

    ----state signals----
    TYPE state_type IS (idle, forward, backward, left_turn, right_turn,
                        pivot_left, pivot_right);
    SIGNAL state : state_type := idle;

    ----motor control signals----
    SIGNAL motor_direction_left_s  : std_logic_vector(1 DOWNTO 0);
    SIGNAL motor_direction_right_s : std_logic_vector(1 DOWNTO 0);
    SIGNAL motor_speed_left_s, motor_speed_right_s : integer RANGE 0 TO 100;

BEGIN

    ----state change logic----
    PROCESS(i_clk) BEGIN
        IF rising_edge(i_clk) THEN
            CASE i_control IS
                WHEN "000" =>
                    state <= idle;
                WHEN "111" =>
                    state <= forward;
                WHEN "100" =>
                    state <= backward;
                WHEN "110" =>
                    state <= left_turn;
                WHEN "101" =>
                    state <= right_turn;
                WHEN "010" =>
                    state <= pivot_left;
                WHEN "001" =>
                    state <= pivot_right;
                WHEN OTHERS => NULL;
            END CASE;
        END IF;
    END PROCESS;

    ----output logic for each state----
    PROCESS(state) BEGIN
        CASE state IS
            WHEN idle =>
                motor_direction_left_s  <= "11";
                motor_direction_right_s <= "11";
                motor_speed_left_s      <= 0;
                motor_speed_right_s     <= 0;

            WHEN forward =>
                motor_direction_left_s  <= "10";
                motor_direction_right_s <= "10";
                motor_speed_left_s      <= 50;
                motor_speed_right_s     <= 50;

            WHEN backward =>
                motor_direction_left_s  <= "01";
                motor_direction_right_s <= "01";
                motor_speed_left_s      <= 50;
                motor_speed_right_s     <= 50;

            WHEN pivot_left =>
                motor_direction_left_s  <= "10";
                motor_direction_right_s <= "01";
                motor_speed_left_s      <= 20;
                motor_speed_right_s     <= 20;

            WHEN pivot_right =>
                motor_direction_left_s  <= "01";
                motor_direction_right_s <= "10";
                motor_speed_left_s      <= 20;
                motor_speed_right_s     <= 20;

            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS;

    ----pwm controller for motor on left side----
    motor_left : ENTITY work.pwm
        GENERIC MAP (
            input_clk_g  => 50000000, -- 50MHz
            freq_g		 => 100, -- 100Hz
            motor_flip_g => '0'
        )
        PORT MAP (
            i_clk       => i_clk,
            i_speed     => motor_speed_left_s,
            i_direction => motor_direction_left_s,
            o_pd1       => o_pd1_left,
            o_pd2       => o_pd2_left,
            o_motor_pwm => o_motor_pwm_left
        );

    ----pwm controller for motor on right side----
    motor_right : ENTITY work.pwm
        GENERIC MAP (
            input_clk_g  => 50000000, -- 50MHz
            freq_g		 => 100, -- 100Hz
            motor_flip_g => '0'
        )
        PORT MAP (
            i_clk       => i_clk,
            i_speed     => motor_speed_right_s,
            i_direction => motor_direction_right_s,
            o_pd1       => o_pd1_right,
            o_pd2       => o_pd2_right,
            o_motor_pwm => o_motor_pwm_right
        );

END rtl;
