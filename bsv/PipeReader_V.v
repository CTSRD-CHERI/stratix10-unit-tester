/*
 * Copyright (c) 2021 Simon W. Moore
 * All rights reserved.
 *
 * This software was developed at the University of Cambridge Computer
 * Laboratory (Department of Computer Science and Technology) based
 * upon work supported by the DoD Information Analysis Center Program
 * Management Office (DoD IAC PMO), sponsored by the Defense
 * Technical Information Center (DTIC) under Contract No. FA807518D0004.
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
 * /
module PipeReader_V
  (
   input 	CLK,
   input 	RST_N,
   input 	EN_GET,
   output [7:0] GET,
   output 	RDY_GET
   );

   reg [7:0] 	data;
   reg 		valid;
   reg [11:0] 	read_slow_down;  // HACK: avoid blocking on $fgetc when other work needs to be done
   
   integer fdr;
   integer c;
   
   initial begin
      fdr = $fopen("bytepipe-host2hw", "rb");
      valid <= 0;
   end

   assign RDY_GET = valid;
   assign GET = data;

   always @(posedge CLK)
     if(!RST_N)
       begin
	  valid <= 1'b0;
	  read_slow_down <= 0;
       end
     else
       if(valid && EN_GET)
	 valid <= 1'b0;
       else
	 begin
	    read_slow_down <= read_slow_down+1;
	    if(read_slow_down==0)
	      begin
		 c = $fgetc(fdr);  // TODO: this appears to be blocking despite the named pipe being setup non-blocking
		 if(c<0) $finish(0);
		 if(c>=0)
		   begin
		      data <= c;
		      valid <= 1'b1;
		   end
	      end
	 end // else: !if(valid && EN_GET)

endmodule
