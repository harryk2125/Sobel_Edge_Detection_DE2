`timescale 1ns/1ns
module top_tb ();

// Samples - In-Out sources
localparam IN_PATH = "C:/altera/Proj_Cam_Sobel_VGA/20_sample/desk_setup.hex";
localparam OUT_PATH = "C:/altera/Proj_Cam_Sobel_VGA/21_outsample/desk_setup_color.hex";
integer file, outfile, status;

// IOs ports of main module
// System
logic clk_i;
logic rst_ni;
logic sobel_i;
logic led_o;
logic locked;
// Camera
logic cam_pclk;
logic cam_vsync;
logic cam_href;
logic [7:0] cam_data;
wire cam_siod;
logic cam_pwdw;
logic cam_sioc;
logic cam_reset;
logic cam_xclk;
// SDRAM
logic sdram_clk;
logic sdram_cke;
logic sdram_cs_n;
logic sdram_ras_n;
logic sdram_cas_n;
logic sdram_we_n;
logic [11:0] sdram_addr;
logic [1:0] sdram_bank;
logic [1:0] sdram_dqm;
wire [15:0] sdram_dq;
// VGA
logic vga_clk;
logic [9:0] vga_red;
logic [9:0] vga_green;
logic [9:0] vga_blue;
logic vga_hsync;
logic vga_vsync;
logic vga_blank_n;
logic vga_sync_n;

// Output testing
logic [15:0] vga_fifo_o;

// Clock generator
// System clock
localparam CLK_50 = 20;
localparam HALF_CLK50 = 10;
always #HALF_CLK50 clk_i = ~clk_i;
// Pixel clock
localparam CLK25 = 40;
localparam HALF_CLK25 = CLK_50;
always #HALF_CLK25 cam_pclk = ~cam_pclk;

// Sample generator
// Timing control
localparam t_p = 40;								// T_PCK = CLK_40
localparam t_pxl = 80;							// Double because RGB format
localparam t_line = 62_720;					// 784 * t_xpl
localparam t_rise_vsync = 188_160;
localparam t_vsync_href = 1_066_240;
localparam t_rise_href = 51_200;
localparam t_low_href = 11_520;
localparam t_end = 627_200;

// Generate random input value for camera
always #t_p cam_data = $random & (32'h000000ff);

// Variables
int i, j;

logic [15:0] hex_data;

logic pixel_byte;

logic [8:0] vga_byte;
logic pre_blank;

// DUT
// Main program
top top_dut
(
	// System
	.clk_i									(clk_i),
	.rst_ni									(rst_ni),
	.sobel_i									(sobel_i),
	.led_o									(led_o),
	.locked									(locked),
	// Camera
	.cam_pclk								(cam_pclk),
	.cam_vsync								(cam_vsync),
	.cam_href								(cam_href),
	.cam_data								(cam_data),
	.cam_siod								(cam_siod),
	.cam_pwdw								(cam_pwdw),
	.cam_sioc								(cam_sioc),
	.cam_reset								(cam_reset),
	.cam_xclk								(cam_xclk),
	// SDRAM
	.sdram_clk								(sdram_clk),
	.sdram_cke								(sdram_cke),
	.sdram_cs_n								(sdram_cs_n),
	.sdram_ras_n							(sdram_ras_n),
	.sdram_cas_n							(sdram_cas_n),
	.sdram_we_n								(sdram_we_n),
	.sdram_addr								(sdram_addr),
	.sdram_bank								(sdram_bank),
	.sdram_dqm								(sdram_dqm),
	.sdram_dq								(sdram_dq),
	// Output testing
	.vga_fifo_o								(vga_fifo_o),
	// VGA
	.vga_clk									(vga_clk),
	.vga_red									(vga_red),
	.vga_green								(vga_green),
	.vga_blue								(vga_blue),
	.vga_hsync								(vga_hsync),
	.vga_vsync								(vga_vsync),
	.vga_blank_n							(vga_blank_n),
	.vga_sync_n								(vga_sync_n)
);

// SDRAM Simulation model
// Old SDRAM (Datasheet)
// Rename new SDRAM

A2V64S40CTP sdram_simulation_model
(
	.Dq										(sdram_dq),
	.Addr										(sdram_addr),
	.Ba										(sdram_bank),
	.Clk										(sdram_clk),
	.Cke										(sdram_cke),
	.Cs_n										(sdram_cs_n),
	.Ras_n									(sdram_ras_n),
	.Cas_n									(sdram_cas_n),
	.We_n										(sdram_we_n),
	.Dqm										(sdram_dqm)
);

// Top design under testing
initial begin
	// Setting up the variables
	#0 clk_i = 0;
	cam_pclk = 0;
	rst_ni = 1;
	cam_href = 0;
	cam_vsync = 0;
	sobel_i = 1;
	// Trigger the initialization of camera if PLL is locked
	#200 if (locked) begin
		rst_ni = 0;
		#100 rst_ni = 1;
	end
	// If finishing the initialization of camera => Start read process of the camera
	// Generate href + vsync + Read image sample from hex file
	#27_000_000 if (led_o) begin
		for (i = 0; i < 100; i++) begin
			cam_vsync = 1;
			#t_rise_vsync cam_vsync = 0;
			#t_vsync_href
			for (j = 0; j < 479; j++) begin
				cam_href = 1;
				#t_rise_href cam_href = 0;
				#t_low_href;
			end
			cam_href = 1;
			#t_rise_href cam_href = 0;
			#t_end;
		end
	end
	$finish;
end

//always @(posedge cam_pclk) begin
//	pre_blank <= vga_blank_n;
//	vga_byte <= (pre_blank && (!vga_blank_n)) ? vga_byte + 9'd1 : vga_byte;
//end


// Infinity read the hex image
// RGB565 format image (convert from Python)
// Write 1 frame of image from VGA fifo
// Finish writing => stop the write hex file (output file)
// Compare between 2 pictures (2 hex file must be the same value)
// RGB565 in = RGB565 out at VGA output file
// Check the image in - out
//initial begin
//	file = $fopen(IN_PATH, "r");
//	outfile = $fopen(OUT_PATH, "w");
//	if (file == 0) $error("Hex file not open");
//	if (outfile == 0) $error("Output file not open");
//	#28_000_000;
//	pixel_byte <= 1'b0;
//	vga_byte <= 9'b0;
//	do begin
//		@(posedge cam_pclk);
//			if (cam_href) begin
//				if (pixel_byte == 1'b0) begin
//					status = $fscanf(file, "%h", hex_data);
//					if (status == -1) begin
//						$fseek(file, 0, 0);
//						status = $fscanf(file, "%h", hex_data);
//					end
//					cam_data = hex_data[15:8];
//				end
//				else begin
//					cam_data = hex_data[7:0];
//				end
//				pixel_byte <= pixel_byte + 1'b1;
//			end
//			else begin
//				cam_data = 8'hzz;
//			end
//			if (vga_byte < 9'd480) begin
//				if (vga_blank_n) begin
//					$fdisplay(outfile, "%h", vga_fifo_o);
//				end	 
//			end
//			else begin
//				$fclose(file);
//				$fclose(outfile);
//				$finish;
//			end
//	end while (1);
//end

endmodule: top_tb