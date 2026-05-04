library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SPI_Controller_TB is
end SPI_Controller_TB;

architecture sim of SPI_Controller_TB is

   
    -- Constants

    constant CLK_PERIOD : time := 20 ns;
    constant CLK_DIV_TB : integer := 4;

    constant TC2_TX  : std_logic_vector(7 downto 0) := x"A5";
    constant TC3_RX  : std_logic_vector(7 downto 0) := x"C3";
    constant TC4_TX  : std_logic_vector(7 downto 0) := x"A5";
    constant TC4_RX  : std_logic_vector(7 downto 0) := x"C3";
    constant TC6_TX1 : std_logic_vector(7 downto 0) := x"55";
    constant TC6_RX1 : std_logic_vector(7 downto 0) := x"AA";
    constant TC6_TX2 : std_logic_vector(7 downto 0) := x"F0";
    constant TC6_RX2 : std_logic_vector(7 downto 0) := x"0F";

 
    -- DUT Signals
 
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal start   : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal miso    : std_logic := '0';

    signal rx_data : std_logic_vector(7 downto 0);
    signal busy    : std_logic;
    signal done    : std_logic;
    signal sclk    : std_logic;
    signal cs      : std_logic;
    signal mosi    : std_logic;

    signal miso_drive : std_logic_vector(7 downto 0) := (others => '0');

  
    -- Helper Function
 
    function slv_to_str(slv : std_logic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(slv)));
    end slv_to_str;

begin


    -- DUT
   
    DUT : entity work.SPI_Controller
        generic map(
            CLK_DIV => CLK_DIV_TB
        )
        port map(
            clk     => clk,
            reset   => reset,
            tx_data => tx_data,
            rx_data => rx_data,
            start   => start,
            busy    => busy,
            done    => done,
            sclk    => sclk,
            cs      => cs,
            mosi    => mosi,
            miso    => miso
        );

   
    -- Clock Generator
   
    clk_gen : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- SPI Slave Model (MODE-0)
    -- preload MSB
    -- update next bit on falling edge
 
    slave_model : process
    begin
        miso <= '0';

        loop
            wait until cs = '0';

            miso <= miso_drive(7);

            for i in 6 downto 0 loop
                wait until falling_edge(sclk);
                miso <= miso_drive(i);
            end loop;

            wait until cs = '1';
            miso <= '0';
        end loop;
    end process;

    -- Stimulus
  
    stimulus : process
        variable mosi_captured : std_logic_vector(7 downto 0);

        procedure wait_clk(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end wait_clk;

        procedure do_reset is
        begin
            reset   <= '1';
            start   <= '0';
            tx_data <= (others => '0');

            wait_clk(5);

            wait until rising_edge(clk);
            reset <= '0';

            wait_clk(2);
        end do_reset;

        procedure pulse_start is
        begin
            wait until rising_edge(clk);
            start <= '1';

            wait until rising_edge(clk);
            start <= '0';
        end pulse_start;

    begin

        
        -- TC1 RESET
       
        report "TC1 RESET TEST" severity note;

        reset <= '1';
        wait_clk(5);

        assert cs='1' severity error;
        assert sclk='0' severity error;
        assert busy='0' severity error;
        assert done='0' severity error;

        reset <= '0';
        wait_clk(3);

        report "TC1 PASSED" severity note;


       
        -- TC2 TX
        
        report "TC2 MOSI TEST" severity note;

        mosi_captured := (others=>'0');
        miso_drive <= (others=>'0');
        tx_data <= TC2_TX;

        pulse_start;

        wait_clk(2);

        for i in 7 downto 0 loop
            wait until rising_edge(sclk);
            mosi_captured(i) := mosi;
        end loop;

        assert mosi_captured = TC2_TX
            report "TC2 FAIL got=" & slv_to_str(mosi_captured)
            severity error;

        report "TC2 PASSED" severity note;


        
        -- TC3 RX
       
        report "TC3 RX TEST" severity note;

        do_reset;
        miso_drive <= TC3_RX;
        tx_data <= x"00";

        pulse_start;
        wait until done='1';

        assert rx_data = TC3_RX
            report "TC3 FAIL got=" & slv_to_str(rx_data)
            severity error;

        report "TC3 PASSED" severity note;


        
        -- TC4 FULL DUPLEX
       
        report "TC4 FULL DUPLEX" severity note;

        do_reset;

        mosi_captured := (others=>'0');
        miso_drive <= TC4_RX;
        tx_data <= TC4_TX;

        pulse_start;

        for i in 7 downto 0 loop
            wait until rising_edge(sclk);
            mosi_captured(i) := mosi;
        end loop;

        wait until done='1';

        assert mosi_captured = TC4_TX severity error;
        assert rx_data = TC4_RX severity error;

        report "TC4 PASSED" severity note;


        
        -- TC5 HANDSHAKE
      
        report "TC5 HANDSHAKE" severity note;

        do_reset;
        miso_drive <= x"00";
        tx_data <= x"AA";

        pulse_start;

        wait_clk(2);

        assert busy='1' severity error;
        assert cs='0' severity error;

        wait until done='1';

        assert busy='0' severity error;
        assert cs='1' severity error;

        wait until rising_edge(clk);
        assert done='0' severity error;

        report "TC5 PASSED" severity note;


       
        -- TC6 BACK TO BACK
       
        report "TC6 BACK TO BACK" severity note;

        do_reset;

        miso_drive <= TC6_RX1;
        tx_data <= TC6_TX1;
        pulse_start;

        wait until done='1';
        assert rx_data = TC6_RX1 severity error;

        wait until rising_edge(clk);

        miso_drive <= TC6_RX2;
        tx_data <= TC6_TX2;
        start <= '1';

        wait until rising_edge(clk);
        start <= '0';

        wait until done='1';

        assert rx_data = TC6_RX2 severity error;

        report "TC6 PASSED" severity note;


        -- TC7 START IGNORED WHEN BUSY
       
        report "TC7 BUSY IGNORE" severity note;

        do_reset;

        miso_drive <= TC3_RX;
        tx_data <= TC2_TX;

        pulse_start;

        wait until busy='1';

        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);

        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        wait until done='1';

        assert rx_data = TC3_RX severity error;

        report "TC7 PASSED" severity note;


    
        -- FINISH
       
        report "====================================" severity note;
        report "ALL TESTS PASSED" severity note;
        report "====================================" severity note;

        wait;
    end process;

end sim;
