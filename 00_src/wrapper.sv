module wrapper 
(
	// System
	input logic CLOCK_50,
	input logic [1:0] SW,
	output logic [1:0] LEDR,
	// Camera
	inout [25:10] GPIO_1,
//	input logic cam_pclk,									// Camera pixel clock			B20
//	input logic cam_vsync,									// Camera VSYCN					B22
//	input logic cam_href,									// Camera HREF						B23
//	input logic [7:0] cam_data,							// Camera data						B19 - B12
//	inout cam_siod,											// Camera SIOD						B25
//	output logic cam_pwdw,									// Camera power down				B11
//	output logic cam_sioc,									// Camera SIOC						B24
//	output logic cam_reset,									// Camera reset					B10
//	output logic cam_xclk,									// Camera master clock			B21
	// SDRAM
	output logic DRAM_CLK,									// SDRAM clock
	output logic DRAM_CKE,									// SDRAM clock enable
	output logic DRAM_CS_N,									// SDRAM CS_n
	output logic DRAM_RAS_N,								// SDRAM RAS_n
	output logic DRAM_CAS_N,								// SDRAM CAS_n
	output logic DRAM_WE_N,									// SDRAM WE_n
	output logic [11:0] DRAM_ADDR,						// SDRAM address
	output logic DRAM_BA_0,									// SDRAM bank
	output logic DRAM_BA_1,									// SDRAM bank
	output logic DRAM_LDQM,									// SDRAM DQM 0
	output logic DRAM_UDQM,									// SDRAM DQM 1
	inout [15:0] DRAM_DQ,									// SDRAM DQ
	// VGA
	output logic VGA_CLK,									// VGA Clock
	output logic [9:0] VGA_R,								// VGA Red
	output logic [9:0] VGA_G,								// VGA Green
	output logic [9:0] VGA_B,								// VGA Blue
	output logic VGA_HS,										// VGA HSync
	output logic VGA_VS,										// VGA VSync	
	output logic VGA_BLANK,									// VGA Blank_n
	output logic VGA_SYNC									// VGA Sync_n
);

logic [7:0] data_cam;
assign data_cam = {GPIO_1[18], GPIO_1[19], GPIO_1[16], GPIO_1[17], GPIO_1[14], GPIO_1[15], GPIO_1[12], GPIO_1[13]};

//assign data_cam = GPIO_1[19:12];

top top_synt
(
	// System
	.clk_i									(CLOCK_50),
	.rst_ni									(SW[0]),
	.sobel_i									(SW[1]),
	.led_o									(LEDR[0]),
	.locked									(LEDR[1]),
	// Camera
	.cam_pclk								(GPIO_1[20]),
	.cam_vsync								(GPIO_1[22]),
	.cam_href								(GPIO_1[23]),
	.cam_data								(data_cam),
	.cam_siod								(GPIO_1[25]),
	.cam_pwdw								(GPIO_1[11]),
	.cam_sioc								(GPIO_1[24]),
	.cam_reset								(GPIO_1[10]),
	.cam_xclk								(GPIO_1[21]),
	// SDRAM
	.sdram_clk								(DRAM_CLK),
	.sdram_cke								(DRAM_CKE),
	.sdram_cs_n								(DRAM_CS_N),
	.sdram_ras_n							(DRAM_RAS_N),
	.sdram_cas_n							(DRAM_CAS_N),
	.sdram_we_n								(DRAM_WE_N),
	.sdram_addr								(DRAM_ADDR[11:0]),
	.sdram_bank								({DRAM_BA_1, DRAM_BA_0}),
	.sdram_dqm								({DRAM_UDQM, DRAM_LDQM}),
	.sdram_dq								(DRAM_DQ[15:0]),
	// VGA
	.vga_clk									(VGA_CLK),
	.vga_red									(VGA_R),
	.vga_green								(VGA_G),
	.vga_blue								(VGA_B),
	.vga_hsync								(VGA_HS),
	.vga_vsync								(VGA_VS),
	.vga_blank_n							(VGA_BLANK),
	.vga_sync_n								(VGA_SYNC)
);

endmodule: wrapper