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
 * This module provides byte-level communication over a named pipe for use in
 * simulation. ("Pure" since BSV only (i.e. no Verilog) version of NamedPipe.bsv)
 */

package NamedPipePure;

export mkPipeReader;
export mkPipeWriter;
export mkPipeClient;

import FIFO           :: *;
import GetPut         :: *;
import ClientServer   :: *;

module mkPipeReader(Get#(Bit#(8)));
  FIFO#(Bit#(8))         rxfifo <- mkFIFO;
  Reg#(Bit#(8))  read_slow_down <- mkReg(1);
  Reg#(File)                fdr <- mkReg(InvalidFile);

  rule open_file(fdr==InvalidFile);
    File f <- $fopen("bytepipe-host2hw","rb");
    fdr <= f;
  endrule

  rule do_read((fdr!=InvalidFile) && (read_slow_down==0));
    int i <- $fgetc(fdr);
    if(i>=0)
      begin
	Bit#(8) c = truncate(pack(i));
	rxfifo.enq(c);
	$display("DEBUG: read 0x%02x", c);
      end
  endrule
  
  rule count;
    read_slow_down <= read_slow_down+1;
  endrule

  return fifoToGet(rxfifo);
endmodule: mkPipeReader


module mkPipeWriter(Put#(Bit#(8)));
  FIFO#(Bit#(8)) txfifo <- mkFIFO;
  Reg#(File) fdw <- mkReg(InvalidFile);

  rule open_file(fdw==InvalidFile);
    File f <- $fopen("bytepipe-hw2host","wb");
    fdw <= f;
  endrule

  rule do_write(fdw!=InvalidFile);
    $display("DEBUG: write 0x%02x", txfifo.first);
    $fwrite(fdw, "%c", txfifo.first);
    $fflush(fdw);
    txfifo.deq;
  endrule
  
  return fifoToPut(txfifo);
endmodule: mkPipeWriter


module mkPipeClient(Client#(Bit#(8),Bit#(8)));
    Get#(Bit#(8)) rx <- mkPipeReader;
    Put#(Bit#(8)) tx <- mkPipeWriter;
    interface request  = rx;
    interface response = tx;
endmodule

  
endpackage: NamedPipePure
