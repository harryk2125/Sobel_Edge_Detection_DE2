module pre_sobel
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	input logic sobel_en,
	input logic [7:0] i_0, i_1, i_2, i_3, i_4, i_5, i_6, i_7, i_8,
	// Output
	output logic dl_sobel_en,
	output logic [7:0] o_0, o_1, o_2, o_3, o_5, o_6, o_7, o_8
);

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		o_0 <= 0;
		o_1 <= 0;
		o_2 <= 0;
		o_3 <= 0;
		o_5 <= 0;
		o_6 <= 0;
		o_7 <= 0;
		o_8 <= 0;
		dl_sobel_en <= 0;
	end
	else begin
		o_0 <= i_0;
		o_1 <= i_1;
		o_2 <= i_2;
		o_3 <= i_3;
		o_5 <= i_5;
		o_6 <= i_6;
		o_7 <= i_7;
		o_8 <= i_8;
		dl_sobel_en <= sobel_en;
	end
end

endmodule: pre_sobel