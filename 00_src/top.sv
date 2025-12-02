module top 
(
	// System
	input logic clk_i,										// Clock50MHz
	input logic rst_ni,										// Negative reset - SW[0]
	input logic sobel_i,										// 0 => Normal | 1 => Sobel - SW[2]
	output logic led_o,										// Led out - Confirm done configuration (SCCB)
	output logic locked,						
	// Camera
	input logic cam_pclk,									// Camera pixel clock
	input logic cam_vsync,									// Camera VSYCN
	input logic cam_href,									// Camera HREF
	input logic [7:0] cam_data,							// Camera data
	inout cam_siod,											// Camera SIOD
	output logic cam_pwdw,									// Camera power down
	output logic cam_sioc,									// Camera SIOC
	output logic cam_reset,									// Camera reset
	output logic cam_xclk,									// Camera master clock
	// SDRAM
	output logic sdram_clk,									// SDRAM clock
	output logic sdram_cke,									// SDRAM clock enable
	output logic sdram_cs_n,								// SDRAM CS_n
	output logic sdram_ras_n,								// SDRAM RAS_n
	output logic sdram_cas_n,								// SDRAM CAS_n
	output logic sdram_we_n,								// SDRAM WE_n
	output logic [11:0] sdram_addr,						// SDRAM address
	output logic [1:0] sdram_bank,						// SDRAM bank
	output logic [1:0] sdram_dqm,							// SDRAM DQM
	inout [15:0] sdram_dq,									// SDRAM DQ
	// Test (output testing from VGA FIFO)
	output logic [15:0] vga_fifo_o,						// VGA Output
	// VGA
	output logic vga_clk,									// VGA Clock
	output logic [9:0] vga_red,							// VGA Red
	output logic [9:0] vga_green,							// VGA Green
	output logic [9:0] vga_blue,							// VGA Blue
	output logic vga_hsync,									// VGA HSync
	output logic vga_vsync,									// VGA VSync	
	output logic vga_blank_n,								// VGA Blank_n
	output logic vga_sync_n									// VGA Sync_n
);

logic sd_clk;
//logic locked;
logic clk_vga;
logic clk_sampl;

// PLL
pll pll_inst
(
	.inclk0														(clk_i),
	.areset														(0),
	.c0															(sd_clk),
	.c1															(clk_vga),
	.c2															(clk_sampl),
	.locked 														(locked)
);

// Clock
logic clk_25, clk_100, clk_150;
assign clk_25 = clk_vga & locked;
assign clk_100 = sd_clk & locked;
assign clk_24 = clk_sampl & locked;

logic rd_cam_fifo;
logic [15:0] cam_data_fifo;
logic [9:0] cam_fifo_data_cnt;

// Clock 25 MHz
camera_interface camera_interface_synt
(
	.sys_clk_i													(clk_25),		// Clock 25MHz
	.rst_ni														(rst_ni),
	.led_o														(led_o),
	.cam_clk														(cam_pclk),		// PIXEL CLOCK: 25MHz (Simulate), cam_pclk
	.cam_vsync													(cam_vsync),
	.cam_href													(cam_href),
	.cam_data_i													(cam_data),
	.siod_io														(cam_siod),
	.pwdw_o														(cam_pwdw),
	.sioc_o														(cam_sioc),
	.reset_o														(cam_reset),
	.xclk_o														(cam_xclk),		// Clock 25MHz
	.sdram_clk													(clk_100),		// Clock 100MHz
	.rd_cam_fifo												(rd_cam_fifo),
	.data_o														(cam_data_fifo),
	.cam_fifo_data_cnt										(cam_fifo_data_cnt)
);

logic sdram_fifo_empty;
logic rd_vga_fifo;
//logic [15:0] vga_fifo_o;
logic first_frame;

// Clock 100-166MHz
sdram_interface sdram_interface_synt
(
	.sd_clk														(clk_100),		// Clock 100MHz
	.rst_ni														(rst_ni),
	.sobel_i														(sobel_i),
	.first_frame												(first_frame),
	.data_cnt_cam_fifo										(cam_fifo_data_cnt),
	.cam_fifo_i													(cam_data_fifo),
	.rd_cam_fifo												(rd_cam_fifo),
	.vga_clk														(clk_25),		// Clock 25MHz
	.rd_vga_fifo												(rd_vga_fifo),
	.vga_fifo_empty											(sdram_fifo_empty),
	.vga_fifo_o													(vga_fifo_o),
	.sdram_clk													(sdram_clk),	// Clock 100MHz - delay 1/2 cycle
	.sdram_cke													(sdram_cke),
	.sdram_cs_n													(sdram_cs_n),
	.sdram_ras_n												(sdram_ras_n),
	.sdram_cas_n												(sdram_cas_n),
	.sdram_we_n													(sdram_we_n),
	.sdram_addr													(sdram_addr),
	.sdram_bank													(sdram_bank),
	.sdram_dqm													(sdram_dqm),
	.sdram_dq													(sdram_dq)
);

// Clock 25MHz
vga_interface vga_interface_synt
(
	.clk_i														(clk_25),				// Clock 25
	.rst_ni														(rst_ni & first_frame),
	.sobel_i														(sobel_i),
	.sdram_fifo_empty											(sdram_fifo_empty),
	.data_i														(vga_fifo_o),
	.vga_clk														(vga_clk),
	.rd_en														(rd_vga_fifo),
	.vga_red														(vga_red),
	.vga_green													(vga_green),
	.vga_blue													(vga_blue),
	.vga_hsync													(vga_hsync),
	.vga_vsync													(vga_vsync),
	.blank_n														(vga_blank_n),
	.sync_n														(vga_sync_n)
);

reg [7:0] dummy_counter;
always @(posedge clk_150) begin
    dummy_counter <= dummy_counter + 1;
end

endmodule: top