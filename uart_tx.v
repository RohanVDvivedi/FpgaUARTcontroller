
module uart_tx(
	 input reset,				// to reset the UART tx controller
	 input clk,					// 50MHz clock
    input [7:0] data_in,	// set data_in and set write_enable to 1
    input write_enable,		// to transfer the data to tx_buffer, to send it
    output reg TC,			// TC = 1, is used to indicate that the transfer of the last tx_buff is complete and a new byte can be sent
    output reg TX				// connect this pin to the RX of another module
    );
	 
	// to store UART tx state
	reg [1:0] state;
	reg [7:0] tx_buff;	// buffer to store UART data byte, that we would send
	reg [2:0] bit_addr;	// the bit address, that we are currently sending
	reg [63:0] count;		// to count clock pulses, to measure time, for providing precise baud rate
	
	parameter clk_frequency  = 50000000;
	parameter baud_rate      = 9600;
	parameter full_bit_count = (clk_frequency/baud_rate) - 1;
	parameter half_bit_count = ((clk_frequency/baud_rate)/2) - 1;
	
	// the UART TX can be in any one of the followingg state
	parameter IDLE = 2'b00;
	parameter START = 2'b01;
	parameter BIT_WR = 2'b10;
	parameter STOP = 2'b11;
	
	always@(posedge clk) begin
		// if reset
		if(reset) begin
			state <= IDLE;
			TX <= 1;
			TC <= 1;
		end
		else begin
			case(state)
				IDLE :									// IDLE -> START, if write_enable is called
					begin
						if(write_enable) begin
							tx_buff <= data_in;
							TX <= 0;
							TC <= 0;
							count <= 0;
							state <= START;
						end
						else begin
							TX <= 1;
							TC <= 1;
						end
					end
				
				START :									// START -> BIT_WR after sending start bit
					begin
						if(count == full_bit_count) begin
							count <= 0;
							TX <= tx_buff[0];
							bit_addr <= 1;
							state <= BIT_WR;
						end
						else
							count <= count + 1;
					end
				
				BIT_WR :									// BIT_WR -> STOP after completing to send all 8 data bytes
					begin
						if(count == full_bit_count) begin
							count <= 0;
							if(bit_addr == 0) begin
								state <= STOP;
								TX <= 1'b1;
							end
							else begin
								TX <= tx_buff[bit_addr];
								bit_addr <= bit_addr + 1;
							end
						end
						else
							count <= count + 1;
					end
				
				STOP :									// STOP -> IDLE 
					begin
						if(count == full_bit_count) begin
							count <= 0;
							state <= IDLE;
							TC <= 1'b1;
						end
						else
							count <= count + 1;
					end
			endcase
		end
	end

endmodule