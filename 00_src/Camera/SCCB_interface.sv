// SCCB interface
// Interface with the camera module OV7670
// System clock: 25 MHz ------- SIO_C: 100 KHz
module SCCB_interface 
#(
	parameter CLK_FREQ = 25_000_000,
	parameter SCCB_FREQ = 100_000					// Custom this for fast simulation: Defalut: 100_000
)
(
	// Input
	input logic clk_i,						// Clock 25 MHz
	input logic send_i,						// Trigger I2C transmission
	input logic [7:0] id_i,					// 0x42: camera module slave's address
	input logic [7:0] regi_i,				// Register's address
	input logic [7:0] value_i,				// Value of register
	// Inout - change the SIOD port to output because just need to write, not read
	output logic siod_io,					// OV7670: SIOD - data between ov7670 and fpga
	// Test
	//output logic [3:0] FSM_State,
	// Output
	output logic taken_o,					// Finish sending 1 value, ready for sending another value
	output logic sioc_o						// OV7670: SIOC - data clock
);
// Note: SIOC + SIOD: Negative output (By code and algorithm)

// Design the FSM for this interface: Work as a Phase, check the end byte to change the loaded data
// Idle state
localparam FSM_Idle = 4'h0;					// Idle state
// Start condition state
localparam FSM_Start = 4'h1;					// Start condition
// Load the data (0 -> ID --- 1 -> Register --- 2 -> Value) - Transmit state
localparam FSM_Load_Byte = 4'h2;				// Load the necessary data to transmit
localparam FSM_TX_Byte_State_1 = 4'h3;		// SIOC -> Low
localparam FSM_TX_Byte_State_2 = 4'h4;		// Assign the output data SIOD
localparam FSM_TX_Byte_State_3 = 4'h5;		// SIOC -> High
localparam FSM_TX_Byte_State_4 = 4'h6;		// Check for the end of the byte
// At this stage: SIOC = 1 --- SIOD = 1
// End transmit state
localparam FSM_End_State_1 = 4'h7;			// SIOC -> 0 
localparam FSM_End_State_2 = 4'h8;			// SIOD -> 0
localparam FSM_End_State_3 = 4'h9;			// SIOC -> 1
localparam FSM_End_State_4 = 4'ha;			// SIOD -> 1
// Send the flag to tell that the transmission is completed
localparam FSM_Done = 4'hb;
// Delay to ensure the timing of the SCCB interface
localparam FSM_CntDwn = 4'hc;

// Variables
logic [3:0] FSM_State;						// Current state
logic [3:0] FSM_Des_state;					// Destinated state after delay
// Buffer
logic [7:0] id_bf;							// ID address buffer
logic [7:0] regi_bf;							// Register address buffer
logic [7:0] value_bf;						// Value buffer
// Other
logic [1:0] phase_cnt;						// Phase counter: 0 -> ID; 1 -> REGISTER; 2 -> VALUE
logic [3:0] bit_cnt;							// Tracking the bit position while transmitting each phase
logic [31:0] timer;							// Delay timer for each state 
logic [7:0] transmit_byte;					// Byte for transmitting

initial begin
	sioc_o = 0;
	siod_io = 0;
	taken_o = 1;
end

always @(posedge clk_i) begin
	case(FSM_State)
		// 0: Idle - set all the necessary variables to 0
		FSM_Idle: begin
			// Reset variables
			phase_cnt <= 0;
			bit_cnt <= 0;
			// Load the data into buffer if the I2C flag is trigger (allow sending)
			if (send_i) begin
				FSM_State <= FSM_Start;
				id_bf <= id_i;
				regi_bf <= regi_i;
				value_bf <= value_i;
				taken_o <= 0;								// Busy
			end
			else taken_o <= 1;							// Finsh trasmitting
		end
		// 1: Start condition							// SIOD -> 0
		FSM_Start: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_Load_Byte;
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			sioc_o <= 0;
			siod_io <= 1;
		end
		// 2: Load byte
		FSM_Load_Byte: begin
			// Check the current phase, if finishing sending data => END
			FSM_State <= (phase_cnt == 3) ? FSM_End_State_1 : FSM_TX_Byte_State_1;
			phase_cnt <= phase_cnt + 2'b1;
			bit_cnt <= 0;									// Reset bit counter when load new 8 bits
			case(phase_cnt)
				2'h0: transmit_byte <= id_bf;
				2'h1: transmit_byte <= regi_bf;
				2'h2: transmit_byte <= value_bf;
				default: transmit_byte <= value_bf;
			endcase
		end
		// 3: Transmit - SIOC -> 0; Delay
		FSM_TX_Byte_State_1: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_TX_Byte_State_2;	// -> State 4
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			sioc_o <= 1;
			// Note: Negative output
		end
		// 4: Transmit - Assign output data (SIOD)
		FSM_TX_Byte_State_2: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_TX_Byte_State_3;	// -> State 5
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			siod_io <= (bit_cnt == 4'h8) ? 1'b0 : ~transmit_byte[7];
			// Note: Negative output, and if send all byte, send 1 more don't care bit
		end
		// 5: Transmit - SIOC -> 1; Delay
		FSM_TX_Byte_State_3: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_TX_Byte_State_4;	// -> State 6
			timer <= (CLK_FREQ/(2*SCCB_FREQ));
			sioc_o <= 0;
			// Note: Negative output
		end
		// 6: Transmit - End of byte, increase the bit counter
		FSM_TX_Byte_State_4: begin
			// Not the end of byte => return to State 3 (Keep sending)
			// The end of byte => load the new byte (State 2)
			FSM_State <= (bit_cnt == 8) ? FSM_Load_Byte : FSM_TX_Byte_State_1;
			transmit_byte <= transmit_byte << 1;	// Shift left 1 bit
			// Increase the bit counter - Tracking the bit position of the byte data
			bit_cnt <= bit_cnt + 4'b1;					
		end
		// 7: End of transmission
		// The current status: SIOC = 1; SIOD = 1
		// Start the end transmission by clear the SIOC: SIOC -> 0
		FSM_End_State_1: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_End_State_2;
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			sioc_o <= 1;
			// Note: Negative output
		end
		// 8: End of transmission - While SIOC low (0) => SIOD low (0)
		FSM_End_State_2: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_End_State_3;
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			siod_io <= 1;
			// Note: Negative output
		end
		// 9: End of transmission - Set SIOC high (1)
		FSM_End_State_3: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_End_State_4;
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			sioc_o <= 0;
			// Note: Negative output
		end
		// 10: End of transmission - Set SIOD high (1)
		FSM_End_State_4: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_Done;
			timer <= (CLK_FREQ/(4*SCCB_FREQ));
			siod_io <= 0;
			// Note: Negative output
		end
		// 11: Delay - After that return to IDLE state (state 0)
		FSM_Done: begin
			FSM_State <= FSM_CntDwn;
			FSM_Des_state <= FSM_Idle;
			timer <= ((2*CLK_FREQ)/SCCB_FREQ);		// Delay more after transmission
			phase_cnt <= 0;								// Reset the phase_cnt
		end
		// 12: Delay - Count down the timer and turn to the next stage (FSM_Des_state)
		FSM_CntDwn: begin
			// Timer == 0 => Next stage (FSM_Des_state)
			// Timer != 0 => Continue count down (FSM_CntDwn)
			FSM_State <= (timer == 0) ? FSM_Des_state : FSM_CntDwn;
			// Timer == 0 => Timer <- 0
			// Timer != 0 => Timer <- Timer - 1 (Keep count down)
			timer <= (timer == 0) ? 0 : timer - 1;
		end
		default: begin
			FSM_State <= FSM_Idle;
		end
	endcase
end

endmodule: SCCB_interface