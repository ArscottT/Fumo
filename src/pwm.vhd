LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pwm IS
    GENERIC (
        input_clk_g  : integer := 50000000; -- 50MHz
        freq_g		 : integer := 100; -- 100Hz
        motor_flip_g : std_logic := '0'
    );
    PORT (
        i_clk       : IN std_logic;
        i_speed     : IN integer RANGE 0 TO 100;
        i_direction : IN std_logic_vector(1 DOWNTO 0);
        o_pd1       : OUT std_logic;
        o_pd2       : OUT std_logic;
        o_motor_pwm : OUT std_logic
    );
END pwm;

ARCHITECTURE rtl OF pwm IS

    CONSTANT max_freq_count_c : integer := input_clk_g / freq_g;

    SIGNAL freq_count_s        : integer RANGE 0 to max_freq_count_c := max_freq_count_c;
    SIGNAL limit_s             : integer RANGE 0 to max_freq_count_c := 0;
    SIGNAL pwm_s, pd1_s, pd2_s : std_logic := '0';

BEGIN

    ----motor direction control----
    PROCESS(i_direction) BEGIN
        CASE i_direction IS
            WHEN "10" => --forward
                pd1_s <= '0';
                pd2_s <= '1';
            WHEN "01" => --backward
                pd1_s <= '1';
                pd2_s <= '0';
            WHEN "00" => --coast
                pd1_s <= '0';
                pd2_s <= '0';
            WHEN "11" => --break
                pd1_s <= '1';
                pd2_s <= '1';
            WHEN OTHERS =>
                null; --why is this needed?
        END CASE;
    END PROCESS;

    ----motor speed---- --TEMPORARY SOLUTION-----
    PROCESS (i_speed) BEGIN
        CASE i_speed IS
            WHEN 0 =>
                limit_s <= 0;
            WHEN 20 =>
                limit_s <= max_freq_count_c / 5;
            WHEN 50 =>
                limit_s <= max_freq_count_c / 2;
            WHEN 100 =>
                limit_s <= max_freq_count_c;
            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS;

    ----pwn timer control----
    PROCESS (i_clk) BEGIN
        IF rising_edge(i_clk) THEN
            IF (freq_count_s = 0) THEN
                freq_count_s <= max_freq_count_c;
            ELSE
                freq_count_s <= freq_count_s - 1;
            END IF;
        END IF;
    END PROCESS;

    ----pwm output control----
    PROCESS(freq_count_s) BEGIN
        IF (freq_count_s <= limit_s) THEN
            pwm_s <= '1';
        ELSE
            pwm_s <= '0';
        END IF;
    END PROCESS;

    ----assign registers to outputs----
    o_pd1 <= pd2_s WHEN motor_flip_g = '1' ELSE pd1_s;
    o_pd2 <= pd1_s WHEN motor_flip_g = '1' ELSE pd2_s;

    o_motor_pwm <= pwm_s;
END rtl;
