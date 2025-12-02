// Module ov7670_capture
// Capture the frame and save it to the SDRAM
// This capture file use to capture the RGB565 output format
module ov7670_capture 
(
	// Input from OV7670
	input logic pclk_i,							// Pixel clock
	input logic rst_ni,							// Negative reset
	input logic vsync_i,							// Vertical sync
	input logic href_i,							// Horizontal reference
	input logic [7:0] data_i,					// Pixel data
	input logic done_config_i,					// Complete configuration
	// Output to the SDRAM
	output logic [18:0] addr_o,				// Memory address (SDRAM)
	output logic [15:0] data_o,				// Memory data (SDRAM)
	output logic cam_fifo_clk,					// Camera FIFO clock
	output logic wren_o,							// Write enable
	output logic start_of_frame,				// Start of picture frame
	output logic end_of_frame_o				// End of picture frame
);

// Address limit
localparam MAX_ADDR = 19'd307200;

// Variables
logic [15:0] d_latch = 16'h0;
logic [18:0] addr = 19'h0;
logic [1:0] wr_hold = 2'h0;

assign addr_o = (addr == 0) ? 19'h0 : addr - 19'h1;

// Change posedge <=> negedge if needed
always @(negedge pclk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		addr <= 19'h0;
		wr_hold <= 2'h0;
		start_of_frame <= 0;
		end_of_frame_o <= 0;
		d_latch <= 0;
		wren_o <= 0;
	end
	else begin
		if (done_config_i) begin
			if (vsync_i == 1) begin
				addr <= 19'h0;
				wr_hold <= 2'h0;
			end
			
			else begin
				start_of_frame <= ((addr == 19'd0) && (wr_hold[1] == 1)) ? 1'b1 : 1'b0; 
				if (addr < MAX_ADDR) begin
					addr <= addr;
					end_of_frame_o <= 0;
				end
				else begin 
					addr <= MAX_ADDR;
					end_of_frame_o <= 1;
				end	
				wr_hold <= {wr_hold[0], (href_i && (!wr_hold[0]))};
				d_latch <= {data_i, d_latch[15:8]};
				//d_latch <= {d_latch[7:0], data_i};
				wren_o <= 0;
				
				if (wr_hold[1] == 1) begin
					addr <= addr + 19'h1;
					data_o <= {d_latch[15:11], d_latch[10:5], d_latch[4:0]};
					wren_o <= 1;
				end
			end
		end
	end
end

// Generate camera fifo clock (12.5MHz)
always @(posedge pclk_i) begin
	cam_fifo_clk <= ~cam_fifo_clk;
end

endmodule: ov7670_capture