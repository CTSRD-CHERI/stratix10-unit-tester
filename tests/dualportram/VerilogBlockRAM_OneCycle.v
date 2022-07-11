/*
 * Copyright (c) 2022 Simon W. Moore
 * All rights reserved.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 * 
 * ----------------------------------------------------------------------------
 * Synthesizable Verilog templates for BRAMs
 */


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
   (* ramstyle = "m20k" *) reg [DATA_WIDTH-1:0] 	mem [2**ADDR_WIDTH-1:0];

   always @ (posedge CLK) begin
      if (WE)
        mem[WR_ADDR] = DI;  // should trigger coherent read
      DO <= mem[RD_ADDR];
      DO_VALID <= RE;
   end
endmodule // VerilogBlockRAM_OneCycle


/*
// This version zeros DO when RE=0, but this results in extra logic
module VerilogBlockRAM_OneCycle_ZeroNoRE
  #(parameter DATA_WIDTH=1, parameter ADDR_WIDTH=1)
   (
    input [DATA_WIDTH-1:0] 	DI,
    input [ADDR_WIDTH-1:0] 	WR_ADDR, RD_ADDR,
    input 			WE, RE, CLK,
    output reg [DATA_WIDTH-1:0] DO,
    output reg 			DO_VALID
    );
   
   // (* ramstyle = "m20k" *)  - pragma that could be tried
   (* ramstyle = "m20k" *) reg [DATA_WIDTH-1:0] 	mem [2**ADDR_WIDTH-1:0];

   always @ (posedge CLK) begin
      if (WE)
	mem[WR_ADDR] <= DI;
      if (RE)
	DO <= mem[RD_ADDR];
      else
  	DO <= 0; // note M20K supports read-enable and output of zero when not enabled
      DO_VALID <= RE;
   end
endmodule // VerilogBlockRAM_OneCycle
*/
