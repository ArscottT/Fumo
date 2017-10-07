LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE constants IS
    ----general constants----
    CONSTANT second_count_c         : unsigned;
    ----motor control constants----
    CONSTANT stop_c        : std_logic_vector;
    CONSTANT forward_c     : std_logic_vector;
    CONSTANT left_pivot_c  : std_logic_vector;
    CONSTANT right_pivot_c : std_logic_vector;
    CONSTANT pivot_time_c  : integer;

END PACKAGE constants;

PACKAGE BODY constants IS
    ----general constants----
    CONSTANT second_count_c : unsigned(25 DOWNTO 0) := "10111110101111000010000000"; --counter for one second assuming 50Mhz clock
    ----motor control constants----
    CONSTANT stop_c        : std_logic_vector(2 DOWNTO 0) := "000";
    CONSTANT forward_c     : std_logic_vector(2 DOWNTO 0) := "111";
    CONSTANT left_pivot_c  : std_logic_vector(2 DOWNTO 0) := "010";
    CONSTANT right_pivot_c : std_logic_vector(2 DOWNTO 0) := "001";
    CONSTANT pivot_time_c  : integer := 100000000;
END constants;
