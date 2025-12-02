// Main module of VGA Section
`timescale 1ns/1ns
module vga_interface 
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	input logic sobel_i,
	// FIFO from SDRAM
	input logic sdram_fifo_empty,						// Check the FIFO of the SDRAM (empty status)
	input logic [15:0] data_i,							// Input data (RGB565 or gray8bit)
	output logic vga_clk,
	output logic rd_en,
	// Output for VGA
	output logic [9:0] vga_red,
	output logic [9:0] vga_green,
	output logic [9:0] vga_blue,
	output logic vga_hsync, vga_vsync,
	output logic blank_n, sync_n
);

// State
localparam IDLE = 1'b0;										// Wait the data from FIFO
localparam DISPLAY = 1'b1;

logic state_q, state_d;							// State
logic [9:0] pixel_x, pixel_y;							// Hor/Ver pixel
logic video_en;

logic [23:0] rgb888;

RGB565toRGB888 cvrt
(
	.rgb565_i									(data_i),
	.rgb888_o									(rgb888)
);

// Change state operation
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		state_q <= IDLE;
	end
	else begin
		state_q <= state_d;
	end
end

// FSM
always @* begin
	// Initial
	state_d = state_q;
	rd_en = 0;
	vga_red = 0;
	vga_green = 0;
	vga_blue = 0;
	// FSM
	case(state_q)
		IDLE: begin
			if (pixel_x == 10'd799 && pixel_y == 10'd524 && (!sdram_fifo_empty)) begin
				if (!sobel_i) begin
					vga_red = rgb888[23:16];
					vga_green = rgb888[15:8];
					vga_blue = rgb888[7:0];
				end
				else begin
					vga_red = {data_i[7:0], 2'b00};
					vga_green = {data_i[7:0], 2'b00};
					vga_blue = {data_i[7:0], 2'b00};
				end
				rd_en = 1;
				state_d = DISPLAY;
			end
			else begin
				rd_en = 0;
				state_d = IDLE;
			end
		end
		DISPLAY: begin
			if (pixel_x < 640 && pixel_y < 480) begin
				if (!sobel_i) begin
					vga_red = {rgb888[23:16], 2'b00};
					vga_green = {rgb888[15:8], 2'b00};
					vga_blue = {rgb888[7:0], 2'b00};
				end
				else begin
					vga_red = {data_i[7:0], 2'b00};
					vga_green = {data_i[7:0], 2'b00};
					vga_blue = {data_i[7:0], 2'b00};
				end
				rd_en = 1;
			end
		end
		default: state_d = IDLE;
	endcase	
end



vga_controller vga_ctrl
(
	.clk_i										(clk_i),
	.rst_ni										(rst_ni),
	.h_sync										(vga_hsync),
	.v_sync										(vga_vsync),
	.video_en									(blank_n),
	.pixel_x										(pixel_x),
	.pixel_y										(pixel_y)
);

assign sync_n = 1'b0;
assign vga_clk = clk_i;

endmodule: vga_interface