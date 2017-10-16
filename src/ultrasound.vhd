LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

ENTITY ultrasound_sensor IS
    PORT (
        i_clk     : IN std_logic;
        o_found   : OUT std_logic;
        io_sensor : INOUT std_logic
    );
END ultrasound_sensor;

ARCHITECTURE rtl OF ultrasound_sensor IS

    TYPE state_type IS (idle, ping, wait_high, wait_low, compare);
    SIGNAL state : state_type := idle;

    SIGNAL counter_s : integer := 0; -- work out count for 10us
    SIGNAL timer_s   : integer := 0;
BEGIN

    PROCESS(i_clk) BEGIN
        IF rising_edge(i_clk) THEN
            CASE state IS
                WHEN idle =>
                    o_found <= '0';
                    state <= ping;

                WHEN ping =>
                    IF (counter_s = 0) THEN
                        io_sensor <= 'Z';
                        counter_s <= us10_count_c;-------WORK THIS OUT
                        state     <= wait_high;
                    ELSE
                        io_sensor <= '1';
                        counter_s <= counter_s - 1;
                    END IF;

                WHEN wait_high =>
                    IF (io_sensor = '1') THEN
                        timer_s <= timer_s + 1;
                        state   <= wait_low;
                    END IF;

                WHEN wait_low =>
                    IF (io_sensor = '0') THEN
                        state <= compare;
                    ELSE
                        timer_s <= timer_s + 1;
                    END IF;

                WHEN compare =>
                    IF (timer_s <= ultras_threshold_c) THEN
                        o_found <= '1';
                    END IF;

                    state <= idle;
            END CASE;
        END IF;
    END PROCESS;
END rtl;
