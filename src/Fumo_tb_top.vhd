library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity Fumo_tb_top is
end Fumo_tb_top;

architecture Behavioral of Fumo_tb_top is

    SIGNAL clk_s, rst_n_s, reflectance_1_s, reflectance_2_s, pd1_left_s, pd2_left_s, motor_pwm_left_s,
           pd1_right_s, pd2_right_s, motor_pwm_right_s : std_logic := '0';
    SIGNAL led_s    : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');

begin
    ----50Mhz clk----
    clk_s <= NOT clk_s AFTER 20ns;

    PROCESS(reflectance_1_s, reflectance_2_) BEGIN
        IF (reflectance_1_s = 'Z') THEN
            reflectance_1_s <= '0' AFTER 5ns;
        END IF;

        IF (reflectance_2_s = 'Z') THEN
            reflectance_2_s <= '0' AFTER 10ns;
        END IF;
    END PROCESS;
    
    ------------------------------------------------------------------------------
    --COMPONENT INSTANTIATION
    ------------------------------------------------------------------------------
    fumo_top : ENTITY work.mojo_top
    	PORT MAP (
            ----mojo standard signals----
    		clk			=> clk_s,
    		rst_n		=> rst_n_s,
    		cclk		=> OPEN,
    		led			=> led_s,
    		spi_sck		=> OPEN,
    		spi_ss		=> OPEN,
    		spi_mosi	=> OPEN,
    		spi_miso	=> OPEN,
    		spi_channel => OPEN,
    		avr_tx		=> OPEN,
    		avr_rx		=> OPEN,
    		avr_rx_busy => OPEN,
            ----additional io----
            io_reflectance_1  => reflectance_1_s,
            io_reflectance_2  => reflectance_2_s,
            o_pd1_left        => pd1_left_s,
            o_pd2_left        => pd2_left_s,
            o_motor_pwm_left  => motor_pwm_left_s,
            o_pd1_right       => pd1_right_s,
            o_pd2_right       => pd2_right_s,
            o_motor_pwm_right => motor_pwm_right_s
        );

end Behavioral;
