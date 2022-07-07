/*****************************************************************************
 * Synthesizable Verilog templates for BRAMs
 * Copyright (c) Simon Moore, 2022
 *****************************************************************************/


module VerilogBlockRAM_OneCycle
  #(parameter DATA_WIDTH=1, parameter ADDR_WIDTH=1)
   (
    output reg [DATA_WIDTH-1:0] DO,
    output reg 			DO_VALID,
    input [DATA_WIDTH-1:0] 	DI,
    input [ADDR_WIDTH-1:0] 	WR_ADDR, RD_ADDR,
    input 			WE, RE, CLK
    );
   
   // (* ramstyle = "m20k" *)  - pragma that could be tried
   reg [DATA_WIDTH-1:0] 	mem [2**ADDR_WIDTH-1:0];

   always @ (posedge CLK) begin
      if (WE)
        mem[WR_ADDR] = DI;
      if (RE)
	DO <= mem[RD_ADDR];
      else
	DO <= 0; // note M20K supports read-enable and output of zero when not enabled
      DO_VALID <= RE;
   end
endmodule // VerilogBlockRAM_OneCycle
