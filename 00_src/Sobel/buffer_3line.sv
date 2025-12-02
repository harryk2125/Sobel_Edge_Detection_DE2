// Receive the data from the RGB888 to Grayscale (Input)
// Push all the data when the 
module buffer_3line
#(
	parameter DATA_WD = 8
)
(
	input logic sys_clk_i,
	input logic rst_ni,
	input logic [DATA_WD-1:0] gray_i,
	input logic ff_en,							// FIFO enable read (From SDRAM interface)
	// Test
	output logic [1:0] rd_ram,
	output logic f_line, l_line,
	output logic dl1_f_line, dl1_l_line,
	output logic dl2_f_line, dl2_l_line,
	output logic [1:0] dl1_rd_ram,
	output logic [1:0] dl2_rd_ram,
	output logic sobel_en,
	output logic wren, start_read, stop_write,
	output logic [9:0] burst_cnt,
//	output logic [DATA_WD-1:0] ram00, ram01, ram02, ram10, ram11, ram12, ram20, ram21, ram22,
	output logic dl2_sobel_en,
	output logic [DATA_WD-1:0] out0, out1, out2, out3, out4, out5, out6, out7, out8
);

localparam ADDR_DW = 10;

// Allow read data and send to Sobel_conv
//logic sobel_en;
// Enable data bank of line buffer
logic first_line, second_line, third_line;
//logic f_line, l_line;
//logic dl2_f_line, dl2_l_line;
//logic [1:0] dl2_rd_ram;
//logic [1:0] rd_ram;

logic [DATA_WD-1:0] ram_data;
logic [ADDR_DW-1:0] waddr, raddr;

logic [DATA_WD-1:0] ram00, ram01, ram02;
logic [DATA_WD-1:0] ram10, ram11, ram12;
logic [DATA_WD-1:0] ram20, ram21, ram22;

// Read/Write controller
buffer_3line_ctrl bf_ctrl
(
	.clk_i							(sys_clk_i),
	.rst_ni							(rst_ni),
	.wdata_i							(gray_i),
	.w_en_i							(ff_en),
	.wdata_o							(ram_data),
	.waddr_o							(waddr),
	.raddr_o							(raddr),
	.wren								(wren),
	.start_read						(start_read),
	.stop_write						(stop_write),
	.burst_cnt						(burst_cnt),
	.wram0							(first_line),
	.wram1							(second_line),
	.wram2							(third_line),
	.r_en_o							(sobel_en),
	.rd_ram							(rd_ram),
	.first_line						(f_line),
	.last_line						(l_line)
);

//logic dl1_f_line;

dl1cycle 
#(
	.DATA_WD						(1)
)
dl1_fline 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(f_line),
	.out							(dl1_f_line)
);

dl1cycle 
#(
	.DATA_WD						(1)
)
dl2_fline 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(dl1_f_line),
	.out							(dl2_f_line)
);

//logic dl1_l_line;

dl1cycle 
#(
	.DATA_WD						(1)
)
dl1_lline 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(l_line),
	.out							(dl1_l_line)
);

dl1cycle 
#(
	.DATA_WD						(1)
)
dl2_lline 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(dl1_l_line),
	.out							(dl2_l_line)
);

//logic [1:0] dl1_rd_ram;

dl1cycle 
#(
	.DATA_WD						(2)
)
dl1_rdram 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(rd_ram),
	.out							(dl1_rd_ram)
);

dl1cycle 
#(
	.DATA_WD						(2)
)
dl2_rdram 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(dl1_rd_ram),
	.out							(dl2_rd_ram)
);

logic dl1_sobel_en;

dl1cycle 
#(
	.DATA_WD						(1)
)
dl1_sben 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(sobel_en),
	.out							(dl1_sobel_en)
);

dl1cycle 
#(
	.DATA_WD						(1)
)
dl2_sben 
(
	.clk_i						(sys_clk_i),
	.rst_ni						(rst_ni),
	.in							(dl1_sobel_en),
	.out							(dl2_sobel_en)
);

line_buffer bf0 
(
	.clk_i							(sys_clk_i),
	.rst_ni							(rst_ni),
	.data_i							(ram_data),
	.waddr_i							(waddr),
	.raddr_i							(raddr),
	.w_en_i							(first_line),
	.r_en_i							(sobel_en),
	.data0_o							(ram00),
	.data1_o							(ram01),
	.data2_o							(ram02)
);

line_buffer bf1 
(
	.clk_i							(sys_clk_i),
	.rst_ni							(rst_ni),
	.data_i							(ram_data),
	.waddr_i							(waddr),
	.raddr_i							(raddr),
	.w_en_i							(second_line),
	.r_en_i							(sobel_en),
	.data0_o							(ram10),
	.data1_o							(ram11),
	.data2_o							(ram12)
);

line_buffer bf2 
(
	.clk_i							(sys_clk_i),
	.rst_ni							(rst_ni),
	.data_i							(ram_data),
	.waddr_i							(waddr),
	.raddr_i							(raddr),
	.w_en_i							(third_line),
	.r_en_i							(sobel_en),
	.data0_o							(ram20),
	.data1_o							(ram21),
	.data2_o							(ram22)
);

// Select output data
buffer_3line_data bf_data
(
	.ram00							(ram00),
	.ram01							(ram01),
	.ram02							(ram02),
	.ram10							(ram10),
	.ram11							(ram11),
	.ram12							(ram12),
	.ram20							(ram20),
	.ram21							(ram21),
	.ram22							(ram22),
	.rd_ram							(dl2_rd_ram),
	.first_line						(dl2_f_line),
	.last_line						(dl2_l_line),
	.out0								(out0),
	.out1								(out1),
	.out2								(out2),
	.out3								(out3),
	.out4								(out4),
	.out5								(out5),
	.out6								(out6),
	.out7								(out7),
	.out8								(out8)
);

endmodule: buffer_3line