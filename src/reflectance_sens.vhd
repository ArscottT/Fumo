library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

ENTITY reflectance_sens IS
    PORT (
	    i_clk            : IN  std_logic;
		io_reflectance_1 : INOUT std_logic;
		io_reflectance_2 : INOUT std_logic;
        o_left_fired     : OUT std_logic;
        o_right_fired    : OUT std_logic
	 );
END reflectance_sens;

ARCHITECTURE rtl OF reflectance_sens IS

    CONSTANT threshold : integer := 15000;

    TYPE state_type IS (idle, ping, wait_rise, switch, wait_low, compare);
    SIGNAL state            : state_type := idle;
    SIGNAL timer_1, timer_2 : integer := 0;
    SIGNAL counter   : integer := 500000;

BEGIN

    PROCESS(i_clk) BEGIN
        IF rising_edge(i_clk) THEN
            CASE state IS
                WHEN idle =>
                    state         <= ping;
                    o_left_fired  <= '0';
                    o_right_fired <= '0';
					timer_1       <= 0;
					timer_2       <= 0;

                WHEN ping =>
                    io_reflectance_1 <= '1';
                    io_reflectance_2 <= '1';
                    state            <= wait_rise;

				WHEN wait_rise =>
					IF (counter = 0) THEN
					    counter <= 500000;
					    state   <= switch;
					ELSE
					    counter <= counter - 1;
					END IF;

				WHEN switch =>
                    io_reflectance_1 <= 'Z';
                    io_reflectance_2 <= 'Z';
                    state            <= wait_low;

                WHEN wait_low =>
                    IF (io_reflectance_1 /= '0') THEN
                        timer_1 <= timer_1 + 1;
                    END IF;

                    IF (io_reflectance_2 /= '0') THEN
                        timer_2 <= timer_2 + 1;
                    END IF;

                    IF (io_reflectance_1 = '0' AND io_reflectance_2 = '0') THEN
                        state <= compare;
                    END IF;

                WHEN compare =>
                    IF (timer_1 < threshold) THEN
                        o_left_fired <= '1';
                        timer_1      <= 0;
                    END IF;

                    IF (timer_2 < threshold) THEN
                        o_right_fired <= '1';
                        timer_2       <= 0;
                    END IF;

					state <= idle;

            END CASE;
        END IF;
    END PROCESS;

END rtl;
