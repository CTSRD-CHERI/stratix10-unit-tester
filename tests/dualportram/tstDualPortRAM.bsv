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
//import RegFile            :: *;
import BlockRAMv          :: *;
import FIFOF              :: *;
import BlockRam           :: *;

typedef struct {
   Bit#(1) re;       // read enable
   Bit#(1) we;       // write enable
   Bit#(9) rd_addr;  // read address
   Bit#(9) wr_addr;  // write address
   Bit#(32) wr_data; // write data
   } CmdT deriving (Bits, Eq);

module top(Empty);

  FPGADebugInterface        comms <- mkFPGADebugInterface();
//  RegFile#(Bit#(9),Bit#(32)) m20k <- mkRegFileWCF(0,511); // M20K block is natively 512 x 40b but can also be used 512 x 32b
  BlockRamv#(Bit#(9),Bit#(32)) m20k <- mkBlockRAM_Verilog;
  BlockRamTrueMixed#(Bit#(9),Bit#(32),Bit#(9),Bit#(32)) brtm <- mkBlockRamTrueMixed;
  FIFOF#(CmdT)                  s <- mkSizedFIFOF(1024);
  FIFOF#(Bit#(32))             rd <- mkSizedFIFOF(1024);
  Reg#(Bool)      run_sequence[2] <- mkCReg(2, False);

  rule handle_requests;
    DebugRequest r <- comms.request.get();
    case (r.cmd)
      Cmd_write_word:
        if(r.idx == 0)
          begin
            Bit#(64) d = r.dat;
                  CmdT cmd = CmdT {
               re      : d[51],
               we      : d[50],
               rd_addr : d[49:41],
               wr_addr : d[40:32],
               wr_data : d[31:0]};
            s.enq(cmd);
          end
        else if(r.idx == 1)
          run_sequence[0] <= True;
        else
          $display("ERROR: invalid index %1d on write", r.idx);
      Cmd_read_word:
        if(r.idx == 0)
          if(rd.notEmpty)
            begin
              comms.response.put(zeroExtend(rd.first));
              rd.deq;
            end
          else
            comms.response.put(64'hdeaddead00000000);
        else if(r.idx == 1)
          comms.response.put(zeroExtend({pack(run_sequence[0]),pack(s.notFull),pack(s.notEmpty),pack(rd.notFull),pack(rd.notEmpty)}));
        else
          $display("ERROR: invalid index %1d on read", r.idx);
      default:
        $display("ERROR: command %1d not handled", r.cmd);
    endcase
  endrule

  rule do_sequence(run_sequence[1]);
    if(s.notEmpty)
      begin
        CmdT cmd = s.first;
        s.deq;
        brtm.putA(unpack(cmd.we), cmd.wr_addr, cmd.wr_data);
        if(cmd.re==1)
          rd.enq(brtm.dataOutA);
      end
    else
      run_sequence[1] <= False;
  endrule
endmodule
