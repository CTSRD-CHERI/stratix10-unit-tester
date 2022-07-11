// Copyright (C) 1991-2016 Altera Corporation
//
// Your use of Altera Corporation's design tools, logic functions
// and other software and tools, and its AMPP partner logic
// functions, and any output files from any of the foregoing
// (including device programming or simulation files), and any
// associated documentation or information are expressly subject
// to the terms and conditions of the Altera Program License
// Subscription Agreement, Altera MegaCore Function License
// Agreement, or other applicable license agreement, including,
// without limitation, that your use is for the sole purpose of
// programming logic devices manufactured by Altera and sold by
// Altera or its authorized distributors.  Please refer to the
// applicable agreement for further details.

// Generated by Quartus.
// With edits from Matthew Naylor, June 2016.

// Dual-port block RAM
// ===================

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module AlteraBlockRam (
  CLK,     // Clock
  DI,      // Data in
  RD_ADDR, // Read address
  WR_ADDR, // Write address
  WE,      // Write enable
  RE,      // Read enable
  BE,      // Byte enable
  DO       // Data out
  );

  parameter ADDR_WIDTH   = 1;
  parameter DATA_WIDTH   = 1;
  parameter NUM_ELEMS    = 1;
  parameter BE_WIDTH     = 1;
  parameter RD_DURING_WR = "OLD_DATA";     // Or: "DONT_CARE"
  parameter DO_REG       = "UNREGISTERED"; // Or: "CLOCK0"
  parameter INIT_FILE    = "UNUSED";
  parameter DEV_FAMILY   = "Stratix V";
  parameter STYLE        = "AUTO";

  input  CLK;
  input  [DATA_WIDTH-1:0] DI;
  input  [ADDR_WIDTH-1:0] RD_ADDR;
  input  [ADDR_WIDTH-1:0] WR_ADDR;
  input  [BE_WIDTH-1:0] BE;
  input  WE;
  input  RE;
  output [DATA_WIDTH-1:0] DO;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
  //tri1 BE[BE_WIDTH-1:0];
  tri1 CLK;
  tri0 WE;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

  altsyncram altsyncram_component (
        .address_a (WR_ADDR),
        .byteena_a (BE_WIDTH == 1 ? 1'b1 : BE),
        .clock0 (CLK),
        .data_a (DI),
        .wren_a (WE),
        .address_b (RD_ADDR),
        .q_b (DO),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_b (-1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
        .clocken2 (1'b1),
        .clocken3 (1'b1),
        .data_b (-1),
        .eccstatus (),
        .q_a (),
        .rden_a (1'b1),
        .rden_b (1'b1),
        .wren_b (1'b0));
  defparam
    altsyncram_component.address_aclr_b = "NONE",
    altsyncram_component.address_reg_b = "CLOCK0",
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_input_b = "BYPASS",
    altsyncram_component.clock_enable_output_b = "BYPASS",
    altsyncram_component.init_file = INIT_FILE,
    altsyncram_component.intended_device_family = DEV_FAMILY,
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = NUM_ELEMS,
    altsyncram_component.numwords_b = NUM_ELEMS,
    altsyncram_component.operation_mode = "DUAL_PORT",
    altsyncram_component.outdata_aclr_b = "NONE",
    altsyncram_component.outdata_reg_b = DO_REG,
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.read_during_write_mode_mixed_ports = RD_DURING_WR,
    altsyncram_component.widthad_a = ADDR_WIDTH,
    altsyncram_component.widthad_b = ADDR_WIDTH,
    altsyncram_component.width_a = DATA_WIDTH,
    altsyncram_component.width_b = DATA_WIDTH,
    altsyncram_component.width_byteena_a = BE_WIDTH,
    altsyncram_component.ram_block_type = STYLE;

endmodule

// Mixed-width true dual port block RAM
// ====================================

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module AlteraBlockRamTrueMixed (
  CLK,    // Clock
  DI_A,   // Port A data in
  DI_B,   // Port B data in
  ADDR_A, // Port A address
  ADDR_B, // Port B address
  WE_A,   // Port A write enable
  WE_B,   // Port B write enable
  EN_A,   // Port A enable
  EN_B,   // Port B enable
  DO_A,   // Port A data out
  DO_B    // Port B data out
  );

  parameter ADDR_WIDTH_A = 1;
  parameter ADDR_WIDTH_B = 1;
  parameter DATA_WIDTH_A = 1;
  parameter DATA_WIDTH_B = 1;
  parameter NUM_ELEMS_A  = 1;
  parameter NUM_ELEMS_B  = 1;
  parameter RD_DURING_WR = "OLD_DATA";     // Or: "DONT_CARE"
  parameter DO_REG_A     = "UNREGISTERED"; // Or: "CLOCK0"
  parameter DO_REG_B     = "UNREGISTERED"; // Or: "CLOCK0"
  parameter DEV_FAMILY   = "Stratix V";
  parameter INIT_FILE    = "UNUSED";
  parameter STYLE        = "AUTO";

  input   [ADDR_WIDTH_A-1:0]  ADDR_A;
  input   [ADDR_WIDTH_B-1:0]  ADDR_B;
  input   CLK;
  input   [DATA_WIDTH_A-1:0]  DI_A;
  input   [DATA_WIDTH_B-1:0]  DI_B;
  input   WE_A;
  input  WE_B;
  input  EN_A;
  input  EN_B;
  output [DATA_WIDTH_A-1:0]  DO_A;
  output [DATA_WIDTH_B-1:0]  DO_B;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
  tri1    CLK;
  tri0    WE_A;
  tri0    WE_B;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

  altsyncram altsyncram_component (
        .address_a (ADDR_A),
        .address_b (ADDR_B),
        .byteena_b (1'b1),
        .clock0 (CLK),
        .data_a (DI_A),
        .data_b (DI_B),
        .wren_a (EN_A & WE_A),
        .wren_b (EN_B & WE_B),
        .q_a (DO_A),
        .q_b (DO_B),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
        .clocken2 (1'b1),
        .clocken3 (1'b1),
        .eccstatus (),
        .rden_a (1'b1),
        .rden_b (1'b1));
  defparam
    altsyncram_component.address_reg_b = "CLOCK0",
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_input_b = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.clock_enable_output_b = "BYPASS",
    altsyncram_component.init_file = INIT_FILE,
    altsyncram_component.init_file_layout = "PORT_A",
    altsyncram_component.indata_reg_b = "CLOCK0",
    altsyncram_component.intended_device_family = DEV_FAMILY,
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = NUM_ELEMS_A,
    altsyncram_component.numwords_b = NUM_ELEMS_B,
    altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_aclr_b = "NONE",
    altsyncram_component.outdata_reg_a = DO_REG_A,
    altsyncram_component.outdata_reg_b = DO_REG_B,
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.read_during_write_mode_mixed_ports = RD_DURING_WR,
    altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
    altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
    altsyncram_component.widthad_a = ADDR_WIDTH_A,
    altsyncram_component.widthad_b = ADDR_WIDTH_B,
    altsyncram_component.width_a = DATA_WIDTH_A,
    altsyncram_component.width_b = DATA_WIDTH_B,
    altsyncram_component.width_byteena_a = 1,
    altsyncram_component.width_byteena_b = 1,
    altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0",
    altsyncram_component.ram_block_type = STYLE;

endmodule

// Mixed-width true dual port block RAM with byte enables
// ======================================================

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module AlteraBlockRamTrueMixedBE (
  CLK,    // Clock
  DI_A,   // Port A data in
  DI_B,   // Port B data in
  ADDR_A, // Port A address
  ADDR_B, // Port B address
  BE_B,   // Port B byte enable
  WE_A,   // Port A write enable
  WE_B,   // Port B write enable
  EN_A,   // Port A enable
  EN_B,   // Port B enable
  DO_A,   // Port A data out
  DO_B    // Port B data out
  );

  parameter ADDR_WIDTH_A = 1;
  parameter ADDR_WIDTH_B = 1;
  parameter DATA_WIDTH_A = 1;
  parameter DATA_WIDTH_B = 1;
  parameter NUM_ELEMS_A  = 1;
  parameter NUM_ELEMS_B  = 1;
  parameter BE_WIDTH     = 1;
  parameter RD_DURING_WR = "OLD_DATA";     // Or: "DONT_CARE"
  parameter DO_REG_A     = "UNREGISTERED"; // Or: "CLOCK0"
  parameter DO_REG_B     = "UNREGISTERED"; // Or: "CLOCK0"
  parameter DEV_FAMILY   = "Stratix V";
  parameter INIT_FILE    = "UNUSED";
  parameter STYLE        = "AUTO";

  input   [ADDR_WIDTH_A-1:0]  ADDR_A;
  input   [ADDR_WIDTH_B-1:0]  ADDR_B;
  input   [BE_WIDTH-1:0]      BE_B;
  input   CLK;
  input   [DATA_WIDTH_A-1:0]  DI_A;
  input   [DATA_WIDTH_B-1:0]  DI_B;
  input   WE_A;
  input  WE_B;
  input  EN_A;
  input  EN_B;
  output [DATA_WIDTH_A-1:0]  DO_A;
  output [DATA_WIDTH_B-1:0]  DO_B;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
  //tri1  [BE_WIDTH-1:0] BE_B;
  tri1    CLK;
  tri0    WE_A;
  tri0    WE_B;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

  // altsyncram altsyncram_component (
  //       .address_a (ADDR_A),
  //       .address_b (ADDR_B),
  //       .byteena_b (BE_B),
  //       .clock0 (CLK),
  //       .data_a (DI_A),
  //       .data_b (DI_B),
  //       .wren_a (EN_A & WE_A),
  //       .wren_b (EN_B & WE_B),
  //       .q_a (DO_A),
  //       .q_b (DO_B),
  //       .aclr0 (1'b0),
  //       .aclr1 (1'b0),
  //       .addressstall_a (1'b0),
  //       .addressstall_b (1'b0),
  //       .byteena_a (1'b1),
  //       .clock1 (1'b1),
  //       .clocken0 (1'b1),
  //       .clocken1 (1'b1),
  //       .clocken2 (1'b1),
  //       .clocken3 (1'b1),
  //       .eccstatus (),
  //       .rden_a (1'b1),
  //       .rden_b (1'b1));
  // defparam
  //   altsyncram_component.address_reg_b = "CLOCK0",
  //   altsyncram_component.byteena_reg_b = "CLOCK0",
  //   altsyncram_component.byte_size = 8,
  //   altsyncram_component.clock_enable_input_a = "BYPASS",
  //   altsyncram_component.clock_enable_input_b = "BYPASS",
  //   altsyncram_component.clock_enable_output_a = "BYPASS",
  //   altsyncram_component.clock_enable_output_b = "BYPASS",
  //   altsyncram_component.init_file = INIT_FILE,
  //   altsyncram_component.init_file_layout = "PORT_A",
  //   altsyncram_component.indata_reg_b = "CLOCK0",
  //   altsyncram_component.intended_device_family = DEV_FAMILY,
  //   altsyncram_component.lpm_type = "altsyncram",
  //   altsyncram_component.numwords_a = NUM_ELEMS_A,
  //   altsyncram_component.numwords_b = NUM_ELEMS_B,
  //   altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
  //   altsyncram_component.outdata_aclr_a = "NONE",
  //   altsyncram_component.outdata_aclr_b = "NONE",
  //   altsyncram_component.outdata_reg_a = DO_REG_A,
  //   altsyncram_component.outdata_reg_b = DO_REG_B,
  //   altsyncram_component.power_up_uninitialized = "FALSE",
  //   altsyncram_component.read_during_write_mode_mixed_ports = RD_DURING_WR,
  //   altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
  //   altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
  //   altsyncram_component.widthad_a = ADDR_WIDTH_A,
  //   altsyncram_component.widthad_b = ADDR_WIDTH_B,
  //   altsyncram_component.width_a = DATA_WIDTH_A,
  //   altsyncram_component.width_b = DATA_WIDTH_B,
  //   altsyncram_component.width_byteena_a = 1,
  //   altsyncram_component.width_byteena_b = BE_WIDTH,
  //   altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0",
  //   altsyncram_component.ram_block_type = STYLE;

  altera_syncram  altera_syncram_component (
               .address_a (ADDR_A),
               .address_b (ADDR_B),
               .clock0 (CLK),
               .data_a (DI_A),
               .data_b (DI_B),
               .wren_a (EN_A & WE_A),
               .wren_b (EN_B & WE_B),
               .q_a (DO_A),
               .q_b (DO_B),
               .aclr0 (1'b0),
               .aclr1 (1'b0),
               .address2_a (1'b1),
               .address2_b (1'b1),
               .addressstall_a (1'b0),
               .addressstall_b (1'b0),
               .byteena_a (1'b1),
               .byteena_b (BE_B),
               // .clock1 (1'b0),
               .clocken0 (1'b1),
               // .clocken1 (1'b0),
               .eccencbypass (1'b0),
               .eccencparity (8'b0),
               .eccstatus (),
               .rden_a (1'b1),
               .rden_b (1'b1),
               .sclr (1'b0));
   defparam
       altera_syncram_component.operation_mode  = "BIDIR_DUAL_PORT",

       // port A
       altera_syncram_component.width_a  = DATA_WIDTH_A,
       altera_syncram_component.widthad_a  = ADDR_WIDTH_A,
       altera_syncram_component.widthad2_a  = ADDR_WIDTH_A,
       altera_syncram_component.numwords_a  = NUM_ELEMS_A,
       altera_syncram_component.outdata_reg_a  = "CLOCK0", // UNREGISTERED : CLOCK0
       altera_syncram_component.outdata_aclr_a  = "NONE",
       altera_syncram_component.outdata_sclr_a  = "NONE",
       altera_syncram_component.address_aclr_a  = "NONE",
       altera_syncram_component.width_byteena_a  = 1,

       altera_syncram_component.width_b  = DATA_WIDTH_B,
       altera_syncram_component.widthad_b  = ADDR_WIDTH_B,
       altera_syncram_component.widthad2_b  = ADDR_WIDTH_B,
       altera_syncram_component.numwords_b  = NUM_ELEMS_B,
       altera_syncram_component.outdata_reg_b  = "CLOCK0",
       altera_syncram_component.indata_reg_b  = "CLOCK0",
       altera_syncram_component.address_reg_b  = "CLOCK0",
       altera_syncram_component.byteena_reg_b  = "CLOCK0",
       altera_syncram_component.outdata_aclr_b  = "NONE",
       altera_syncram_component.outdata_sclr_b  = "NONE",
       altera_syncram_component.address_aclr_b  = "NONE",
       altera_syncram_component.width_byteena_b  = BE_WIDTH,

       altera_syncram_component.intended_device_family  = "Stratix 10",
       altera_syncram_component.ram_block_type  = STYLE,
       altera_syncram_component.byte_size  = "8",

       altera_syncram_component.read_during_write_mode_mixed_ports  = "DONT_CARE", // only supported value RD_DURING_WR,

       altera_syncram_component.init_file = INIT_FILE,
       altera_syncram_component.init_file_layout = "PORT_A",

       altera_syncram_component.clock_enable_input_a  = "BYPASS",
       altera_syncram_component.clock_enable_output_a  = "BYPASS",
       altera_syncram_component.clock_enable_core_a  = "BYPASS",

       altera_syncram_component.clock_enable_input_b  = "BYPASS",
       altera_syncram_component.clock_enable_output_b  = "BYPASS",
       altera_syncram_component.clock_enable_core_b  = "BYPASS",

       altera_syncram_component.read_during_write_mode_port_a  = "NEW_DATA_NO_NBE_READ",
       altera_syncram_component.read_during_write_mode_port_b  = "NEW_DATA_NO_NBE_READ",

       altera_syncram_component.enable_ecc = "FALSE",
       altera_syncram_component.ecc_pipeline_stage_enabled = "FALSE",
       altera_syncram_component.enable_ecc_encoder_bypass = "FALSE",

       altera_syncram_component.enable_coherent_read = "FALSE",
       altera_syncram_component.enable_force_to_zero  = "FALSE",

       altera_syncram_component.width_eccencparity = "8",
       altera_syncram_component.optimization_option = "AUTO";

       // altera_syncram_component.lpm_type  = "altera_syncram",
       // altera_syncram_component.power_up_uninitialized  = "FALSE",


endmodule

// Quartus Prime SystemVerilog Template
//
// True Dual-Port RAM with single clock
// and individual controls for writing into separate bytes of the memory word (byte-enable)
//
// Read-during-write returns either new or old data depending
// on the order in which the simulator executes the process statements.
// Quartus Prime will consider this read-during-write scenario as a
// don't care condition to optimize the performance of the RAM.  If you
// need a read-during-write behavior to be determined, you
// must instantiate the altsyncram Megafunction directly.
module AlteraBlockRamTrueBEInfer#(
		parameter int
		BYTE_WIDTH = 8,
		ADDRESS_WIDTH = 6,
		BYTES = 4,
		DATA_WIDTH = BYTE_WIDTH * BYTES
)
(
	input [ADDRESS_WIDTH-1:0] addr1,
	input [ADDRESS_WIDTH-1:0] addr2,
	input [BYTES-1:0] be2,
	input [DATA_WIDTH-1:0] data_in1,
	input [DATA_WIDTH-1:0] data_in2,
	input we1, we2, clk,
	output [DATA_WIDTH-1:0] data_out1,
	output [DATA_WIDTH-1:0] data_out2);
	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

	// model the RAM with two dimensional packed array
	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	reg [DATA_WIDTH-1:0] data_reg1;
	reg [DATA_WIDTH-1:0] data_reg2;


	// port A
	always@(posedge clk)
	begin
		if(we1) begin
		// edit this code if using other than four bytes per word
			ram[addr1][0] = data_in1[BYTE_WIDTH-1:0];
			ram[addr1][1] = data_in1[2*BYTE_WIDTH-1:BYTE_WIDTH];
			ram[addr1][2] = data_in1[3*BYTE_WIDTH-1:2*BYTE_WIDTH];
			ram[addr1][3] = data_in1[4*BYTE_WIDTH-1:3*BYTE_WIDTH];
		end
	end

	always@(posedge clk)
	begin
		data_reg1 <= ram[addr1];
	end

	assign data_out1 = data_reg1;

	// port B
	always@(posedge clk)
	begin
		if(we2) begin
		// edit this code if using other than four bytes per word
			if(be2[0]) ram[addr2][0] = data_in2[BYTE_WIDTH-1:0];
			if(be2[1]) ram[addr2][1] = data_in2[2*BYTE_WIDTH-1:BYTE_WIDTH];
			if(be2[2]) ram[addr2][2] = data_in2[3*BYTE_WIDTH-1:2*BYTE_WIDTH];
			if(be2[3]) ram[addr2][3] = data_in2[4*BYTE_WIDTH-1:3*BYTE_WIDTH];
		end
	end

	always@(posedge clk)
	begin
		data_reg2 <= ram[addr2];
	end

	assign data_out2 = data_reg2;

endmodule : AlteraBlockRamTrueBEInfer
