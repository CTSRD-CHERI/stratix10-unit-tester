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
 * Simple loop-back test of a DebugChannel
 */

import GetPut       :: *;
import ClientServer :: *;
import FIFO         :: *;
import DebugChannel :: *;

module top(Empty);
  
  FIFO#(Bit#(8))   fifo <- mkSizedFIFO(256);
  DebugChannel     pipe <- mkDebugChannel();
  Reg#(Bool)     finish <- mkReg(False);
  
  rule receive_request;
    Bit#(8) d <- pipe.request.get();
    $display("RX = 0x%02x", d);
    fifo.enq(d);
  endrule
  
  rule send_response;
    fifo.deq;
    let reply = fifo.first ^ 8'h55; // invert every other bit in reply
    pipe.response.put(reply);
    $display("\t\t\tTX = 0x%02x",reply);
    if(fifo.first==0)
      finish <= True;
  endrule

  rule the_end(finish);
    $finish(0);
  endrule
  
endmodule
