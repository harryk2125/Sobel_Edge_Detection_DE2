module camera_interface 
(
	// System
	input logic sys_clk_i,										// Clock 25MHz
	input logic rst_ni,
	output logic led_o,
	// Camera
		// Capture
	input logic cam_clk,											// Pixel clock
	input logic cam_vsync,										// Vertical sync
	input logic cam_href,										// Horizontal Ref
	input logic [7:0] cam_data_i,								// Data in
		// Controller
	inout siod_io,													// SIOD
	output logic pwdw_o,											// Power down
	output logic sioc_o,											// Data clock out (SCCB)
	output logic reset_o,										// Reset out
	output logic xclk_o,											// Master clock
	// FIFO
	input logic sdram_clk,										// Read clock from SDRAM
	input logic rd_cam_fifo,									// Read camera FIFO 
	output logic [15:0] data_o,								// Output data from FIFO to SDRAM
	output logic [9:0] cam_fifo_data_cnt					// Data read count FIFO to SDRAM
);

// SCCB Interface - Configure the camera parameters
ov7670_controller cam_controller
(
	.clk_25mhz												(sys_clk_i),
	.rst_ni													(rst_ni),
	.siod_io													(siod_io),
	.conf_led_o												(led_o),
	.pwdw_o													(pwdw_o),
	.sioc_o													(sioc_o),
	.reset_o													(reset_o),
	.xclk_o													(xclk_o)
);

logic [15:0] cam_data_o;
logic wr_fifo_cam;
logic cam_fifo_clk;

// Capture the camera frames
ov7670_capture frame_cap
(
	.pclk_i													(cam_clk),
	.rst_ni													(rst_ni),
	.vsync_i													(cam_vsync),
	.href_i													(cam_href),
	.data_i													(cam_data_i),
	.done_config_i											(led_o),
	.addr_o													(),
	.data_o													(cam_data_o),
	.cam_fifo_clk											(cam_fifo_clk),
	.wren_o													(wr_fifo_cam),
	.end_of_frame_o										()
);

// FIFO: From Camera to SDRAM
async_fifo
#(
	.DATA_WD													(16),
	.DEPTH													(1024)
)
camera_fifo
(
	// Write section
	.wclk_i													(cam_clk),
	.wrst_ni													(rst_ni),
	.w_en_i													(wr_fifo_cam),
	.data_i													(cam_data_o),
	// Read section
	.rclk_i													(sdram_clk),
	.rrst_ni													(rst_ni),
	.r_en_i													(rd_cam_fifo),
	.data_o													(data_o),
	// FIFO parameter
	.data_cnt_w												(cam_fifo_data_cnt),
	.data_cnt_r												(),
	.full_o													(),
	.empty_o													()
);

endmodule: camera_interface