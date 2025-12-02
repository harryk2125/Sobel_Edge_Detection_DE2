module sdram_interface 
#(
	parameter IDATA_WD = 16,
	parameter ODATA_WD = 8
)
(
	// System
	input logic sd_clk,
	input logic rst_ni,
	input logic sobel_i,									// 0: Normal - 1 Sobel
	output logic first_frame,							// First frame flag => enable VGA
	// Camera FIFO
	input logic [9:0] data_cnt_cam_fifo,			// Data counter of camera FIFO
	input logic [IDATA_WD-1:0] cam_fifo_i,			// Data of cam FIFO
	output logic rd_cam_fifo,							// Write cam FIFO enable
	// VGA FIFO
	input logic vga_clk,									// Clock of VGA
	input logic rd_vga_fifo,							// Read VGA FIFO enable
	output logic vga_fifo_empty,
	output logic [IDATA_WD-1:0] vga_fifo_o,		// VGA FIFO data out
	// Controller of SDRAM
	output logic sdram_clk,								// SDRAM Clock
	output logic sdram_cke,								// Clock enable
	output logic sdram_cs_n,
	output logic sdram_ras_n,
	output logic sdram_cas_n,
	output logic sdram_we_n,
	output logic [11:0] sdram_addr,
	output logic [1:0] sdram_bank,
	output logic [1:0] sdram_dqm,
	inout [IDATA_WD-1:0] sdram_dq
);

// Variable
logic ready;
logic rw, rw_en;
logic fpga_data_valid, sd_data_valid;
logic [IDATA_WD-1:0] sd_data_i, sd_data_o;
logic rd_sobel_fifo;
logic [10:0] data_cnt_sobel_fifo, data_cnt_vga_fifo;
logic [ODATA_WD-1:0] sobel_o;
// Structure : {row, bank} - SDRAM
logic [13:0] sd_wr_addr;													// SDRAM address
logic wr_vga_fifo;

sdram_dataflow 
#(
	.IDATA_WD												(IDATA_WD),
	.ODATA_WD												(ODATA_WD)
)
sdram_dataflow_synt
(
	// System
	.sdram_clk												(sd_clk),
	.rst_ni													(rst_ni),
	.sobel_i													(sobel_i),
	// FIFO Camera
	.data_cnt_cam_fifo									(data_cnt_cam_fifo),
	.cam_fifo_i												(cam_fifo_i),
	.rd_cam_fifo											(rd_cam_fifo),
	// FIFO VGA
	.data_cnt_vga_fifo									(data_cnt_vga_fifo),
	.wr_vga_fifo											(wr_vga_fifo),
	// FIFO Sobel
	.data_cnt_sobel_fifo									(data_cnt_sobel_fifo),
	.sobel_o													(sobel_o),
	.rd_sobel_fifo											(rd_sobel_fifo),
	// Flags
	.start_of_cam											(),
	.end_of_cam												(),
	.start_of_vga											(),
	.end_of_vga												(),
	.cam_frame_id											(),
	.vga_frame_id											(),
	.first_frame											(first_frame),
	// SDRAM Controller
	.ready													(ready),
	.fpga_data_valid										(fpga_data_valid),
	.sd_data_valid											(sd_data_valid),
	.rw														(rw),
	.rw_en													(rw_en),
	.sd_wr_addr												(sd_wr_addr),
	.sd_data_i												(sd_data_i)
);

// SDRAM Controller
// Address structure: {row, bank} <=> 12 + 2 = 14
sdram_controller
#(
	.DATA_WD													(IDATA_WD),
	.ADDR_WD													(14)
)
sdram_ctrl
(
	// Input
	.sys_clk_i												(sd_clk),
	.rst_ni													(rst_ni),
	.rw_i														(rw),
	.rw_ena_i												(rw_en),
	.addr_i													(sd_wr_addr),
	.data_i													(sd_data_i),
	// Output
	.data_o													(sd_data_o),
	.sd_data_valid											(sd_data_valid),
	.fpga_data_valid										(fpga_data_valid),
	.ready_o													(ready),
	// SDRAM Controller
	.sd_clk													(sdram_clk),
	.sd_cke													(sdram_cke),
	.sd_cs_n													(sdram_cs_n),
	.sd_ras_n												(sdram_ras_n),
	.sd_cas_n												(sdram_cas_n),
	.sd_we_n													(sdram_we_n),
	.sd_addr													(sdram_addr),
	.sd_bank													(sdram_bank),
	.LDQM														(sdram_dqm[0]),
	.HDQM														(sdram_dqm[1]),
	.sd_dq													(sdram_dq)
);

// Sobel operation
// Convert the input data RGB565 to RGB888
// Convert to Grayscale
// Store data in 3 line buffer
// Apply sobel operation 
// Write into FIFO inside sobel
sobel
#(
	.IDATA_WD												(IDATA_WD),
	.ODATA_WD												(ODATA_WD),
	.FIFO_DEPTH												(1024)
)
sb_conv
(
	.clk_i													(sd_clk),
	.rst_ni													(rst_ni),
	.rgb565_i												(cam_fifo_i),
	.rd_cam_fifo											(rd_cam_fifo),
	.sdram_clk												(sd_clk),
	.rd_sobel_fifo											(rd_sobel_fifo),
	.data_cnt_sobel_fifo									(data_cnt_sobel_fifo),
	.sobel_o													(sobel_o)
);

// Pipeline

// FIFO: From SDRAM to VGA
async_fifo
#(
	.DATA_WD													(IDATA_WD),
	.DEPTH													(2048)
)
vga_fifo
(
	// Write section
	.wclk_i													(sd_clk),
	.wrst_ni													(rst_ni),
	.w_en_i													(wr_vga_fifo),
	.data_i													(sd_data_o),
	// Read section
	.rclk_i													(vga_clk),
	.rrst_ni													(rst_ni),
	.r_en_i													(rd_vga_fifo),
	.data_o													(vga_fifo_o),
	// FIFO parameter
	.data_cnt_w												(data_cnt_vga_fifo),
	.data_cnt_r												(),
	.full_o													(),
	.empty_o													(vga_fifo_empty)
);


endmodule: sdram_interface