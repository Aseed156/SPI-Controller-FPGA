library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SPI_Controller is 
generic(
   CLK_DIV : integer :=4
	);
port(

   clk      : in std_logic;
	reset    : in std_logic;
	tx_data  : in std_logic_vector(7 downto 0);  --Data to be given for Transmission
	rx_data  : out std_logic_vector(7 downto 0); --Data Received by the controller
	start    : in std_logic;  --Receive from host system to indicate start of communication
   busy     : out std_logic;  --Remains 1 during communication
	done     : out std_logic;  --Becomes 1 for one clock cycle after Byte communication completion
	
--SPI Pins	
	sclk  : out std_logic;
	cs    : out std_logic;
	mosi  : out std_logic;
	miso  : in std_logic
);
end SPI_Controller;

architecture rtl of SPI_Controller is 

type my_state is (IDLE, LOAD, TRANSFER, COMPLETED);
signal shift_reg : std_logic_vector(7 downto 0);
signal rx_reg    : std_logic_vector(7 downto 0);
signal bit_count : integer range 0 to 8:=0;
signal clk_div_count : integer range 0 to CLK_DIV-1:=0;
signal cs_reg, busy_reg, done_reg : std_logic;
signal sclk_reg  : std_logic:='0';
signal current_state : my_state;
signal next_state    : my_state;


begin


--Output Mapping
  cs<=cs_reg;
  busy<=busy_reg;
  done<=done_reg;
  sclk<=sclk_reg;
  rx_data<=rx_reg;
  mosi<=shift_reg(7);   --Bit Read

--FSM State Register
  state_register : process(clk)
  begin
    if rising_edge(clk) then
	    if reset='1' then
		    current_state<=IDLE;
		 else
	       current_state<=next_state;
		 end if;
	 end if;
  end process;	
 
--FSM Next State Logic
  next_state_logic : process(start,bit_count, current_state) 
  begin
  
   
	  case current_state is
	      when IDLE=> 
			     if start='1' then
			     next_state<=LOAD;
				  else
				  next_state<=IDLE;
				  end if;
				  
			when LOAD=>
			     next_state<=TRANSFER;
				  
         when TRANSFER=>
              if bit_count=8 then
			        next_state<=COMPLETED;
				  else 
			        next_state<=TRANSFER;
				  end if;
			when COMPLETED=>
              next_state<=IDLE;
			when others=>
              next_state<=IDLE;	
		end	case;
		
  end process;
  
  
  
--Datapath
   Data_Path : process(clk)
	begin
	
	if rising_edge(clk) then
		   if reset = '1' then
            shift_reg     <= (others => '0');
            rx_reg        <= (others => '0');
            bit_count     <= 0;
            clk_div_count <= 0;
            sclk_reg      <= '0';
            cs_reg        <= '1';
            busy_reg      <= '0';
            done_reg      <= '0';
			 else	
				case current_state is
					when IDLE =>
							busy_reg<='0';
							done_reg<='0';
							sclk_reg<='0';
							clk_div_count<=0;
							bit_count<=0;
							cs_reg<='1';   --Active Low
		
					when LOAD=>
							busy_reg<='1';
							sclk_reg<='0';
							done_reg<='0';
							cs_reg<='0';
							bit_count<= 0;
                     clk_div_count <= 0;
							shift_reg<=tx_data;

				
					when TRANSFER=>
							busy_reg<='1';
							done_reg<='0';
							cs_reg<='0';
				 
							if clk_div_count< CLK_DIV-1 then
								clk_div_count<=clk_div_count+1;
							else
								clk_div_count<=0;
						 
						 --Toggle sclk
							if sclk_reg='0' then
								sclk_reg<='1';
							else 
								sclk_reg<='0';
							end if; 
						 
				       --Falling Edge Detection		 
							if sclk_reg='1' then
								shift_reg<=shift_reg(6 downto 0) & '0';   --Shift left
								
							end if;
						  
						  
						  --Rising Edge Detection
							if sclk_reg='0' then
								rx_reg<=rx_reg(6 downto 0) & miso;  --Shift left
								if bit_count<8 then
									bit_count<=bit_count+1;
								end if;	  
							end if;
						end if;	
						
				
					when COMPLETED=>
							done_reg<='1';
							busy_reg<='0';
							cs_reg<='1';
							sclk_reg<='0';
			

					when others=>
							busy_reg<='0';
							done_reg<='0';
							sclk_reg<='0';
							clk_div_count<=0;
							bit_count<=0;
							cs_reg<='1';   --Active Low
					end case;
			end if;
		end if;	
		

   end process;

end rtl;	
							  
						    	 
				    
				    
				   
				  
  


  
			
         			
			
              			
		        	
	 













	
	
	
