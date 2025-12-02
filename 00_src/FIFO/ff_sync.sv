module ff_sync 
#(
	parameter WIDTH = 10				// Data width
)
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	input logic [WIDTH:0] d_i,
	// Output
	output logic [WIDTH:0] d_o
);

logic [WIDTH:0] q1;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		q1 <= 0;
		d_o <= 0;
	end
	else begin
		q1 <= d_i;
		d_o <= q1;
	end
end

endmodule: ff_sync