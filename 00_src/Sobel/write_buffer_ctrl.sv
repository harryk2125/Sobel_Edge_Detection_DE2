module write_buffer_ctrl 
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
	input logic [ADDR_WD-1:0] waddr_i,
	input logic [DATA_WD-1:0] wdata_i,
	input logic w_en_i,
	// Output
	output logic [DATA_WD-1:0] wdata_o,
	output logic [RAM_WD-1:0] ram0_addr,
	output logic [RAM_WD-1:0] ram1_addr,
	output logic [RAM_WD-1:0] ram2_addr,
	//output logic [1:0] ram_bank,
	output logic ram0_en,
	output logic ram1_en,
	output logic ram2_en
);

logic [RAM_WD-1:0] addr_cnt;
logic [1:0] ram_bank;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		ram0_addr <= 8'h0;
		ram1_addr <= 8'h0;
		ram2_addr <= 8'h0;
		ram0_en <= 1'b0;
		ram1_en <= 1'b0;
		ram2_en <= 1'b0;
		addr_cnt <= 8'h0;
		ram_bank <= 2'b0;
		wdata_o <= 8'h0;
	end
	else begin
		if (w_en_i) begin
			wdata_o <= wdata_i;
			if (ram_bank < 2'b10) begin
				ram_bank <= ram_bank + 2'b01;
			end
			else begin
				ram_bank <= 2'b0;
				addr_cnt <= addr_cnt + 8'h1;
			end
			{ram2_en, ram1_en, ram0_en} <= ((3'b001) << ram_bank);
			ram0_addr <= addr_cnt;
			ram1_addr <= addr_cnt;
			ram2_addr <= addr_cnt;
		end
		else begin
			ram0_en <= 1'b0;
			ram1_en <= 1'b0;
			ram2_en <= 1'b0;
		end
		if (waddr_i == 10'h27f) begin
			ram_bank <= 2'b0;
			addr_cnt <= 8'h0;
		end
	end
end

endmodule: write_buffer_ctrl