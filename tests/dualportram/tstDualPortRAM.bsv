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
 * 
 * Test dual-port RAM (M20K blocks) in simulation and on FPGA
 */

import Vector             :: *;
import GetPut             :: *;
import ClientServer       :: *;
import FPGADebugInterface :: *;
import RegFile            :: *;

module top(Empty);

  FPGADebugInterface comms <- mkFPGADebugInterface();
  Reg#(Bit#(9))   addr_reg <- mkReg(0);
  RegFile#(Bit#(9),Bit#(32)) m20k <- mkRegFileWCF(0,511); // M20K block is natively 512 x 40b but can also be used 512 x 32b
  
  rule handle_requests;
    DebugRequest r <- comms.request.get();
    case (r.cmd)
      Cmd_write_word:
        if(r.idx == 0)
	  m20k.upd(addr_reg, truncate(r.dat));
        else if(r.idx == 1)
	  addr_reg <= truncate(r.dat);
        else
	  $display("ERROR: invalid index %1d on write", r.idx);
      Cmd_read_word:
        if(r.idx == 0)
	  comms.response.put(zeroExtend(m20k.sub(addr_reg)));
        else
	  $display("ERROR: invalid index %1d on read", r.idx);
      default:
        $display("ERROR: command %1d not handled", r.cmd);
    endcase
  endrule
  
endmodule
