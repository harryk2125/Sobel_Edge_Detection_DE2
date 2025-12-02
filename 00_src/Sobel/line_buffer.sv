// Line buffer: 1 in - 3 out
// Data read delay 1 cycle because of delay 0.5 cycle for each control data path
module line_buffer 
#(
	parameter DATA_WD = 8,
	parameter ADDR_WD = 10
)
(
	// Input
	input logic clk_i,
	input logic rst_ni,
		// From Camera FIFO
	input logic [DATA_WD-1:0] data_i,
	input logic [ADDR_WD-1:0] waddr_i,
	input logic [ADDR_WD-1:0] raddr_i,
	input logic w_en_i,
	input logic r_en_i,
	// Test
	output logic [DATA_WD-1:0] ram_i,					// Data in for ram
	output logic [7:0] w_addr0, w_addr1, w_addr2,
	output logic [7:0] r_addr0, r_addr1, r_addr2,
	output logic [DATA_WD-1:0] ram_data0, ram_data1, ram_data2,
	output logic w_en0, w_en1, w_en2,
	output logic r_en0, r_en1, r_en2,
	output logic [1:0] padding, read_case,
	// Output
	output logic [DATA_WD-1:0] data0_o,
	output logic [DATA_WD-1:0] data1_o,
	output logic [DATA_WD-1:0] data2_o
);

// Control signals
//logic [7:0] w_addr0, w_addr1, w_addr2;
//logic [7:0] r_addr0, r_addr1, r_addr2;
//logic [DATA_WD-1:0] ram_i;
//logic [DATA_WD-1:0] ram_data0, ram_data1, ram_data2;
//logic w_en0, w_en1, w_en2;
//logic r_en0, r_en1, r_en2;
//logic [7:0] addr_cnt;
//logic [1:0] padding, read_case;
logic [1:0] dl_pad, dl_rd;

// Write buffer controller
write_buffer_ctrl wr_ctrl
(
	.clk_i						(clk_i),
	.rst_ni						(rst_ni),
	.waddr_i						(waddr_i),
	.wdata_i						(data_i),
	.w_en_i						(w_en_i),
	.wdata_o						(ram_i),
	.ram0_addr					(w_addr0),
	.ram1_addr					(w_addr1),
	.ram2_addr					(w_addr2),
	.ram0_en						(w_en0),
	.ram1_en						(w_en1),
	.ram2_en						(w_en2)
);

// Read buffer controller
read_buffer_ctrl	rd_ctrl
(
	.clk_i						(clk_i),
	.rst_ni						(rst_ni),
	.raddr_i						(raddr_i),
	.r_en_i						(r_en_i),
	.ram0_addr					(r_addr0),
	.ram1_addr					(r_addr1),
	.ram2_addr					(r_addr2),
	.ram0_en						(r_en0),
	.ram1_en						(r_en1),
	.ram2_en						(r_en2),
	.read_case					(read_case),
	.padding						(padding)
);

// Delay 1 cycle for read_case and padding signal
dl1cycle 
#(
	.DATA_WD						(2)
)
dl_read_case 
(
	.clk_i						(clk_i),
	.rst_ni						(rst_ni),
	.in							(read_case),
	.out							(dl_rd)
);

dl1cycle 
#(
	.DATA_WD						(2)
)
dl_padding
(
	.clk_i						(clk_i),
	.rst_ni						(rst_ni),
	.in							(padding),
	.out							(dl_pad)
);

// Mask buffer (Choosing the correct output data)
mask1buffer mk_bf
(
	.ram0_data					(ram_data0),
	.ram1_data					(ram_data1),
	.ram2_data					(ram_data2),
	.padding						(dl_pad),
	.read_bank					(dl_rd),
	.out0							(data0_o),
	.out1							(data1_o),
	.out2							(data2_o)
);

// Line buffer structure
//			0	1	2	3	...	211	212	213(pixel-640)
// RAM0	.	.	.	.	...	...	...	...
// RAM1	.	.	.	.	...	...	...
// RAM2	.	.	.	.	...	...	...
// But each of them has the length of 220 (Extra for overflow or wrong structure)

// Buffer 0
ram2port
#(
	.DATA_WD 					(DATA_WD),
	.ADDR_WD						(8)
)
buffer0
(
	.clk_i						(clk_i),
	.data_i						(ram_i),
	.waddr_i						(w_addr0),
	.raddr_i						(r_addr0),
	.w_en_i						(w_en0),
	.r_en_i						(r_en0),
	.data_o						(ram_data0)
);

// Buffer 1
ram2port 
#(
	.DATA_WD 					(DATA_WD),
	.ADDR_WD						(8)
)
buffer1
(
	.clk_i						(clk_i),
	.data_i						(ram_i),
	.waddr_i						(w_addr1),
	.raddr_i						(r_addr1),
	.w_en_i						(w_en1),
	.r_en_i						(r_en1),
	.data_o						(ram_data1)
);

// Buffer 2
ram2port
#(
	.DATA_WD 					(DATA_WD),
	.ADDR_WD						(8)
)
buffer2
(
	.clk_i						(clk_i),
	.data_i						(ram_i),
	.waddr_i						(w_addr2),
	.raddr_i						(r_addr2),
	.w_en_i						(w_en2),
	.r_en_i						(r_en2),
	.data_o						(ram_data2)
);



endmodule: line_buffer