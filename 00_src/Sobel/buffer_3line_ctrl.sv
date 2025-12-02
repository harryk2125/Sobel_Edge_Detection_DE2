module buffer_3line_ctrl
#(
	parameter DATA_WD = 8,
	parameter ADDR_WD = 10
)
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	input logic [DATA_WD-1:0] wdata_i,
	input logic w_en_i,
	// Test
//	output logic [9:0] wr_cnt, rd_cnt, 
//	output logic [8:0] wr_row, rd_row,
	output logic start_read, stop_write, wren,
	output logic [9:0] burst_cnt,
//	output logic [1:0] wr_ram, rd_ram,
	// Output
	output logic [DATA_WD-1:0] wdata_o,
	output logic [ADDR_WD-1:0] waddr_o, raddr_o,
	output logic wram0, wram1, wram2,
	output logic first_line, last_line,
	output logic [1:0] rd_ram,
	output logic r_en_o
);

localparam LINE2 = 1920;
localparam LINE1 = 1280;
localparam LINE0 = 640;
localparam VGA_COL = 480;
localparam ST_READ = 1024;

logic [DATA_WD-1:0] data;
logic [9:0] wr_cnt, rd_cnt;
logic [8:0] wr_row, rd_row;
//logic [9:0] burst_cnt;
//logic start_read, stop_write;
logic line0, line1, line2;
logic [1:0] wr_ram;
//logic wren;

// Write address controller
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		wr_cnt <= 0;
		wr_row <= 0;
		waddr_o <= 0;
		wr_ram <= 0;
		wren <= 0;
	end
	else begin
		wren <= w_en_i;
		if (w_en_i) begin
			waddr_o <= wr_cnt;
			if (wr_cnt < LINE0-1'b1) begin
				wr_cnt <= wr_cnt + 1'b1;
			end
			else begin
				wr_cnt <= 0;
				wr_row <= wr_row + 1'b1;
				wr_ram <= wr_ram + 1'b1;
			end
		end
		if (wr_ram == 2'd3) begin
			wr_ram <= 0;
		end
		if (wr_row == VGA_COL) begin
			wr_row <= 0;
		end
	end
end

// Write enable controller
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		line0 <= 1'b0;
		line1 <= 1'b0;
		line2 <= 1'b0;
	end
	else begin
		// Generate the address
		case(wr_ram)
			2'b00: begin
				line0 <= 1'b1;
				line1 <= 1'b0;
				line2 <= 1'b0;
			end
			2'b01: begin
				line0 <= 1'b0;
				line1 <= 1'b1;
				line2 <= 1'b0;
			end
			2'b10: begin
				line0 <= 1'b0;
				line1 <= 1'b0;
				line2 <= 1'b1;
			end
			2'b11: begin
				line0 <= 1'b1;
				line1 <= 1'b0;
				line2 <= 1'b0;
			end
			default: begin
				line0 <= 1'b0;
				line1 <= 1'b0;
				line2 <= 1'b0;
			end
		endcase
	end
end

// Special 
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		start_read <= 1'b0;
		stop_write <= 1'b0;
		burst_cnt <= 0;
	end
	else begin
		if ((wr_cnt == 10'd384) && (wr_row == 9'h1)) begin
			start_read <= 1'b1;
		end
		if ((wr_cnt == LINE0-1'b1) && (wr_row == VGA_COL-1'b1)) begin
			stop_write <= 1'b1;
			burst_cnt <= 0;
		end
		if (stop_write) begin
			if (burst_cnt < ST_READ-1) begin
				burst_cnt <= burst_cnt + 1'b1;
			end
			else begin
				stop_write <= 1'b0;
				start_read <= 1'b0;
				burst_cnt <= 0;
			end
		end
	end
end

// Read address controller
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		rd_cnt <= 0;
		rd_row <= 0;
		rd_ram <= 0;
	end
	else begin
		if (r_en_o) begin
			if (rd_cnt < LINE0-1'b1) begin
				rd_cnt <= rd_cnt + 1'b1;
			end
			else begin
				rd_cnt <= 0;
				rd_row <= rd_row + 1'b1;
				rd_ram <= rd_ram + 1'b1;
			end
		end
		if (rd_row == VGA_COL) begin
			rd_row <= 0;
		end
		if (rd_ram == 2'd3) begin
			rd_ram <= 0;
		end
	end
end

assign wram0 = line0 & wren;
assign wram1 = line1 & wren;
assign wram2 = line2 & wren;
assign wdata_o = wdata_i;
assign r_en_o = (wren & start_read) | stop_write;
assign raddr_o = rd_cnt;
assign first_line = (rd_row == 0) & r_en_o;
assign last_line = (rd_row == VGA_COL-1'b1) & r_en_o;

endmodule: buffer_3line_ctrl