module mask1buffer 
#(
	parameter DATA_WD = 8
)
(
	input logic [DATA_WD-1:0] ram0_data,
	input logic [DATA_WD-1:0] ram1_data,
	input logic [DATA_WD-1:0] ram2_data,
	input logic [1:0] padding,
	input logic [1:0] read_bank,
	output logic [DATA_WD-1:0] out0, out1, out2
);

// Note
// Padding: 00 => No padding; 01 => Padding the first value; 10 => Padding the last value
// Read_bank (Center read address - Current read address at xx bank): 0 => Ram0; 1 => Ram1; 2 => Ram2

logic [3:0] sel;
assign sel = {padding, read_bank};

//	case(sel)
//		// Center read address at bank 0
//		// Out0 <= Ram2
//		// Out1 <= Ram0
//		// Out2 <= Ram1
//		4'b0000: begin
//			out0 = ram2_data;
//			out1 = ram0_data;
//			out2 = ram1_data;
//		end
//		// Center read address at bank 1
//		// Out0 <= Ram0
//		// Out1 <= Ram1
//		// Out2 <= Ram2
//		4'b0001: begin
//			out0 = ram0_data;
//			out1 = ram1_data;
//			out2 = ram2_data;
//		end
//		// Center read address at bank 2
//		// Out0 <= Ram1
//		// Out1 <= Ram2
//		// Out2 <= Ram0
//		4'b0010: begin
//			out0 = ram1_data;
//			out1 = ram2_data;
//			out2 = ram0_data;
//		end
//		// When read address is the first one (Ram0, Col0)
//		// Note: Also disable read for Ram2
//		// Replication padding
//		// Out0 = Out1 <= Ram0
//		// Out2 <= Ram1
//		4'b0100: begin
//			out0 = ram0_data;
//			out1 = ram0_data;
//			out2 = ram1_data;
//		end
//		// When read address is the last one (Ram0, Col213)
//		// Note: Also disable read for Ram1
//		// Replication padding
//		// Out0 <= Ram2
//		// Out1 = Out2 <= Ram0
//		4'b1000: begin
//			out0 = ram2_data;
//			out1 = ram0_data;
//			out2 = ram0_data;
//		end
//	endcase

assign out0 = (sel[3] ? ram2_data : (sel[2] ? ram0_data : (sel[1] ? ram1_data : (sel[0] ? ram0_data : ram2_data))));
assign out1 = (sel[3] ? ram0_data : (sel[2] ? ram0_data : (sel[1] ? ram2_data : (sel[0] ? ram1_data : ram0_data))));
assign out2 = (sel[3] ? ram0_data : (sel[2] ? ram1_data : (sel[1] ? ram0_data : (sel[0] ? ram2_data : ram1_data))));

endmodule: mask1buffer