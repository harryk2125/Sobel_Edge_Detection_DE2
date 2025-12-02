module sdram_dataflow
#(
	parameter IDATA_WD = 16,
	parameter ODATA_WD = 8
)
(
	// System
	input logic sdram_clk,
	input logic rst_ni,
	input logic sobel_i,
	// Cam FIFO
	input logic [IDATA_WD-1:0] cam_fifo_i,
	input logic [9:0] data_cnt_cam_fifo,
	output logic rd_cam_fifo,
	// Sobel FIFO
	input logic [ODATA_WD-1:0] sobel_o,
	input logic [10:0] data_cnt_sobel_fifo,
	output logic rd_sobel_fifo,
	// VGA FIFO
	input logic [10:0] data_cnt_vga_fifo,
	output logic wr_vga_fifo,
	// Flag
	output logic start_of_cam,
	output logic end_of_cam,
	output logic start_of_sobel,
	output logic end_of_sobel,
	output logic start_of_vga,
	output logic end_of_vga,
	output logic cam_frame_id,
	output logic sobel_frame_id,
	output logic vga_frame_id,
	output logic first_frame,
	// SDRAM Controller
	input logic ready,
	input logic fpga_data_valid,
	input logic sd_data_valid,
	output logic rw,
	output logic rw_en,
	output logic [13:0] sd_wr_addr,
	output logic [IDATA_WD-1:0] sd_data_i
);

// FSM States
logic state_q, state_d;
localparam IDLE = 1'b0;
localparam BURST = 1'b1;

// Variable
logic idata_sel_q, idata_sel_d;											// 0: Cam_fifo_i | 1: Sobel_fifo
// Structure : {row, bank} - SDRAM
logic [13:0] color_addr_q, color_addr_d;								// Color addr
logic [13:0] sobel_addr_q, sobel_addr_d;							// Sobel address
logic [13:0] sd_rd_addr_q, sd_rd_addr_d;								// Read address (for VGA)

logic dl_wr;

// Flag for enable reading VGA
// Change the method of system
// Just allow to do the VGA since the first frame is loaded into SDRAM

// SDRAM address allocating:
// 0 -> 1199: Color frame 0 (Foreground 0)
// 1200 -> 2399: Color frame 1 (Foreground 1)
// 2400 -> 3599: Sobel frame 0 (Sobel)
// 3600 -> 4799: Sobel frame 1 (Sobel)
// 4800 -> 5999: Background frame (Chroma Key)

// Interlanced frame scan
// Camera
// 0 -> 1 -> 0 -> 1 -> ...
// Solve the problem of VGA will read the old frame if the new frame is not finishing reading
// VGA
// 0 -> 0 -> 1 -> 1 -> 0 -> 0 -> ...

// State changing operation
always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		state_q <= 0;
		color_addr_q <= 0;
		sobel_addr_q <= 0;
		sd_rd_addr_q <= 0;
		idata_sel_q <= 0;
	end
	else begin
		state_q <= state_d;
		color_addr_q <= color_addr_d;
		sobel_addr_q <= sobel_addr_d;
		sd_rd_addr_q <= sd_rd_addr_d;
		idata_sel_q <= idata_sel_d;
	end
end

// State detail - Controller the addr and read/write signals
// 1 full frame: 256 burst x 1200 times = 640 col * 480 row
// Double frame buffer
// Address allocate
localparam COLOR_END0 = 14'd1200;
localparam COLOR_END1 = 14'd2400;
localparam SOBEL_END0 = 14'd3600;
localparam SOBEL_END1 = 14'd4800;
always @* begin
	// Initial parameter
	state_d = state_q;
	rw = 0;
	rw_en = 0;
	color_addr_d = color_addr_q;
	sobel_addr_d = sobel_addr_q;
	sd_rd_addr_d = sd_rd_addr_q;
	sd_wr_addr = 0;
	idata_sel_d = idata_sel_q;
	// State details
	case(state_q)
		IDLE: begin
			// Wait for enough data in Camera FIFO (256 pixel) to burst write into SDRAM
			// First is writing the color data from FIFO camera to SDRAM
			if (data_cnt_cam_fifo > 256 && ready) begin
				rw = 0;															// Write
				rw_en = 1;														// Enable write/read
				color_addr_d = 1;
				sobel_addr_d = COLOR_END1;
				sd_wr_addr = color_addr_q;									
				state_d = BURST;
				idata_sel_d = 0;
			end
		end
		BURST: begin
			// If SDRAM is ready
			if (ready) begin
				// Check, keep WRITE the color data from Camera FIFO to SDRAM (If can)
				if (data_cnt_cam_fifo > 255) begin
					rw = 0;
					rw_en = 1;
					color_addr_d = (color_addr_q == COLOR_END1-1'b1) ? 14'b0 : color_addr_q + 1'b1;
					sd_wr_addr = color_addr_q;
					idata_sel_d = 0;
				end
				// If not => Check and LOAD the data from SDRAM to VGA if possible
				// Update: Just start loading the data to VGA FIFO when complete 1 frame (first_frame flag)
				else if ((data_cnt_vga_fifo < 250) && first_frame) begin
					rw = 1;
					rw_en = 1;
					sd_rd_addr_d = ((sd_rd_addr_q == COLOR_END0-1'b1) || (sd_rd_addr_q == COLOR_END1-1'b1)) ? ((sobel_i ? sobel_frame_id : cam_frame_id) ? 14'd0 : COLOR_END0) : sd_rd_addr_q + 1'b1;
					// If allow sobel operation => Write the sobel data into SDRAM
					sd_wr_addr = (sobel_i) ? (sd_rd_addr_q + COLOR_END1) : sd_rd_addr_q;
					//sd_wr_addr = sd_rd_addr_q;
				end
				// If not => Check and WRITE the sobel data from Sobel FIFO to SDRAM
				else if (data_cnt_sobel_fifo > 255) begin
					rw = 0;
					rw_en = 1;
					sobel_addr_d = (sobel_addr_q == SOBEL_END1-1'b1) ? COLOR_END1 : sobel_addr_q + 1'b1;
					sd_wr_addr = sobel_addr_q;
					idata_sel_d = 1;
				end
			end
		end
		default: state_d = IDLE;
	endcase
end

assign rd_cam_fifo = (((!rw) && rw_en) || dl_wr || fpga_data_valid) && (!idata_sel_d);
//assign rd_sobel_fifo = fpga_data_valid && idata_sel_d; // OLD

assign rd_sobel_fifo = (((!rw) && rw_en) || dl_wr || fpga_data_valid) && (idata_sel_d);
assign sd_data_i = (!idata_sel_d) ? cam_fifo_i : {8'h00, sobel_o};
assign start_of_cam = (color_addr_q == 14'd0) ? 1'b1 : 1'b0;
assign end_of_cam = (color_addr_q == COLOR_END0-1'b1) ? 1'b1 : 1'b0;
assign start_of_sobel = (sobel_addr_q == 14'd0) ? 1'b1 : 1'b0;
assign end_of_sobel = (sobel_addr_q == SOBEL_END0-1'b1) ? 1'b1 : 1'b0;
assign start_of_vga = (sd_rd_addr_q == 14'd0) ? 1'b1 : 1'b0;
assign end_of_vga = (sd_rd_addr_q == COLOR_END0-1'b1) ? 1'b1 : 1'b0;

// Camera - VGA frame ID: 0 -> Frame 0 		|| 1 -> Frame 1

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		cam_frame_id <= 1'b0;
	end
	else begin
		if (color_addr_q < COLOR_END0 - 1'b1) begin
			cam_frame_id <= 1'b0;
		end
		else begin
			cam_frame_id <= 1'b1;
		end
	end
end

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		sobel_frame_id <= 1'b0;
	end
	else begin
		if (color_addr_q < SOBEL_END0 - 1'b1) begin
			sobel_frame_id <= 1'b0;
		end
		else begin
			sobel_frame_id <= 1'b1;
		end
	end
end

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		vga_frame_id <= 1'b0;
	end
	else begin
		if (sd_rd_addr_q < COLOR_END0 - 1'b1) begin
			vga_frame_id <= 1'b0;
		end
		else begin
			vga_frame_id <= 1'b1;
		end
	end
end

// VGA will work after finishing reading the first frame of VGA

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		first_frame <= 1'b0;
	end
	else begin
		if (end_of_cam) begin
			first_frame <= 1'b1;
		end
		else begin
			first_frame <= first_frame;
		end
	end
end

// Read 1 pixel before transmitting to SDRAM (data sync)

logic [3:0] rw_cnt;

always @(posedge sdram_clk) begin
	if ((!rw) && rw_en) begin
		rw_cnt <= 4'd0;
		dl_wr <= 1'b0;
	end
	else begin
		if (rw_cnt < 4'd11) begin
			rw_cnt <= rw_cnt + 4'd1;
		end
		else if (rw_cnt == 4'd11) begin
			dl_wr <= 1'b1;
			rw_cnt <= rw_cnt + 4'd1;
		end
		else begin
			dl_wr <= 1'b0;
		end
	end
end

// Fix the 1 cycle delay and loss signals in the end
logic pre_vga;

always @(posedge sdram_clk) begin
	pre_vga <= sd_data_valid;
end

assign wr_vga_fifo = sd_data_valid | pre_vga;

// END

endmodule: sdram_dataflow