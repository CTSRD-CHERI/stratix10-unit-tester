/*
 * Copyright (c) 2021 Simon W. Moore
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
 * Example that reads the FPGA chip ID
 */

import Vector             :: *;
import GetPut             :: *;
import ClientServer       :: *;
import FPGADebugInterface :: *;
import ChipID             :: *;

module top(Empty);

  FPGADebugInterface comms <- mkFPGADebugInterface();
  Get#(Bit#(64))     getid <- mkChipID;
  
  rule handle_requests;
    DebugRequest r <- comms.request.get();
    if((r.cmd==Cmd_read_word) && (r.idx==0))
      begin
	Bit#(64) id <- getid.get();
        comms.response.put(id);
      end
  endrule
  
endmodule
