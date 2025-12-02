module sobel_conv 
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	input logic dl_sobel_en,
	input logic [7:0] i_0, i_1, i_2, i_3, i_5, i_6, i_7, i_8,
	// Test
	//output logic signed [10:0] gx, gy, abs_gx, abs_gy, sum,
	output logic signed [10:0] sum,
	// Output
	output logic [18:0] rd_addr_chroma,
	output logic dl_sb_enable,
	output logic [7:0] sobel_o
);

logic signed [10:0] gx, gy, dl_gx, dl_gy;						// Max bit calculation: (8+8)+9 => 10+10 =>11
logic signed [10:0] abs_gx, abs_gy, dl_abs_gx, dl_abs_gy;
//logic [10:0] sum;

// Pipeline - Delay 1 cycle
assign gx = (i_2-i_0) + ((i_5-i_3)<<1) + (i_8-i_6);
assign gy = (i_0-i_6) + ((i_1-i_7)<<1) + (i_2-i_8);

dl1cycle
#(
	.DATA_WD											(11)
)
del_gx
(
	.clk_i											(clk_i),
	.rst_ni											(rst_ni),
	.in												(gx),
	.out												(dl_gx)
);

dl1cycle
#(
	.DATA_WD											(11)
)
del_gy
(
	.clk_i											(clk_i),
	.rst_ni											(rst_ni),
	.in												(gy),
	.out												(dl_gy)
);

logic dl_sb_en;

dl1cycle
#(
	.DATA_WD											(1)
)
del_sobel_en
(
	.clk_i											(clk_i),
	.rst_ni											(rst_ni),
	.in												(dl_sobel_en),
	.out												(dl_sb_en)
);

// Calculate the abs of Gx, Gy

assign abs_gx = (dl_gx[10]) ? (~dl_gx+1'b1) : dl_gx;
assign abs_gy = (dl_gy[10]) ? (~dl_gy+1'b1) : dl_gy;

// Pipeline - Delay 1 cycle

dl1cycle
#(
	.DATA_WD											(11)
)
del_abs_gx
(
	.clk_i											(clk_i),
	.rst_ni											(rst_ni),
	.in												(abs_gx),
	.out												(dl_abs_gx)
);

dl1cycle
#(
	.DATA_WD											(11)
)
del_abs_gy
(
	.clk_i											(clk_i),
	.rst_ni											(rst_ni),
	.in												(abs_gy),
	.out												(dl_abs_gy)
);

dl1cycle
#(
	.DATA_WD											(1)
)
del_abs_en
(
	.clk_i											(clk_i),
	.rst_ni											(rst_ni),
	.in												(dl_sb_en),
	.out												(dl_sb_enable)
);

// Change to dl_sb_en if happens 1 cycle delay data

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		rd_addr_chroma <= 19'd0;
	end
	else if (dl_sb_enable) begin
		rd_addr_chroma <= (rd_addr_chroma == 19'd307_200) ? 19'd0 : rd_addr_chroma + 19'd1;
	end
end

// |Gx| + |Gy|
assign sum = dl_abs_gx + dl_abs_gy;

// Normalization
// Upper: > 255 => 255
// Lower: < 64 => 0
// Keep
assign sobel_o = (|sum[10:8]) ? (8'hff) : ((|sum[7:6]) ? sum[7:0] : 8'h00);

endmodule: sobel_conv