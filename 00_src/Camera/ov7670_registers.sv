// OV7670 register: contains the address and the value of the register
// to send the ov7670
module ov7670_registers 
(
	// Input
	input logic clk_i,					// System clock - 50 MHz
	input logic [7:0] addr_i,
	// Output
	output logic [7:0] regi_o,			// Register out
	output logic [7:0] value_o
);

// Variables
logic [15:0] svalue;

// Outputs
assign {regi_o, value_o} = svalue;

// All the registers with approriate value
always @(posedge clk_i) begin
	// Some values are set from another example
	// Send value {regi_o, value_o}
	// Noticable register:
	case (addr_i)
//		8'h00: svalue <= 16'h12_80;				// COM7 Reset all the register
//		8'h01: svalue <= 16'hFF_F0;				// Delay : test for another value
//		8'h02: svalue <= 16'h12_80;				// COM7 Reset all the register
//		8'h03: svalue <= 16'h12_04;				// COM7 Choose data output as RGB format
//		8'h04: svalue <= 16'h11_80; 				// CLKRC Prescaler - Fin/(1+1) => default
//		8'h05: svalue <= 16'h0C_00; 				// COM3 Enable scaling
//		8'h06: svalue <= 16'h3E_00; 				// COM14 PCLK scaling off
//		8'h07: svalue <= 16'h8C_00; 				// RGB444 Set RGB format (???)
//		8'h08: svalue <= 16'h04_00; 				// COM1 no CCIR601
//		8'h09: svalue <= 16'h40_10; 				// COM15 Full output, RGB 565
//		8'h0A: svalue <= 16'h3A_04; 				// TSLB Set UV ordering
//		8'h0B: svalue <= 16'h14_38; 				// COM9 AGC Celling
//		8'h0C: svalue <= 16'h4F_40; 				// MTX1 Colour conversion matrix
//		8'h0D: svalue <= 16'h50_34; 				// MTX2 Colour conversion matrix
//		8'h0E: svalue <= 16'h51_0C; 				// MTX3 Colour conversion matrix
//		8'h0F: svalue <= 16'h52_17; 				// MTX4 Colour conversion matrix
//		8'h10: svalue <= 16'h53_29; 				// MTX5 Colour conversion matrix
//		8'h11: svalue <= 16'h54_40; 				// MTX6 Colour conversion matrix
//		8'h12: svalue <= 16'h58_1E; 				// MTXS Matrix sign
//		8'h13: svalue <= 16'h3D_C0; 				// COM13 Gamma & UV Auto adjust
//		8'h14: svalue <= 16'h11_00; 				// CLKRC Prescaler
//		8'h15: svalue <= 16'h17_11; 				// HSTART HREF start
//		8'h16: svalue <= 16'h18_61; 				// HSTOP HREF stop
//		8'h17: svalue <= 16'h32_A4; 				// HREF Edge offset
//		8'h18: svalue <= 16'h19_03; 				// VSTART VSYNC start
//		8'h19: svalue <= 16'h1A_7B; 				// VSTOP VSYNC stop
//		8'h1A: svalue <= 16'h03_0A; 				// VREF VSYNC low
//		8'h1B: svalue <= 16'h0E_61; 				// COM5
//		8'h1C: svalue <= 16'h0F_4B; 				// COM6
//		8'h1D: svalue <= 16'h16_02;
//		8'h1E: svalue <= 16'h1E_37; 				// MVFP Flip & mirror image
//		8'h1F: svalue <= 16'h21_02;
//		8'h20: svalue <= 16'h22_91;
//		8'h21: svalue <= 16'h29_07;
//		8'h22: svalue <= 16'h33_0B;
//		8'h23: svalue <= 16'h35_0B;
//		8'h24: svalue <= 16'h37_1D;
//		8'h25: svalue <= 16'h38_71;
//		8'h26: svalue <= 16'h39_2A;
//		8'h27: svalue <= 16'h3C_78; 				// COM12
//		8'h28: svalue <= 16'h4D_40;
//		8'h29: svalue <= 16'h4E_20;
//		8'h2A: svalue <= 16'h69_00; 				// GFIX
//		8'h2B: svalue <= 16'h6B_0A;
//		8'h2C: svalue <= 16'h74_10;
//		8'h2D: svalue <= 16'h8D_4F;
//		8'h2E: svalue <= 16'h8E_00;
//		8'h2F: svalue <= 16'h8F_00;
//		8'h30: svalue <= 16'h90_00;
//		8'h31: svalue <= 16'h91_00;
//		8'h32: svalue <= 16'h96_00;
//		8'h33: svalue <= 16'h9A_00;
//		8'h34: svalue <= 16'hB0_84;
//		8'h35: svalue <= 16'hB1_0C;
//		8'h36: svalue <= 16'hB2_0E;
//		8'h37: svalue <= 16'hB3_82;
//		8'h38: svalue <= 16'hB8_0A;
//		8'd0: svalue <= 16'h12_80;				// COM7 Reset all the register
//		8'd1: svalue <= 16'hFF_F0;				// Delay : test for another value
//		8'd2: svalue <= 16'h12_04;				// COM7 Choose data output as RGB format
//		8'd3: svalue <= 16'h15_20;  			//	Pclk will not toggle during horizontal blank
//		8'd4: svalue <= 16'h40_d0;				//RGB565
//		8'd5: svalue <= 16'h12_04; 			// COM7,     set RGB color output
//		8'd6: svalue <= 16'h11_80; 			// CLKRC     internal PLL matches input clock
//		8'd7: svalue <= 16'h0C_00; 			// COM3,     default settings
//		8'd8: svalue <= 16'h3E_00; 			// COM14,    no scaling, normal pclock
//		8'd9: svalue <= 16'h04_00; 			// COM1,     disable CCIR656
//		8'd10: svalue <= 16'h40_d0; 			//COM15,     RGB565, full output range
//		8'd11: svalue <= 16'h3a_04; 			//TSLB       set correct output data sequence (magic)
//		8'd12: svalue <= 16'h14_18; 			//COM9       MAX AGC value x4 0001_1000
//		8'd13: svalue <= 16'h4F_B3; 			//MTX1       all of these are magical matrix coefficients
//		8'd14: svalue <= 16'h50_B3; 			//MTX2
//		8'd15: svalue <= 16'h51_00; 			//MTX3
//		8'd16: svalue <= 16'h52_3d; 			//MTX4
//		8'd17: svalue <= 16'h53_A7; 			//MTX5
//		8'd18: svalue <= 16'h54_E4; 			//MTX6
//		8'd19: svalue <= 16'h58_9E; 			//MTXS
//		8'd20: svalue <= 16'h3D_C0; 			//COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
//		8'd21: svalue <= 16'h17_14; 			//HSTART     start high 8 bits
//		8'd22: svalue <= 16'h18_02;	 		//HSTOP      stop high 8 bits //these kill the odd colored line
//		8'd23: svalue <= 16'h32_80; 			//HREF       edge offset
//		8'd24: svalue <= 16'h19_03; 			//VSTART     start high 8 bits
//		8'd25: svalue <= 16'h1A_7B; 			//VSTOP      stop high 8 bits
//		8'd26: svalue <= 16'h03_0A; 			//VREF       vsync edge offset
//		8'd27: svalue <= 16'h0F_41; 			//COM6       reset timings
//		8'd28: svalue <= 16'h1E_00; 			//MVFP       disable mirror / flip //might have magic value of 03
//		8'd29: svalue <= 16'h33_0B; 			//CHLF       //magic value from the internet
//		8'd30: svalue <= 16'h3C_78; 			//COM12      no HREF when VSYNC low
//		8'd31: svalue <= 16'h69_00; 			//GFIX       fix gain control
//		8'd32: svalue <= 16'h74_00; 			//REG74      Digital gain control
//		8'd33: svalue <= 16'hB0_84; 			//RSVD       magic value from the internet *required* for good color
//		8'd34: svalue <= 16'hB1_0C; 			//ABLC1
//		8'd35: svalue <= 16'hB2_0E; 			//RSVD       more magic internet values
//		8'd36: svalue <= 16'hB3_80; 			//THL_ST
//		8'd37: svalue <= 16'h70_3a;
//		8'd38: svalue <= 16'h71_35;
//		8'd39: svalue <= 16'h72_11;
//		8'd40: svalue <= 16'h73_f0;
//		8'd41: svalue <= 16'ha2_02;
//		8'd42: svalue <= 16'h7a_20;
//		8'd43: svalue <= 16'h7b_10;
//		8'd44: svalue <= 16'h7c_1e;
//		8'd45: svalue <= 16'h7d_35;
//		8'd46: svalue <= 16'h7e_5a;
//		8'd47: svalue <= 16'h7f_69;
//		8'd48: svalue <= 16'h80_76;
//		8'd49: svalue <= 16'h81_80;
//		8'd50: svalue <= 16'h82_88;
//		8'd51: svalue <= 16'h83_8f;
//		8'd52: svalue <= 16'h84_96;
//		8'd53: svalue <= 16'h85_a3;
//		8'd54: svalue <= 16'h86_af;
//		8'd55: svalue <= 16'h87_c4;
//		8'd56: svalue <= 16'h88_d7;
//		8'd57: svalue <= 16'h89_e8;
//		8'd58: svalue <= 16'h13_e0; 			//COM8, disable AGC / AEC
//		8'd59: svalue <= 16'h00_00; 			//set gain reg to 0 for AGC
//		8'd60: svalue <= 16'h10_00; 			//set ARCJ reg to 0
//		8'd61: svalue <= 16'h0d_40; 			//magic reserved bit for COM4
//		8'd62: svalue <= 16'h14_18; 			//COM9, 4x gain + magic bit
//		8'd63: svalue <= 16'ha5_05; 			// BD50MAX
//		8'd64: svalue <= 16'hab_07; 			//DB60MAX
//		8'd65: svalue <= 16'h24_95; 			//AGC upper limit
//		8'd66: svalue <= 16'h25_33; 			//AGC lower limit
//		8'd67: svalue <= 16'h26_e3; 			//AGC/AEC fast mode op region
//		8'd68: svalue <= 16'h9f_78; 			//HAECC1
//		8'd69: svalue <= 16'ha0_68; 			//HAECC2
//		8'd70: svalue <= 16'ha1_03; 			//magic
//		8'd71: svalue <= 16'ha6_d8; 			//HAECC3
//		8'd72: svalue <= 16'ha7_d8; 			//HAECC4
//		8'd73: svalue <= 16'ha8_f0; 			//HAECC5
//		8'd74: svalue <= 16'ha9_90; 			//HAECC6
//		8'd75: svalue <= 16'haa_94; 			//HAECC7
//		8'd76: svalue <= 16'h13_e5; 			//COM8, enable AGC / AEC
//		8'd77: svalue <= 16'h1E_23; 			//Mirror Image
//		8'd78: svalue <= 16'h69_06; 			//gain of RGB(manually adjusted)
//		TEST VALUE NEXT TIME
//		8'h00: svalue <= 16'h12_80;		// Reset all registers to default
//		8'h01: svalue <= 16'hff_f0;		// Wait camera stable
//		8'h02: svalue <= 16'h12_80;		// Reset again
//		8'h03: svalue <= 16'h12_04;		// Set output format -> RGB 
//		8'h04: svalue <= 16'h15_20;		// Pclk won't toggle while horizontal blank
//		8'h05: svalue <= 16'h40_d0;		// RGB565
//		8'h06: svalue <= 16'h12_04;		// COM7,		Set output format -> RGB
//		8'h07: svalue <= 16'h11_80;		// CLKRC,	Internal PLL matches input clock
//		8'h08: svalue <= 16'h0c_00;		// COM3,		default
//		8'h09: svalue <= 16'h3e_00;		// COM14,	no scaling, normal pclock
//		8'h0a: svalue <= 16'h04_00;		// COM1,		disable CCIR656
//		8'h0b: svalue <= 16'h40_d0;		// RGB565,	full output range
//		8'h0c: svalue <= 16'h3a_04;		// TSLB,		set correct output data sequence
//		8'h0d: svalue <= 16'h14_18;		// COM9,		Max AGC value x4 0001_1000
//		8'h0f: svalue <= 16'h4f_b3;		// MTX1,		matrix coefficients
//		8'h10: svalue <= 16'h50_b3;		// MTX2,		matrix coefficients
//		8'h11: svalue <= 16'h51_00;		// MTX3,		matrix coefficients
//		8'h12: svalue <= 16'h52_3d;		// MTX4,		matrix coefficients
//		8'h13: svalue <= 16'h53_a7;		// MTX5,		matrix coefficients
//		8'h14: svalue <= 16'h54_e4;		// MTX6,		matrix coefficients
//		8'h15: svalue <= 16'h58_9e;		// MTXS,		matrix coefficients
//		8'h16: svalue <= 16'h3d_c0;		// COM13,	set gamma enable
//		8'h17: svalue <= 16'h17_14;		// HSTART,	start high 8 bits
//		8'h18: svalue <= 16'h18_02;		// HSTOP,	stop high 8 bits
//		8'h19: svalue <= 16'h32_08;		// HREF,		edge offset
//		8'h1a: svalue <= 16'h19_03;		// VSTART,	start high 8 bits
//		8'h1b: svalue <= 16'h1a_7b;		// VSTOP,	stop high 8 bits
//		8'h1c: svalue <= 16'h03_0a;		// VREF,		vsync edge offset
//		8'h1d: svalue <= 16'h0f_41;		// COM6,		reset timings
//		8'h1e: svalue <= 16'h1e_00;		// MVFP,		disable mirror / flip		// might be 03
//		8'h1f: svalue <= 16'h33_0b;		// CHLF,		xxx
//		8'h20: svalue <= 16'h3c_78;		// COM12,	no HREF when VSYNC Low
//		8'h21: svalue <= 16'h69_00;		// GFIX,		fix gain control
//		8'h22: svalue <= 16'h74_00; 		// REG74   	Digital gain control
//		8'h23: svalue <= 16'hB0_84; 		// RSVD		magic value from the internet *required* for good color
//		8'h24: svalue <= 16'hB1_0c; 		// ABLC1
//		8'h25: svalue <= 16'hB2_0e; 		// RSVD     more magic internet values
//		8'h26: svalue <= 16'hB3_80; 		// THL_ST
//		//begin mystery scaling numbers
//		8'h27: svalue <= 16'h70_3a;
//		8'h28: svalue <= 16'h71_35;
//		8'h29: svalue <= 16'h72_11;
//		8'h2a: svalue <= 16'h73_f0;
//		8'h2b: svalue <= 16'ha2_02;
//		//gamma curve values
//		8'h2c: svalue <= 16'h7a_20;
//		8'h2d: svalue <= 16'h7b_10;
//		8'h2e: svalue <= 16'h7c_1e;
//		8'h2f: svalue <= 16'h7d_35;
//		8'h30: svalue <= 16'h7e_5a;
//		8'h31: svalue <= 16'h7f_69;
//		8'h32: svalue <= 16'h80_76;
//		8'h33: svalue <= 16'h81_80;
//		8'h34: svalue <= 16'h82_88;
//		8'h35: svalue <= 16'h83_8f;
//		8'h36: svalue <= 16'h84_96;
//		8'h37: svalue <= 16'h85_a3;
//		8'h38: svalue <= 16'h86_af;
//		8'h39: svalue <= 16'h87_c4;
//		8'h3a: svalue <= 16'h88_d7;
//		8'h3b: svalue <= 16'h89_e8;
//		//AGC and AEC
//		8'h3c: svalue <= 16'h13_e0;		//COM8, disable AGC / AEC
//		8'h3d: svalue <= 16'h00_00;		//set gain reg to 0 for AGC
//		8'h3e: svalue <= 16'h10_00;		//set ARCJ reg to 0
//		8'h3f: svalue <= 16'h0d_40;		//magic reserved bit for COM4
//		8'h40: svalue <= 16'h14_18;		//COM9, 4x gain + magic bit
//		8'h41: svalue <= 16'ha5_05;		// BD50MAX
//		8'h42: svalue <= 16'hab_07;		//DB60MAX
//		8'h43: svalue <= 16'h24_95;		//AGC upper limit
//		8'h44: svalue <= 16'h25_33;		//AGC lower limit
//		8'h45: svalue <= 16'h26_e3;		//AGC/AEC fast mode op region
//		8'h46: svalue <= 16'h9f_78;		//HAECC1
//		8'h47: svalue <= 16'ha0_68;		//HAECC2
//		8'h48: svalue <= 16'ha1_03;		//magic
//		8'h49: svalue <= 16'ha6_d8;		//HAECC3
//		8'h4a: svalue <= 16'ha7_d8;		//HAECC4
//		8'h4b: svalue <= 16'ha8_f0;		//HAECC5
//		8'h4c: svalue <= 16'ha9_90;		//HAECC6
//		8'h4d: svalue <= 16'haa_94;		//HAECC7
//		8'h4e: svalue <= 16'h13_e5;		//COM8, enable AGC / AEC
//		8'h4f: svalue <= 16'h1E_23;		//Mirror Image
//		8'h50: svalue <= 16'h69_06;		//gain of RGB(manually adjusted)

//8'd0:  svalue <= 16'h12_80;   // Reset all registers
//8'd1:  svalue <= 16'hFF_F0;   // Delay ~100ms
//
//// Output format RGB565
//8'd2:  svalue <= 16'h12_04;   // COM7: RGB
//8'd3:  svalue <= 16'h15_20;   // PCLK không toggle khi blank
//8'd4:  svalue <= 16'h40_d0;   // COM15: RGB565 full range
//8'd5:  svalue <= 16'h8c_00;   // Disable RGB444
//8'd6:  svalue <= 16'h3a_04;   // TSLB: correct byte order
//
//// Clock setup
//8'd7:  svalue <= 16'h11_01;   // CLKRC: Div 2 (giảm noise)
//8'd8:  svalue <= 16'h0C_00;   // COM3: default
//8'd9:  svalue <= 16'h3E_00;   // COM14: no scaling
//8'd10: svalue <= 16'h04_00;   // COM1: disable CCIR656

// doi luc chay duoc

//8'd0:  svalue <= 16'h12_80;   // Reset all registers
//8'd1:  svalue <= 16'hFF_F0;   // Delay ~100ms
//
//// Output format RGB565
//8'd2:  svalue <= 16'h12_04;   // COM7: RGB
//8'd3:  svalue <= 16'h15_20;   // PCLK không toggle khi blank
//8'd4:  svalue <= 16'h40_d0;   // COM15: RGB565 full range
//8'd5:  svalue <= 16'h8c_00;   // Disable RGB444
//8'd6:  svalue <= 16'h3a_04;   // TSLB: correct byte order
//
//// Clock setup
//8'd7:  svalue <= 16'h11_00;   // CLKRC: Không chia (PCLK gốc)
//8'd8:  svalue <= 16'h0C_00;   // COM3: default
//8'd9:  svalue <= 16'h3E_00;   // COM14: no scaling
//8'd10: svalue <= 16'h04_00;   // COM1: disable CCIR656
//
//
//// Window setup 640x480
//8'd11: svalue <= 16'h17_13;   // HSTART
//8'd12: svalue <= 16'h18_01;   // HSTOP
//8'd13: svalue <= 16'h19_02;   // VSTART
//8'd14: svalue <= 16'h1A_7A;   // VSTOP
//8'd15: svalue <= 16'h32_B6;   // HREF
//
//// Color matrix (chuẩn datasheet)
//8'd16: svalue <= 16'h4F_80;
//8'd17: svalue <= 16'h50_80;
//8'd18: svalue <= 16'h51_00;
//8'd19: svalue <= 16'h52_22;
//8'd20: svalue <= 16'h53_5e;
//8'd21: svalue <= 16'h54_80;
//8'd22: svalue <= 16'h58_9e;
//
//// Gamma correction (chuẩn)
//8'd23: svalue <= 16'h7a_20;
//8'd24: svalue <= 16'h7b_1c;
//8'd25: svalue <= 16'h7c_28;
//8'd26: svalue <= 16'h7d_3c;
//8'd27: svalue <= 16'h7e_55;
//8'd28: svalue <= 16'h7f_68;
//8'd29: svalue <= 16'h80_76;
//8'd30: svalue <= 16'h81_80;
//8'd31: svalue <= 16'h82_88;
//8'd32: svalue <= 16'h83_8f;
//8'd33: svalue <= 16'h84_96;
//8'd34: svalue <= 16'h85_a3;
//8'd35: svalue <= 16'h86_af;
//8'd36: svalue <= 16'h87_c4;
//8'd37: svalue <= 16'h88_d7;
//8'd38: svalue <= 16'h89_e8;
//
//// AGC/AEC tối ưu (giới hạn gain để giảm noise)
//8'd39: svalue <= 16'h13_e5;   // COM8: bật AGC/AEC
//8'd40: svalue <= 16'h24_60;   // AGC upper limit (giảm noise)
//8'd41: svalue <= 16'h25_30;   // AGC lower limit
//8'd42: svalue <= 16'h26_a5;   // AEC fast mode
//
//// Một số giá trị tối ưu màu
//8'd43: svalue <= 16'h33_0B;   // CHLF (magic)
//8'd44: svalue <= 16'h3C_78;   // COM12
//8'd45: svalue <= 16'h69_00;   // GFIX
//8'd46: svalue <= 16'hB0_84;   // magic
//8'd47: svalue <= 16'hB1_0C;
//8'd48: svalue <= 16'hB2_0E;
//8'd49: svalue <= 16'hB3_80;
//
//8'd50: svalue <= 16'hFF_FF;   // End
8'd0:  svalue <= 16'h12_80;   // Reset all registers
8'd1:  svalue <= 16'hFF_F0;   // Delay ~100ms
8'd2:  svalue <= 16'hFF_F0;   // Delay ~100ms
8'd3:  svalue <= 16'hFF_F0;   // Delay ~100ms
8'd4:  svalue <= 16'hFF_F0;   // Delay ~100ms
8'd5:  svalue <= 16'hFF_F0;   // Delay ~100ms

// Output format RGB565
8'd6:  svalue <= 16'h12_04;   // COM7: RGB
8'd7:  svalue <= 16'h15_20;   // PCLK không toggle khi blank
8'd8:  svalue <= 16'h40_d0;   // COM15: RGB565 full range
8'd9:  svalue <= 16'h8c_00;   // Disable RGB444
8'd10: svalue <= 16'h3a_04;   // TSLB: correct byte order

// Clock setup
8'd11: svalue <= 16'h11_00;   // CLKRC: Không chia (PCLK gốc)
8'd12: svalue <= 16'h0C_00;   // COM3: default
8'd13: svalue <= 16'h3E_00;   // COM14: no scaling
8'd14: svalue <= 16'h04_00;   // COM1: disable CCIR656

// Window setup 640x480
8'd15: svalue <= 16'h17_13;   // HSTART
8'd16: svalue <= 16'h18_01;   // HSTOP
8'd17: svalue <= 16'h19_02;   // VSTART
8'd18: svalue <= 16'h1A_7A;   // VSTOP
8'd19: svalue <= 16'h32_B6;   // HREF

// Color matrix
8'd20: svalue <= 16'h4F_80;
8'd21: svalue <= 16'h50_80;
8'd22: svalue <= 16'h51_00;
8'd23: svalue <= 16'h52_22;
8'd24: svalue <= 16'h53_5e;
8'd25: svalue <= 16'h54_80;
8'd26: svalue <= 16'h58_9e;

// Gamma correction
8'd27: svalue <= 16'h7a_20;
8'd28: svalue <= 16'h7b_1c;
8'd29: svalue <= 16'h7c_28;
8'd30: svalue <= 16'h7d_3c;
8'd31: svalue <= 16'h7e_55;
8'd32: svalue <= 16'h7f_68;
8'd33: svalue <= 16'h80_76;
8'd34: svalue <= 16'h81_80;
8'd35: svalue <= 16'h82_88;
8'd36: svalue <= 16'h83_8f;
8'd37: svalue <= 16'h84_96;
8'd38: svalue <= 16'h85_a3;
8'd39: svalue <= 16'h86_af;
8'd40: svalue <= 16'h87_c4;
8'd41: svalue <= 16'h88_d7;
8'd42: svalue <= 16'h89_e8;

// AGC/AEC tối ưu (giới hạn gain cao hơn)
8'd43: svalue <= 16'h13_e7;   // COM8: bật AGC/AEC/AWB
8'd44: svalue <= 16'h24_c0;   // AGC upper limit cao hơn
8'd45: svalue <= 16'h25_40;   // AGC lower limit
8'd46: svalue <= 16'h26_a3;   // AEC mode, cho phép phơi sáng cao hơn

// Một số giá trị tối ưu màu
8'd47: svalue <= 16'h33_0B;   // CHLF (magic)
8'd48: svalue <= 16'h3C_78;   // COM12
8'd49: svalue <= 16'h69_00;   // GFIX
8'd50: svalue <= 16'hB0_84;   // magic
8'd51: svalue <= 16'hB1_0C;
8'd52: svalue <= 16'hB2_0E;
8'd53: svalue <= 16'hB3_80;

8'd54: svalue <= 16'hFF_FF;   // End


		default: svalue <= 16'hFF_FF;
	endcase	
end

endmodule: ov7670_registers