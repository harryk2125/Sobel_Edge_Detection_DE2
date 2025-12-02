module ov7670_config
#(
	parameter CLK_FREQ = 25_000_000
)
(
	// Input
	input logic clk_i,									// System clock - 25 MHz
	input logic rst_ni,									// Negative reset - Activate transmit trigger
	input logic [7:0] regi_i,							// Register address (Phase 2)
	input logic [7:0] value_i,							// Value data (Phase 3)
	input logic transmit_ready_i,						// Flag: Ready to transmit (Or the interface is free - not busy)
	// Output
	output logic [7:0] regi_addr_o,					// Next address of the register (for ov7670_registers)
	output logic [7:0] regi_o,							// Register address (Phase 2)
	output logic [7:0] value_o,						// Value data (Phase 3)
	output logic start_transmit_o,					// Start the transmission
	output logic done_config_o							// Done config => Led
);

// States:
localparam FSM_Idle = 0;
localparam FSM_Send = 1;
localparam FSM_Done = 2;
localparam FSM_CntDwn = 3;

// Variables
logic [1:0] FSM_State = FSM_Idle;
logic [1:0] FSM_Des_state;
logic [31:0] timer = 0;

initial begin
	// Reset all
	regi_addr_o = 0;
	regi_o = 0;
	value_o = 0;
	start_transmit_o = 0;
	done_config_o = 0;
end

always @(posedge clk_i) begin
	case(FSM_State)
		// 0: Idle - Reset all the state
		FSM_Idle: begin
			FSM_State <= (rst_ni == 0) ? FSM_Send : FSM_Idle;
			regi_addr_o <= 0;
			done_config_o <= (rst_ni == 0) ? 1'b0 : done_config_o;
		end
		// 1: Get the reg-value from ov7670
		FSM_Send: begin
			case({regi_i, value_i})
				16'hFFFF: begin							// End of the register (ov7670_registers)
					FSM_State <= FSM_Done;
				end
				16'hFFF0: begin
					timer <= (CLK_FREQ/100);			// 10ms delay
					FSM_State <= FSM_CntDwn;
					FSM_Des_state <= FSM_Send;
					regi_addr_o <= regi_addr_o + 8'h1;
				end
				default: begin
					if (transmit_ready_i) begin
						FSM_State <= FSM_CntDwn;
						FSM_Des_state <= FSM_Send;
						timer <= 0;
						regi_addr_o <= regi_addr_o + 8'h1;
						regi_o <= regi_i;
						value_o <= value_i;
						start_transmit_o <= 1;
					end
				end
			endcase
		end
		// 2: Done sending all the signals
		FSM_Done: begin
			FSM_State <= FSM_Idle;
			done_config_o <= 1;
		end
		// 3: Delay - Count down to fit the timing
		FSM_CntDwn: begin
			FSM_State <= (timer == 0) ? FSM_Des_state : FSM_CntDwn;
			timer <= (timer == 0) ? 0 : timer - 1;
			start_transmit_o <= 0;
		end
		default: begin
			FSM_State <= FSM_Idle;
		end
	endcase
end

endmodule: ov7670_config