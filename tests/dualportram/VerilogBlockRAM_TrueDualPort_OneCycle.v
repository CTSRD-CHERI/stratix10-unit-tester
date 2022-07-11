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
 * Synthesizable Verilog template for BRAM
 */


// True dual-port block RAM
module VerilogBlockRAM_TrueDualPort_OneCycle
  #(parameter DATA_WIDTH=1, parameter ADDR_WIDTH=1)
   (
    input [ADDR_WIDTH-1:0] 	ADDR_A, ADDR_B,
    input [DATA_WIDTH-1:0] 	DI_A, DI_B,
    input 			WE_A, WE_B, EN_A, EN_B, CLK,
    output reg [DATA_WIDTH-1:0] DO_A, DO_B,
    output reg 			DO_VALID_A, DO_VALID_B
    );
   
   // (* ramstyle = "m20k" *)  - pragma that could be tried, but not used by Intel template
   (* ramstyle = "m20k" *) reg [DATA_WIDTH-1:0] 	mem [2**ADDR_WIDTH-1:0];

   always @ (posedge CLK) begin
      if (WE_A && EN_A)
	mem[ADDR_A] = DI_A; // blocking assignment used by Intel template
      DO_A <= mem[ADDR_A];
      DO_VALID_A <= !WE_A && EN_A;

      if (WE_B && EN_B)
	mem[ADDR_B] = DI_B; // blocking assignment used by Intel template
      DO_B <= mem[ADDR_B];
      DO_VALID_B <= !WE_B && EN_B;
   end

endmodule // VerilogBlockRAM_OneCycle

