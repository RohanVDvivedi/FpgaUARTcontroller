module main(
	 input reset_bar,
	 input clk,
	 output TX_bar,
	 output TC_bar,
	 input send_bar,
	 output TX
    );

wire reset;
wire send;

// board has inverting switches
assign reset = ~reset_bar;
assign send = ~send_bar;

// board has inverting leds
assign TC_bar = ~TC;
assign TX_bar = ~TX;

parameter start_address = 12;
parameter size = 13;
parameter last_address = start_address + size - 1;

// outputs from pipeline stage 0
reg write_enable_0;
reg [7:0] address;
reg [1:0] TC_state;
// TC_state 0 : No data to write -> go to state 2 if send is pressed
// TC_state 1 : in the middle of the loop to write complete bytes from start to last address specified
// TC_state 2 : UART tx is expected to be busy with io, do not write anything, since if you do that data will be lost
// TC_stste 3 : byte io from UART_tx was complete, check if we need to write more data and jump to 0 or 1 accordingly

// pipeline stage 0, setup address and write enable signal logic
always@(posedge clk) begin
	if(TC && !write_enable_0) begin
		if(address == last_address && send) begin
			address <= start_address;
			write_enable_0 <= 1;
		end
		else if (address < last_address) begin
			address <= address + 1;
			write_enable_0 <= 1;
		end
	end
	else begin
		address <= address;
		write_enable_0 <= 0;
	end
end

// output registers of pipeline stage 2
reg [7:0] mem [0:29];
initial $readmemh ("mem_init.txt", mem);

// pipeline state 1, write data of mem[] using the address
// to internal register, using the address provided by the previous stage
// note, the rom is still synchronously read
// since it gets data gets clocked in the next cycle inside the uart_tx

wire write_enable;
wire [7:0]data;

assign data = mem[address];
assign write_enable = write_enable_0;

uart_tx uart_tx (
	 reset,
	 clk,
    data,
    write_enable,
    TC,
    TX
    );

endmodule