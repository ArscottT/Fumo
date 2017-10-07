----------------------------------------------------------------------------------
-- FUMO sumo robot
-- Based on the Mojo V3 FPGA
--
--Mojo base VHLD file:
--Translated from Mojo-base Verilog project @ http://embeddedmicro.com/frontend/files/userfiles/files/Mojo-Base.zip
--by Xark
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

LIBRARY work;
USE work.constants.ALL;

entity mojo_top is
	port (
        ----mojo standard signals----
		clk			: in  std_logic;		-- 50Mhz clock
		rst_n		: in  std_logic;		-- "reset" button input (negative logic)
		cclk		: in  std_logic;		-- configuration clock (?) from AVR (to detect when AVR ready)
		led			: out std_logic_vector(7 downto 0);	 -- 8 LEDs on Mojo board
		spi_sck		: in  std_logic;		-- SPI clock to from AVR
		spi_ss		: in  std_logic;		-- SPI slave select from AVR
		spi_mosi	: in  std_logic;		-- SPI serial data master out, slave in (AVR -> FPGA)
		spi_miso	: out std_logic;		-- SPI serial data master in, slave out (AVR <- FPGA)
		spi_channel : out std_logic_vector(3 downto 0);  -- analog read channel (input to AVR service task)
		avr_tx		: in  std_logic;		-- serial data transmited from AVR/USB (FPGA recieve)
		avr_rx		: out std_logic;		-- serial data for AVR/USB to receive (FPGA transmit)
		avr_rx_busy : in  std_logic;		-- AVR/USB buffer full (don't send data when true)
        ----additional io----
        io_reflectance_1  : INOUT std_logic;
        io_reflectance_2  : INOUT std_logic;
        o_pd1_left        : OUT std_logic;
        o_pd2_left        : OUT std_logic;
        o_motor_pwm_left  : OUT std_logic;
        o_pd1_right       : OUT std_logic;
        o_pd2_right       : OUT std_logic;
        o_motor_pwm_right : OUT std_logic
    );
end mojo_top;

architecture RTL of mojo_top is
------------------------------------------------------------------------------
--MOJO AVR STANDARD SIGNALS
------------------------------------------------------------------------------
signal rst	: std_logic;		-- reset signal (rst_n inverted for postive logic)
-- signals for avr_interface
signal channel			: std_logic_vector(3 downto 0);
signal sample			: std_logic_vector(9 downto 0);
signal sample_channel	: std_logic_vector(3 downto 0);
signal new_sample		: std_logic;
signal tx_data			: std_logic_vector(7 downto 0);
signal rx_data			: std_logic_vector(7 downto 0);
signal new_tx_data		: std_logic;
signal new_rx_data		: std_logic;
signal tx_busy			: std_logic;
-- signals for UART echo test
signal uart_data		: std_logic_vector(7 downto 0);	-- data buffer for UART (holds last recieved/sent byte)
signal data_to_send	    : std_logic;					-- indicates data to send in uart_data
-- signals for sample test
signal last_sample	    : std_logic_vector(9 downto 0);

    ------------------------------------------------------------------------------
    --ADDITIONAL SIGNALS FOR FUMO
    ------------------------------------------------------------------------------
    TYPE state_type IS (idle, forward, left_pivot, right_pivot);
    SIGNAL state                       : state_type := idle;
    SIGNAL left_fired_s, right_fired_s : std_logic := '0';
    SIGNAL motor_control_s             : std_logic_vector(2 DOWNTO 0) := "000";
    SIGNAL counter_s                   : integer := 0; ---- work out range for this

begin

    rst	<= NOT rst_n;						-- generate non-inverted reset signal from rst_n button

    ------------------------------------------------------------------------------
    --FUMO CONTROL
    ------------------------------------------------------------------------------
    ----state change process----
    PROCESS(clk) BEGIN
        IF rising_edge(clk) THEN
            IF (rst = '1') THEN
                state <= idle;
            ELSE
                CASE state IS
                    WHEN idle =>
                        led(7 DOWNTO 2) <= "100000";
                        motor_control_s <= stop_c;
                        state           <= forward;

                    WHEN forward =>
                        led(7 DOWNTO 2) <= "010000";
                        motor_control_s <= forward_c;
                        IF (left_fired_s = '1' AND right_fired_s = '1') THEN
                            counter_s <= pivot_time_c;
                            state     <= right_pivot; --create new state 180
                        ELSIF (left_fired_s = '1') THEN
                            counter_s <= pivot_time_c;
                            state     <= right_pivot;
                        ELSIF (right_fired_s = '1') THEN
                            counter_s <= pivot_time_c;
                            state     <= left_pivot;
                        END IF;

                    WHEN left_pivot =>
                        led(7 DOWNTO 2) <= "001000";
                        motor_control_s <= left_pivot_c;
                        IF (counter_s = 0) THEN
                            state <= forward;
                        ELSE
                            counter_s <= counter_s - 1;
                        END IF;

                    WHEN right_pivot =>
                        led(7 DOWNTO 2) <= "000100";
                        motor_control_s <= right_pivot_c;
                        IF (counter_s = 0) THEN
                            state <= forward;
                        ELSE
                            counter_s <= counter_s - 1;
                        END IF;
                    END CASE;
            END IF;
        END IF;
    END PROCESS;

    led(1) <= left_fired_s; --LED flickers to quick to see
    led(0) <= right_fired_s;

    ------------------------------------------------------------------------------
    --COMPONENT INSTANTIATION
    ------------------------------------------------------------------------------
    -- instantiate the avr_interface (to handle USB UART and analog sampling, etc.)
    avr_interface : entity work.avr_interface
	port map (
		clk			=> clk,				-- 50Mhz clock
		rst			=> rst,				-- reset signal
		-- AVR MCU pin connections (that will be managed)
		cclk		=> cclk,
		spi_miso	=> spi_miso,
		spi_mosi	=> spi_mosi,
		spi_sck		=> spi_sck,
		spi_ss		=> spi_ss,
		spi_channel	=> spi_channel,
		tx			=> avr_rx,
		tx_block	=> avr_rx_busy,
		rx			=> avr_tx,
		-- analog sample interface
		channel		=> channel,			-- set this to channel to sample (0, 1, 4, 5, 6, 7, 8, or 9)
		new_sample	=> new_sample,		-- indicates when new sample available
		sample_channel => sample_channel,	-- channel number of sample (only when new_sample = '1')
		sample		=> sample,			-- 10 bit sample value (only when new_sample = '1')
		-- USB UART tx interface
		new_tx_data	=> new_tx_data,		-- set to set data in tx_data (only when tx_busy = '0')
		tx_data		=> tx_data,			-- data to send
		tx_busy		=> tx_busy,			-- indicates AVR is not ready to send data
		-- USB UART rx interface
		new_rx_data	=> new_rx_data,		-- set when new data is received
		rx_data		=> rx_data			-- received data (only when new_tx_data = '1')
	);

    ----motor controller----
    motor_control : ENTITY work.motor_control
        PORT MAP(
            i_clk             => clk,
            i_control         => motor_control_s,
            o_pd1_left        => o_pd1_left,
            o_pd2_left        => o_pd2_left,
            o_motor_pwm_left  => o_motor_pwm_left,
            o_pd1_right       => o_pd1_right,
            o_pd2_right       => o_pd2_right,
            o_motor_pwm_right => o_motor_pwm_right
        );
    ----reflectance sensors----
    refectance_sensors : ENTITY work.reflectance_sens
        PORT MAP (
    	    i_clk            => clk,
    		io_reflectance_1 => io_reflectance_1,
    		io_reflectance_2 => io_reflectance_2,
            o_left_fired     => left_fired_s,
            o_right_fired    => right_fired_s
    	 );

end RTL;
