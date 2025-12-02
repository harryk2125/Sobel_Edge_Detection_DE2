// Contains 2 modules: ov7670_registers and SCCB_interface
// Function: Init the OV7670 and communicate with the camera module
module ov7670_controller 
(
	// Input
	input logic clk_25mhz,				// System clock 50 MHz
	input logic rst_ni,					// Negative Reset button: KEY[0]
	// Inout
	inout siod_io,							// SCCB: SIOD - Serial data I/O data
	// Output
		// System
	output logic conf_led_o,			// Led: confirm that REGISTER CONFIGURATION DONE 
		// OV7670
	output logic pwdw_o,					// OV7670: PWDW - power down
	output logic sioc_o,					// OV7670: SIOC - Serial clock
	output logic reset_o,				// OV7670: RESET - Reset
	output logic xclk_o					// OV7670: XCLK - Master clock - 25 MHz
);

// Constant value
localparam camera_address = 8'h42;	// Slave: camera address: 0x42 for write - 0x43 for read 
//(from datasheet - page 44)

// Variables
logic send, taken, sioc_n, siod_n;
logic [7:0] regi, value, mem_addr, mem_regi, mem_value;

// Register value for the OV7670
ov7670_registers regi_syn 
(
	.clk_i				(clk_25mhz),			// System clock
	.addr_i				(mem_addr),				// Register (ov7670_registers)
	.regi_o				(mem_regi),				// Register's address
	.value_o				(mem_value)				// Register's value
);

// OV7670 Configuration
ov7670_config config_syn
(
	.clk_i				(clk_25mhz),			// System clock
	.rst_ni				(rst_ni),				// Negative reset
	.regi_i				(mem_regi),				
	.value_i				(mem_value),
	.transmit_ready_i	(taken),					// Ready to transmit
	.regi_addr_o		(mem_addr),				// Next register (ov7670_registers)
	.regi_o				(regi),
	.value_o				(value),
	.start_transmit_o	(send),					// Flag: Trigger SCCB transmission
	.done_config_o		(conf_led_o)			// Done config => LED
);

// SCCB communicate with the camera module
SCCB_interface sccb_syn 
(
	// Input
	.clk_i				(clk_25mhz),			// System clock
	.send_i				(send),					// Trigger SCCB transmission
	.id_i					(camera_address),		// Slave's ID (0x42)
	.regi_i				(regi),					// Register's address
	.value_i				(value),					// Register's value
	// Inout
	.siod_io				(siod_n),				// OV7670: SIOD - Serial data I/O data
	// Output
	.taken_o				(taken),					// Finish sending 1 value, ready for sending another value
	.sioc_o				(sioc_n)					// OV7670: SIOC - Serial clock
);

assign xclk_o = clk_25mhz;

// Negative output
assign sioc_o = sioc_n ? 1'b0 : 1'bZ;
assign siod_io = siod_n ? 1'b0 : 1'bZ;

// Initial values
initial begin
	reset_o = 1'b1;
	pwdw_o = 1'b0;
end

endmodule: ov7670_controller