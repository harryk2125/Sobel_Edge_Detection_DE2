// 2 port RAM buffer
module ram2port 
#(
	parameter DATA_WD = 8,
	parameter ADDR_WD = 8
)
(
	// Input
	input logic clk_i,
	// To RAM
	input logic [DATA_WD-1:0] data_i,
	input logic [ADDR_WD-1:0] waddr_i,
	input logic [ADDR_WD-1:0] raddr_i,
	input logic w_en_i,
	input logic r_en_i,
	// Output
	output logic [DATA_WD-1:0] data_o
);

localparam ADDR_ID = 220;

logic [DATA_WD-1:0] buffer [0:ADDR_ID-1];

always @(posedge clk_i) begin
	if (w_en_i) begin
		buffer[waddr_i] <= data_i;
	end
end

always @(posedge clk_i) begin
	if (r_en_i) begin
		data_o <= buffer[raddr_i];
	end
end

endmodule: ram2port