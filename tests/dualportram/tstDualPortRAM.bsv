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

typedef struct {
   Bit#(1)  re;       // read enable
   Bit#(1)  we;       // write enable
   Bit#(9)  rd_addr;  // read address
   Bit#(9)  wr_addr;  // write address
   Bit#(32) wr_data;  // write data
   } CmdSpT deriving (Bits, Eq);

typedef struct {
   // Port A
   Bit#(1)  reA;      // read enable
   Bit#(1)  weA;      // write enable
   Bit#(12) addrA;    // address
   Bit#(8)  wr_dataA; // write data
   // Port B
   Bit#(1)  reB;      // read enable
   Bit#(1)  weB;      // write enable
   Bit#(12) addrB;    // address
   Bit#(8)  wr_dataB; // write data
   } CmdDpT deriving (Bits, Eq);

typedef struct {
   // Port A
   Bit#(1)   reA;      // read enable
   Bit#(1)   weA;      // write enable
   Bit#(13)  addrA;    // address
   Bit#(128) wr_dataA; // write data
   // Port B
   Bit#(1)   reB;      // read enable
   Bit#(1)   weB;      // write enable
   Bit#(15)  addrB;    // address
   Bit#(4)   beB;      // byte enables
   Bit#(32)  wr_dataB; // write data
   } CmdMwT deriving (Bits, Eq);


module top(Empty);

  FPGADebugInterface          comms <- mkFPGADebugInterface();
  //----For tests on single read, single write Block RAM
  //  RegFile#(Bit#(9),Bit#(32)) m20k <- mkRegFileWCF(0,511); // M20K block is natively 512 x 40b but can also be used 512 x 32b
  BlockRam#(Bit#(9),Bit#(32))  m20k <- mkBlockRAM;
  FIFOF#(CmdSpT)              cmdsp <- mkSizedFIFOF(1024);
  FIFOF#(Bit#(32))             rdsp <- mkSizedFIFOF(1024);
  Reg#(Bool)     run_sequence_sp[2] <- mkCReg(2, False);
  //----For tests on true dual-port block RAM
  BlockRamTrueDualPort#(Bit#(12),Bit#(8)) dpram <- mkDualPortBlockRAM;
  FIFOF#(CmdDpT)              cmddp <- mkSizedFIFOF(1024);
  FIFOF#(Bit#(8))             rddpA <- mkSizedFIFOF(1024);
  FIFOF#(Bit#(8))             rddpB <- mkSizedFIFOF(1024);
  Reg#(Bool)     run_sequence_dp[2] <- mkCReg(2, False);
  //----For tests on true dual-port *multi-width* block RAM with write enables
  BlockRamTrueMixedByteEn#(Bit#(13), Bit#(128), Bit#(15), Bit#(32),4) mwram <- mkBlockRamTrueMixedBE;
  FIFOF#(CmdMwT)              cmdmw <- mkSizedFIFOF(1024);
  FIFOF#(Bit#(128))           rdmwA <- mkSizedFIFOF(1024);
  FIFOF#(Bit#(32))            rdmwB <- mkSizedFIFOF(1024);
  Reg#(Bool)     run_sequence_mw[2] <- mkCReg(2, False);
  Vector#(3,Reg#(Bit#(64))) data_write <- replicateM(mkReg(0));

  rule handle_requests;
    DebugRequest r <- comms.request.get();
    case (r.cmd)
      Cmd_write_word:
        //----Commands for simple read/write BRAM (1 read port, 1 write port)
        if(r.idx == 0) // read/write BRAM: write command
	  begin
	    Bit#(64) d = r.dat;
      	    CmdSpT cmd = CmdSpT {
               re      : d[51],
	       we      : d[50],
	       rd_addr : d[49:41],
	       wr_addr : d[40:32],
	       wr_data : d[31:0]};
	    cmdsp.enq(cmd);
	  end
        else if(r.idx == 1) // read/write BRAM: trigger test sequence
	  run_sequence_sp[0] <= True;
        //----Commands for true dual-port BRAM (without byte enables, same width for both ports)
        else if(r.idx == 2) // true dual-port BRAM: write command
	  begin
	    Bit#(64) d = r.dat;
      	    CmdDpT cmd = CmdDpT {
	       reB      : d[43],
	       weB      : d[42],
               reA      : d[41],
	       weA      : d[40],
	       addrB    : d[39:28], // 12-bit
	       addrA    : d[27:16], // 12-bit
	       wr_dataB : d[15:8],  // 8-bit
	       wr_dataA : d[7:0]};  // 8-bit
	    cmddp.enq(cmd);
	    $display("reB=%1d  weB=%1d  reA=%1d  weA=%1d  addrB=%4d  addrA=%4d  wr_dataB=%3d wr_dataA=%3d",
	       cmd.reB, cmd.weB, cmd.reA, cmd.weA, cmd.addrB, cmd.addrA, cmd.wr_dataB, cmd.wr_dataA);
	  end
        else if(r.idx == 3) // true dual-port BRAM: trigger test sequence
	  run_sequence_dp[0] <= True;
        //----Commands for true dual-port mixed width BRAM with byte enables
	else if(r.idx == 4)
	  begin
	    Bit#(64) d = r.dat;
	    CmdMwT cmd = CmdMwT {
	       reB      : d[35],
	       weB      : d[34],
	       reA      : d[33],
	       weA      : d[32],
	       beB      : d[31:28], // 4-bits
	       addrB    : d[27:13], // 15-bits
	       addrA    : d[12:0],  // 13-bits
	       wr_dataB : data_write[2][31:0], // 32-bits
	       wr_dataA : {data_write[1],data_write[0]} // 128-bit
	       };
//	    $display("multi-width command: reB=%d weB=%d    reA=%d weA=%d   addrB=%4d  wr_dataB=0x%08x",cmd.reB,cmd.weB,cmd.reA,cmd.weA,cmd.addrB,cmd.wr_dataB);
	    cmdmw.enq(cmd);
	  end
        else if(r.idx == 6)
	  data_write[0] <= r.dat; // lower 64-bits of dataA
        else if(r.idx == 7)
	  data_write[1] <= r.dat; // upper 64-bits of dataA
        else if(r.idx == 8)
	  data_write[2] <= r.dat; // 32-bits of dataB
        else if(r.idx == 9)
	  run_sequence_mw[0] <= True;
        else
	  $display("ERROR: invalid index %1d on write", r.idx);
      Cmd_read_word:
        //----Responses for simple read/write BRAM (1 read port, 1 write port)
        if(r.idx == 0) // read/write BRAM: read responses
	  if(rdsp.notEmpty)
	    begin
	      comms.response.put(zeroExtend(rdsp.first));
	      rdsp.deq;
	    end
          else
	    comms.response.put(64'hdeaddead00000000);
        else if(r.idx == 1) // read/write BRAM: read flags
	  comms.response.put(zeroExtend({pack(run_sequence_sp[0]),pack(cmdsp.notFull),pack(cmdsp.notEmpty),pack(rdsp.notFull),pack(rdsp.notEmpty)}));
        //----Responses for true dual-port BRAM (without byte enables, same width for both ports)
        else if(r.idx == 2) // true dual-port BRAM: read response port A
	  if(rddpA.notEmpty)
	    begin
	      comms.response.put(zeroExtend(rddpA.first));
	      rddpA.deq;
	    end
          else
	    comms.response.put(64'hdeaddead00000000);
        else if(r.idx == 3) // true dual-port BRAM: read response port B
	  if(rddpB.notEmpty)
	    begin
	      comms.response.put(zeroExtend(rddpB.first));
	      rddpB.deq;
	    end
          else
	    comms.response.put(64'hdeaddead00000000);
        else if(r.idx == 4) // true dual-port BRAM: read flags
	  comms.response.put(zeroExtend({pack(run_sequence_dp[0]),pack(cmddp.notFull),pack(cmddp.notEmpty),pack(rddpB.notFull),pack(rddpB.notEmpty),pack(rddpA.notFull),pack(rddpA.notEmpty)}));
        //----Response for true dual-port mixed width BRAM with byte enables
        else if(r.idx == 5)
	  if(rdmwA.notEmpty)
	    begin // read lower 64-bit port A and dequeue
	      comms.response.put(rdmwA.first[63:0]);
              rdmwA.deq;
	    end
          else
	    comms.response.put(64'hdeaddead00000000);
        else if(r.idx == 6) // read upper 64-bit port A (no dequeue)
	  if(rdmwA.notEmpty)
	    comms.response.put(rdmwA.first[127:64]);
          else
	    comms.response.put(64'hdeaddead00000000);
        else if(r.idx == 7) begin // read port B
	  if(rdmwB.notEmpty) begin
	    comms.response.put(zeroExtend(rdmwB.first));
	    rdmwB.deq;
	  end
	  else
	    comms.response.put(64'hdeaddead00000000);
	end
        else if(r.idx == 8) // read flags
	  comms.response.put(zeroExtend({pack(run_sequence_mw[0]),pack(cmdmw.notFull),pack(cmdmw.notEmpty),pack(rdmwB.notFull),pack(rdmwB.notEmpty),pack(rdmwA.notFull),pack(rdmwA.notEmpty)}));
        else
	  $display("ERROR: invalid index %1d on read", r.idx);
      default:
        $display("ERROR: command %1d not handled", r.cmd);
    endcase
  endrule

  //----run tests on simple read/write BRAM (1 read port, 1 write port)
  rule do_sequence_sp(run_sequence_sp[1]);
    if(cmdsp.notEmpty)
      begin
	CmdSpT cmd = cmdsp.first;
	cmdsp.deq;
	if(cmd.we==1)
	  m20k.write(cmd.wr_addr, cmd.wr_data);
	  // m20k.upd(cmd.wr_addr, cmd.wr_data);
        if(cmd.re==1)
	  m20k.read(cmd.rd_addr);
	  // rdsp.enq(m20k.sub(cmd.rd_addr));
      end
    else
      run_sequence_sp[1] <= False;
  endrule
  rule store_reads_sp(m20k.dataOutValid);
    rdsp.enq(m20k.dataOut);
  endrule  

  //----run tests on true dual-port block RAM
  rule do_sequence_dp(run_sequence_dp[1]);
    if(cmddp.notEmpty)
      begin
	CmdDpT cmd = cmddp.first;
	cmddp.deq;
	if((cmd.weA==1) || (cmd.reA==1))
	   dpram.putA(cmd.weA==1, cmd.reA==1, cmd.addrA, cmd.wr_dataA);
	if((cmd.weB==1) || (cmd.reB==1))
	   dpram.putB(cmd.weB==1, cmd.reB==1, cmd.addrB, cmd.wr_dataB);
      end
    else
      run_sequence_dp[1] <= False;
  endrule
  rule store_reads_dpA(dpram.dataOutValidA);
    rddpA.enq(dpram.dataOutA);
  endrule  
  rule store_reads_dpB(dpram.dataOutValidB);
    rddpB.enq(dpram.dataOutB);
  endrule  

  //----run tests on true dual-port mixed width BRAM with byte enables
  rule do_sequence_mw(run_sequence_mw[1]);
    if(cmdmw.notEmpty)
      begin
	CmdMwT cmd = cmdmw.first;
	cmdmw.deq;
	$display("multi-width command deq: reB=%d weB=%d    reA=%d weA=%d",cmd.reB,cmd.weB,cmd.reA,cmd.weA);
	if((cmd.weA==1) || (cmd.reA==1))
	  mwram.putA(cmd.weA==1, cmd.reA==1, cmd.addrA, cmd.wr_dataA);
	if((cmd.weB==1) || (cmd.reB==1))
	  mwram.putB(cmd.weB==1, cmd.reB==1, cmd.addrB, cmd.wr_dataB, cmd.beB);
      end
    else
      run_sequence_mw[1] <= False;
  endrule
  rule store_reads_mwA(mwram.dataOutValidA);
    rdmwA.enq(mwram.dataOutA);
  endrule  
  rule store_reads_mwB(mwram.dataOutValidB);
    rdmwB.enq(mwram.dataOutB);
  endrule  
endmodule
