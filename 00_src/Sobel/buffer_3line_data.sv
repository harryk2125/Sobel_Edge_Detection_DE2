module buffer_3line_data 
#(
	parameter DATA_WD = 8
)
(
	input logic [DATA_WD-1:0] ram00, ram01, ram02,
	input logic [DATA_WD-1:0] ram10, ram11, ram12,
	input logic [DATA_WD-1:0] ram20, ram21, ram22,
	input logic [1:0] rd_ram,
	input logic first_line,
	input logic last_line,
	output logic [DATA_WD-1:0] out0, out1, out2, out3, out4, out5, out6, out7, out8
);

assign out0 = (last_line ? ram10 : 
					(first_line ? ram00 : 
					(rd_ram[1] ? ram10 :
					(rd_ram[0] ? ram00 : ram20))));

assign out1 = (last_line ? ram11 : 
					(first_line ? ram01 : 
					(rd_ram[1] ? ram11 :
					(rd_ram[0] ? ram01 : ram21))));

assign out2 = (last_line ? ram12 : 
					(first_line ? ram02 : 
					(rd_ram[1] ? ram12 :
					(rd_ram[0] ? ram02 : ram22))));
					
assign out3 = (last_line ? ram20 : 
					(first_line ? ram00 : 
					(rd_ram[1] ? ram20 :
					(rd_ram[0] ? ram10 : ram00))));

assign out4 = (last_line ? ram21 : 
					(first_line ? ram01 : 
					(rd_ram[1] ? ram21 :
					(rd_ram[0] ? ram11 : ram01))));

assign out5 = (last_line ? ram22 : 
					(first_line ? ram02 : 
					(rd_ram[1] ? ram22 :
					(rd_ram[0] ? ram12 : ram02))));
					
assign out6 = (last_line ? ram20 : 
					(first_line ? ram10 : 
					(rd_ram[1] ? ram00 :
					(rd_ram[0] ? ram20 : ram10))));

assign out7 = (last_line ? ram21 : 
					(first_line ? ram11 : 
					(rd_ram[1] ? ram01 :
					(rd_ram[0] ? ram21 : ram11))));

assign out8 = (last_line ? ram22 : 
					(first_line ? ram12 : 
					(rd_ram[1] ? ram02 :
					(rd_ram[0] ? ram22 : ram12))));


endmodule: buffer_3line_data