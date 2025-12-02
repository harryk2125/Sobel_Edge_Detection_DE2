module dl1cycle 
#(
	parameter DATA_WD = 2
)
(
	input logic clk_i,
	input logic rst_ni,
	input logic [DATA_WD-1:0] in,
	output logic [DATA_WD-1:0] out
);

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		out <= 0;
	end
	else begin
		out <= in;
	end
end	

endmodule: dl1cycle