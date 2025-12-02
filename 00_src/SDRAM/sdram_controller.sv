// SDRAM controller
// This module will communicate - control the SDRAM signals
// Also give the sdram the commands - addr - data to read/write
module sdram_controller 
#(
	parameter DATA_WD = 16,									// Data length FIFOs (camera - sobel - vga)
	parameter ADDR_WD = 14									// Full-page burst => Don't need columns addr {bank, row}
)
(
	// Input
	input logic sys_clk_i,									// Before optimize: 100MHz. After: 166MHz
	input logic rst_ni,
	input logic rw_i,											// 0 => write | 1 => read
	input logic rw_ena_i,									// Enable W/R
	input logic [ADDR_WD-1:0] addr_i,					// Address to load in SDRAM {row, bank}
	input logic [DATA_WD-1:0] data_i,					// Data in from FIFO
	// Output
	output logic [DATA_WD-1:0] data_o,					// Data out
	output logic sd_data_valid,
	output logic fpga_data_valid,
	output logic ready_o,
	// Test
	output logic [3:0] state_q, state_d, nxt_d, nxt_q,
	output logic [14:0] delay_ctr_q, delay_ctr_d,
	output logic [DATA_WD-1:0] data_iq, data_id,
	output logic [DATA_WD-1:0] data_oq, data_od,
	output logic [ADDR_WD-1:0] addr_q, addr_d,
	// Controller to SDRAM
	output logic sd_clk,
	output logic sd_cke,
	output logic sd_cs_n,
	output logic sd_ras_n,
	output logic sd_cas_n,
	output logic sd_we_n,
	output logic [11:0] sd_addr,
	output logic [1:0] sd_bank,
	output logic LDQM, HDQM,
	inout [DATA_WD-1:0] sd_dq
);


// States:
// Init: NOP -> PRECHARGE -> REFRESH x2 -> LOAD_MODE_REG
// Normal operation
// Begin (Initialize first)
localparam	[3:0]	start = 4'd0;
localparam	[3:0]	precharge_initial = 4'd1;
localparam	[3:0]	refresh_1 = 4'd2;
localparam	[3:0]	refresh_2 = 4'd3;
localparam	[3:0]	load_mode_reg = 4'd4;
// Normal operation
localparam	[3:0]	idle = 4'd5;
localparam	[3:0]	read = 4'd6;
localparam	[3:0]	read_data = 4'd7;
localparam	[3:0]	write = 4'd8;
localparam	[3:0]	write_burst = 4'd9;
localparam	[3:0]	refresh = 4'd10;
localparam	[3:0]	delay = 4'd11;
localparam	[3:0] wait_write = 4'd12;

// Timing state (For 100 MHz clock (10ns)) 
localparam	[2:0] t_RP = 3; // 20ns (Precharge)					=> 21 (3)
localparam	[2:0] t_RC = 7; // 60ns (Active to active)		=> 63	(7)
localparam	[2:0] t_MRD = 2; // 2 cycle (Mode register)
localparam	[2:0] t_RCD = 3; // 20ns (Active to Read/Write)	=> 21	(3)
localparam	[2:0] t_WR = 2; // 2 cycle delay after writing, before manual/auto precharge can start
localparam	[2:0] t_CL = 2;	// 2 (<133MHz), 3 (>133MHz)

// Commands {cs_n, ras_n, cas_n, we_n} (According to the datasheet)
localparam	[3:0] cmd_precharge = 4'b0010; // Precharge
localparam	[3:0] cmd_NOP = 4'b0111; // NOP
localparam	[3:0] cmd_active = 4'b0011; // Active
localparam	[3:0] cmd_write = 4'b0100;	// Write
localparam	[3:0] cmd_read = 4'b0101; // Read
localparam	[3:0] cmd_MRS = 4'b0000; // Mode register set
localparam	[3:0] cmd_refresh = 4'b0001; // Refresh

// Variable (buffers)
// D_FF : d => q
//logic [3:0] state_q, state_d;	// From D_FF state_q,
//logic [3:0] nxt_q, nxt_d; // Next stage of the current stage
logic [3:0] cmd_q, cmd_d; // Command
//logic [14:0] delay_ctr_q, delay_ctr_d; // Delay (Because it needs about 200us for initialization process)
// 200us / 10ns = 20000 (15 bit)
logic [9:0] refresh_ctr_q, refresh_ctr_d; // Refresh (Like delay: 7.8us)
logic refresh_flag_q, refresh_flag_d;
// 7.8us / 10ns = 780 (10 bit)
logic [8:0] burst_index_q, burst_index_d; // Store the data left to be burst (8 columns - 256: full-page burst)

// Input/Output buffers
logic rw_q, rw_d, rw_ena_q, rw_ena_d;
//logic [ADDR_WD-1:0] addr_q, addr_d;
//logic [DATA_WD-1:0] data_iq, data_id;		// Data in
//logic [DATA_WD-1:0] data_oq, data_od;		// Data out
logic sd_data_valid_q, sd_data_valid_d;	// SDRAM to FPGA data valid
logic fpga_data_valid_q, fpga_data_valid_d;	// SDRAM to FPGA data valid
logic [11:0] sd_addr_q, sd_addr_d;			// SDRAM addr
logic [1:0] sd_bank_q, sd_bank_d;			// SDRAM bank
logic [DATA_WD-1:0] sd_dq_q, sd_dq_d;		// SDRAM data port (I/O)
logic tri_q, tri_d;								// SDRAM masking
logic end_q, end_d;

// Generate the delay 180 degree from the system clock
oddr2 delay180
(
	.d0		(1'b0),
	.d1		(1'b1),
	.c0		(sys_clk_i),
	.c1		(~sys_clk_i),
	.ce		(1'b1),
	.r			(1'b0),
	.s			(1'b0),
	.q			(sd_clk)
);

// Operation
always @(posedge sys_clk_i or negedge rst_ni) begin
	if (!rst_ni) begin							// Negative reset => Start => Initialize
		state_q <= start;	
		nxt_q	<= start;
		cmd_q <= cmd_NOP;	
		delay_ctr_q	<= 0;
		refresh_ctr_q <= 0;
		sd_addr_q <= 0;
		tri_q <= 0;
		rw_q <= 0;
		rw_ena_q <= 0;
		
		sd_bank_q <= 0;
		sd_dq_q <= 0;
		addr_q <= 0;
		data_iq <= 0;
		data_oq <= 0;
		sd_data_valid_q <= 0;
		fpga_data_valid_q <= 0;
		refresh_flag_q <= 0;
		burst_index_q <= 0;
		
		end_q <= 0;
	end
	// Normal operation
	else begin		// D_FF
		state_q <= state_d;	
		nxt_q	<= nxt_d;
		cmd_q <= cmd_d;	
		delay_ctr_q	<= delay_ctr_d;
		refresh_ctr_q <= refresh_ctr_d;
		sd_addr_q <= sd_addr_d;
		tri_q <= tri_d;
		rw_q <= rw_d;
		rw_ena_q <= rw_ena_d;
		
		sd_bank_q <= sd_bank_d;
		sd_dq_q <= sd_dq_d;
		addr_q <= addr_d;
		data_iq <= data_id;
		data_oq <= data_od;
		sd_data_valid_q <= sd_data_valid_d;
		fpga_data_valid_q <= fpga_data_valid_d;
		refresh_flag_q <= refresh_flag_d;
		burst_index_q <= burst_index_d;
		
		end_q <= end_d;
	end
end

always @* begin
		state_d = state_q;	
		nxt_d	= nxt_q;
		cmd_d = cmd_NOP;	
		delay_ctr_d	= delay_ctr_q;
		ready_o = 0;
		sd_addr_d = sd_addr_q;
		sd_bank_d = sd_bank_q;
		sd_dq_d = sd_dq_q;
		addr_d = addr_q;
		rw_d = rw_q;
		rw_ena_d = rw_ena_q;
		data_id = data_iq;
		data_od = data_oq;
		tri_d = 0;
		sd_data_valid_d = 1'b0;
		fpga_data_valid_d = 1'b0;
		burst_index_d = burst_index_q;
		
		end_d = 0;
		
		// Refresh every 7.8us
		refresh_flag_d = refresh_flag_q;
		refresh_ctr_d = refresh_ctr_q + 1'b1;
		if (refresh_ctr_q == 780) begin
			refresh_ctr_d = 0;
			refresh_flag_d = 1;
		end
		
		case(state_q)
			// Start initializing
			delay: begin
				delay_ctr_d = delay_ctr_q - 1'b1;
				if (delay_ctr_d == 15'h0) begin
					state_d = nxt_q;
				end
				if (nxt_q == write) begin
					tri_d = 1;
				end
			end
			start: begin
				state_d = delay;
				nxt_d = precharge_initial;
				delay_ctr_d = 15'd20000;						// Wait for 200us: 20000
				sd_addr_d = 0;
				sd_bank_d = 0;
			end
			precharge_initial: begin							// A10 -> HIGH
				state_d = delay;
				nxt_d = refresh_1;
				delay_ctr_d = t_RP-1'b1;
				cmd_d = cmd_precharge;
				sd_addr_d[10] = 1'b1;
			end
			refresh_1: begin
				state_d = delay;
				nxt_d = refresh_2;
				delay_ctr_d = t_RC-1'b1;
				cmd_d = cmd_refresh;
			end
			refresh_2: begin
				state_d = delay;
				nxt_d = load_mode_reg;
				delay_ctr_d = t_RC-1'b1;
				cmd_d = cmd_refresh;
			end
			load_mode_reg: begin
				state_d = delay;
				nxt_d = idle;
				delay_ctr_d = t_MRD-1'b1;
				cmd_d = cmd_MRS;
				sd_addr_d = 12'b 00_0_00_010_0_111;
				// {reserved, writemode: Programmed, operatemode, CL:2, addressingMode: Seq, burstLength: Full-page}
				sd_bank_d = 2'b00;
			end
			// End initializing
			
			// Normal operation
			idle: begin
				ready_o = rw_ena_q ? 1'b0 : 1'b1;
				end_d = 0;
				if (rw_ena_q) begin										// Permission granted for r/w operation
					state_d = delay;
					cmd_d = cmd_active;
					delay_ctr_d = t_RCD-1'b1;
					nxt_d = rw_q ? read : write;
					burst_index_d = 0;
					rw_ena_d = 1'b0;
					{sd_addr_d, sd_bank_d} = addr_q;
				end
				else if (refresh_flag_q || rw_ena_i) begin		// Refresh every 7.8us
					state_d = delay;
					nxt_d = refresh;
					delay_ctr_d = t_RP-1'b1;
					cmd_d = cmd_precharge;
					sd_addr_d[10] = 1'b1;
					refresh_flag_d = 0;
					if (rw_ena_i) begin
						rw_ena_d = rw_ena_i;
						addr_d = addr_i;
						rw_d = rw_i;
					end
				end
			end
			refresh: begin
				state_d = delay;
				nxt_d = idle;
				delay_ctr_d = t_RC-1'b1;
				cmd_d = refresh;
			end
			read: begin
				state_d = delay;
				delay_ctr_d = t_CL;
				cmd_d = cmd_read;
				sd_addr_d = 0;
				sd_bank_d = addr_q[1:0];
				sd_addr_d[10] = 1'b0;
				nxt_d = read_data;
			end
			read_data: begin
				data_od = sd_dq;
				sd_data_valid_d = 1'b1;
				burst_index_d = burst_index_q + 1'b1;
				if (burst_index_d == 9'd256) begin
					sd_data_valid_d = 1'b0;
					state_d = delay;
					nxt_d = idle;
					delay_ctr_d = t_RP-1'b1;
					cmd_d = cmd_precharge;
				end
			end
			write: begin
				data_id = data_i;
				fpga_data_valid_d = 1'b1;
				sd_addr_d = 0;
				sd_bank_d = addr_q[1:0];
				sd_addr_d[10] = 0;
				tri_d = 1'b1;
				cmd_d = cmd_write;
				state_d = write_burst;
				burst_index_d = burst_index_q + 1'b1;
			end
			write_burst: begin
				data_id = data_i;
				fpga_data_valid_d = 1'b1;
				tri_d = 1'b1;
				burst_index_d = burst_index_q + 1'b1;
				if (burst_index_q == 9'd254) begin
					fpga_data_valid_d = 1'b0;
				end
				if (burst_index_q == 9'd255) begin
					fpga_data_valid_d = 1'b0;
				end
				if (burst_index_q == 9'd256) begin
					tri_d = 0;
					state_d = delay;
					fpga_data_valid_d = 1'b0;
					nxt_d = wait_write;
					delay_ctr_d = t_WR-1'b1;
					end_d = 1;
				end
			end
			wait_write: begin
				state_d = delay;
				nxt_d = idle;
				delay_ctr_d = t_RP-1'b1;
				cmd_d = cmd_precharge;
				end_d = 0;
			end
			default: state_d = start;
		endcase
end

logic [1:0] cnt;

always @(posedge sys_clk_i) begin
	if (end_d == 1) begin
		cnt = 0;
	end
	if (cnt <= 2'b10) begin
		LDQM = 1'b1;
		HDQM = 1'b1;
		cnt = cnt + 1'b1;
	end
	else begin
		LDQM = 1'b0;
		HDQM = 1'b0;
	end
end

assign {sd_cs_n, sd_ras_n, sd_cas_n, sd_we_n} = cmd_q;
assign sd_cke = 1'b1;
assign sd_addr = sd_addr_q;
assign sd_bank = sd_bank_q;
assign sd_dq = tri_q ? data_iq : 16'hzzzz;
assign data_o = data_oq;
assign sd_data_valid = sd_data_valid_q;
assign fpga_data_valid = fpga_data_valid_q;

endmodule: sdram_controller