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
 * 
 * ----------------------------------------------------------------------------
 * 
 * Simple loop-back test of a named pipe
 */

import GetPut    :: *;
import FIFO      :: *;
import NamedPipe :: *;

module top(Empty);
  
  FIFO#(Bit#(8))  fifo <- mkSizedFIFO(256);
  Get#(Bit#(8)) rxpipe <- mkPipeReader();
  Put#(Bit#(8)) txpipe <- mkPipeWriter();
  Reg#(Bool)    finish <- mkReg(False);
  
  rule do_rx;
    Bit#(8) d <- rxpipe.get();
    $display("RX = 0x%02x", d);
    fifo.enq(d);
  endrule
  
  rule do_tx;
    fifo.deq;
    let reply = fifo.first ^ 8'h55; // invert every other bit in reply
    txpipe.put(reply);
    $display("\t\t\tTX = 0x%02x",reply);
    if(fifo.first==0)
      finish <= True;
  endrule

  rule the_end(finish);
    $finish(0);
  endrule
  
endmodule
