module echo(
	input echo_button_bar,
	input reset_bar,
	input clk,
	input RX,
	output RC_bar,
	output TX,
	output TC_bar
    );
	 
wire RC;
wire TC;
assign RC_bar = ~RC;
assign TC_bar = ~TC;

wire echo_button;
wire reset;
assign reset = ~reset_bar;
assign echo_button = ~echo_button_bar;
	 
wire [7:0] data_bus;
wire read_complete;
wire write_enable;

assign write_enable = RC && TC;
assign read_complete = RC && TC;

uart_rx uart_rx (reset,	clk, data_bus, read_complete, RC, RX);

uart_tx uart_tx (reset, clk, data_bus, write_enable,	TC, TX);

endmodule
