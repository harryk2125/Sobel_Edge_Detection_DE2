module sobel 
#(
	parameter IDATA_WD = 16,
	parameter ODATA_WD = 8,
	parameter FIFO_DEPTH = 1024,
	parameter PTR_WD = $clog2(FIFO_DEPTH)
)
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	// FIFO Camera to Sobel
	input logic [IDATA_WD-1:0] rgb565_i,
	input logic rd_cam_fifo,
	// FIFO Sobel to SDRAM
	input logic sdram_clk,
	input logic rd_sobel_fifo,
	output logic [10:0] data_cnt_sobel_fifo,
	//output logic dl_sb_enable,
	output logic [ODATA_WD-1:0] sobel_o								//sobel_o
);

// Convert the color RGB565 to RGB888 (Extend bits)
logic [23:0] colorp888;

RGB565toRGB888 color888 
(
	.rgb565_i								(rgb565_i),
	.rgb888_o								(colorp888)
);

// Convert to Grayscale (8bit)
logic [ODATA_WD-1:0] gray8;

RGB2Gray grayscale
(
	.red										(colorp888[23:16]),
	.green									(colorp888[15:8]),
	.blue										(colorp888[7:0]),
	.gray										(gray8)
);

logic [ODATA_WD-1:0] out0, out1, out2, out3, out4, out5, out6, out7, out8;
logic sobel_en;

buffer_3line
#(
	.DATA_WD									(ODATA_WD)
)
control_dataflow
(
	.sys_clk_i								(clk_i),
	.rst_ni									(rst_ni),
	.gray_i									(gray8),
	.ff_en									(rd_cam_fifo),
	.dl2_sobel_en							(sobel_en),
	.out0										(out0),
	.out1										(out1),
	.out2										(out2),
	.out3										(out3),
	.out4										(out4),
	.out5										(out5),
	.out6										(out6),
	.out7										(out7),
	.out8										(out8)
);

// Pipeline
logic [ODATA_WD-1:0] dl_out0, dl_out1, dl_out2, dl_out3, dl_out5, dl_out6, dl_out7, dl_out8;
logic dl_sobel_en;
pre_sobel sobel_pp
(
	.clk_i									(clk_i),
	.rst_ni									(rst_ni),
	.sobel_en								(sobel_en),
	.i_0										(out0),
	.i_1										(out1),
	.i_2										(out2),
	.i_3										(out3),
	.i_4										(out4),
	.i_5										(out5),
	.i_6										(out6),
	.i_7										(out7),
	.i_8										(out8),
	.dl_sobel_en							(dl_sobel_en),
	.o_0										(dl_out0),
	.o_1										(dl_out1),
	.o_2										(dl_out2),
	.o_3										(dl_out3),
	.o_5										(dl_out5),
	.o_6										(dl_out6),
	.o_7										(dl_out7),
	.o_8										(dl_out8)
);

logic [ODATA_WD-1:0] sobel;
logic dl_sb_enable;
sobel_conv sobel_convolution
(
	.clk_i									(clk_i),
	.rst_ni									(rst_ni),
	.dl_sobel_en							(dl_sobel_en),
	.i_0										(dl_out0),
	.i_1										(dl_out1),
	.i_2										(dl_out2),
	.i_3										(dl_out3),
	.i_5										(dl_out5),
	.i_6										(dl_out6),
	.i_7										(dl_out7),
	.i_8										(dl_out8),
	.dl_sb_enable							(dl_sb_enable),
	.sobel_o									(sobel)
);

// Sobel FIFO
// 8 x 1024 (1KB)


async_fifo
#(
	.DATA_WD									(ODATA_WD),
	.DEPTH									(2048)
)
sobel_fifo
(
	// Write section
	.wclk_i									(clk_i),
	.wrst_ni									(rst_ni),
	.w_en_i									(dl_sb_enable),
	.data_i									(sobel),
	// Read section
	.rclk_i									(sdram_clk),
	.rrst_ni									(rst_ni),
	.r_en_i									(rd_sobel_fifo),
	.data_o									(sobel_o),
	// FIFO parameter
	.data_cnt_w								(data_cnt_sobel_fifo),
	.data_cnt_r								(),
	.full_o									(),
	.empty_o									()
);

endmodule: sobel