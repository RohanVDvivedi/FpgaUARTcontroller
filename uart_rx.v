module uart_rx(
	 input reset,					// to reset the UART rx controller
	 input clk,						// 50MHz clock
    output reg [7:0] data_out,// this is last valid byte that was read from RX
	 input read_complete,		// set this pin to 1, in the same cycle as you read the data_out to inform the rx controller that the last byte is read
    output reg RC,				// data_out holds valid data, only when RC = 1
    input RX						// connect this pin to the TX of another module
    );
	 
	// to store UART rx state
	reg [1:0] state;
	reg [7:0] rx_buff;	// buffer to store UART data byte that was read, that you will read
	reg [2:0] bit_addr;	// the bit address, that we are currently receiving
	reg [63:0] count;		// to count clock pulses, to measure time, for providing precise baud rate
	
	parameter clk_frequency  = 50000000;
	parameter baud_rate      = 9600;
	parameter full_bit_count = (clk_frequency/baud_rate) - 1;
	parameter half_bit_count = ((clk_frequency/baud_rate)/2) - 1;
	parameter one_half_bit_count = full_bit_count + half_bit_count + 1;
	
	// the UART RX can be in any one of the following state at any instant
	parameter IDLE = 2'b00;
	parameter START = 2'b01;
	parameter BIT_WR = 2'b10;
	parameter STOP = 2'b11;
	
	always@(posedge clk) begin
		// if reset
		if(reset) begin
			state <= IDLE;
			RC <= 0;
		end
		else begin
			// once read, we reset the RC bit, 
			// so that no one again tries to read the same byte
			if(read_complete)
				RC <= 1'b0;
			
			case(state)
				IDLE :									// IDLE -> START, if RX goes low
					begin
						if(RX == 0) begin
							count <= 0;
							state <= START;
						end
					end
				
				START :									// START -> BIT_WR after receiving start bit
					begin
						if(count == half_bit_count) begin
							count <= 0;
							bit_addr <= 0;
							state <= BIT_WR;
						end
						else
							count <= count + 1;
					end
				
				BIT_WR :									// BIT_WR -> STOP after completing to receive all 8 data bytes
					begin
						if(count == full_bit_count) begin
							count <= 0;
							rx_buff[bit_addr] <= RX;
							if(bit_addr == 7) begin
								state <= STOP;
							end
							else begin
								bit_addr <= bit_addr + 1;
							end
						end
						else
							count <= count + 1;
					end
				
				STOP :									// STOP -> IDLE 
					begin
						if(count == full_bit_count) begin
							if(RX == 1) begin
								RC <= 1'b1;
								state <= IDLE;
								count <= 0;
								data_out <= rx_buff;
							end
						end
						else
							count <= count + 1;
					end
			endcase
		end
	end

endmodule