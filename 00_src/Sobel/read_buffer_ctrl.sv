module read_buffer_ctrl 
#(
	parameter DATA_WD = 8,
	parameter ADDR_WD = 10,
	parameter RAM_WD = 8
)
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	// RAM
	input logic [ADDR_WD-1:0] raddr_i,
	input logic r_en_i,
	// Output
	output logic ram0_en, ram1_en, ram2_en,
	output logic [RAM_WD-1:0] ram0_addr, ram1_addr, ram2_addr,
	output logic [1:0] read_case,
	output logic [1:0] padding
);

logic [RAM_WD-1:0] addr_cnt;
logic [1:0] ram_bank;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		ram0_en <= 1'b0;
		ram1_en <= 1'b0;
		ram2_en <= 1'b0;
		addr_cnt <= 8'h0;
		ram_bank <= 2'b0;
		padding <= 2'b0;
	end
	else begin
		if (r_en_i) begin
			if (ram_bank < 2'b10) begin
				ram_bank <= ram_bank + 2'b01;
			end
			else begin
				ram_bank <= 2'b0;
				addr_cnt <= addr_cnt + 8'h1;
			end
			ram0_en <= 1'b1;
			ram1_en <= 1'b1;
			ram2_en <= 1'b1;
			padding <= (raddr_i == 10'h0) ? 2'b01 : (raddr_i == 10'h27f ? 2'b10 : 2'b00); 
			if (raddr_i == 10'h27f) begin
				ram_bank <= 2'b0;
				addr_cnt <= 8'h0;
			end
			read_case <= ram_bank;
		end
		else begin
			ram0_en <= 1'b0;
			ram1_en <= 1'b0;
			ram2_en <= 1'b0;
		end
	end
end

// Control the read address
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		ram0_addr <= 8'h0;
		ram1_addr <= 8'h0;
		ram2_addr <= 8'h0;
	end
	else begin
		case(ram_bank)
			2'b00: begin
				// Buffer 0
				ram0_addr <= addr_cnt;
				ram1_addr <= addr_cnt;
				ram2_addr <= (raddr_i == 10'h0) ? addr_cnt : addr_cnt - 1'b1;
			end
			2'b01: begin
				ram0_addr <= addr_cnt;
				ram1_addr <= addr_cnt;
				ram2_addr <= addr_cnt;
			end
			2'b10: begin
				ram0_addr <= addr_cnt + 1'b1;
				ram1_addr <= addr_cnt;
				ram2_addr <= addr_cnt;
			end
		endcase
	end
end

endmodule: read_buffer_ctrl