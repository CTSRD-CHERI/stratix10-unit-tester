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
 * Builds on BlockRAM by Matt Naylor, et al.
 * This "v" version uses pure Verilog to describe basic single and
 * true dual-port RAMs that can be inferred as BRAMs like M20K on Stratix 10.
 */

package BlockRAMv;

import Vector :: *;
import Assert :: *;

// ==========
// Interfaces
// ==========

// Basic dual-port block RAM with a read port and a write port
interface BlockRam#(type addr, type data);
  method Action write(addr a, data d);  // write data (d) to address (a)
  method Action read(addr a);           // initiate read from address (a)
  method data dataOut;                  // read result returned
  method Bool dataOutValid;             // True when read result available
endinterface


// True dual-port block RAM: ports A and B can write or read independently
interface BlockRamTrueDualPort#(type addr, type data);
  // Port A
  method Action putA(Bool we, addr a, data d); // initiate read or write (not both)
  method data dataOutA;                        // read result returned
  method Bool dataOutValidA;                   // True when read result available
  // Port B
  method Action putB(Bool we, addr a, data d); // initiate read or write (not both)
  method data dataOutB;                        // read result returned
  method Bool dataOutValidB;                   // True when read result available
endinterface

//function getDataOutValidA(BlockRamTrueDualPort#(addr,data) ram) = ram.dataOutValidA;
//function getDataOutValidB(BlockRamTrueDualPort#(addr,data) ram) = ram.dataOutValidB;
  

// =====================
// Verilog Instatiations
// =====================

import "BVI" VerilogBlockRAM_OneCycle =
  module mkBlockRAM_Verilog(BlockRam#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth));

    parameter ADDR_WIDTH     = valueOf(addrWidth);
    parameter DATA_WIDTH     = valueOf(dataWidth);

    method write(WR_ADDR, DI) enable (WE) clocked_by(clk);
    method read(RD_ADDR) enable (RE) clocked_by(clk);
    method DO dataOut;
    method DO_VALID dataOutValid;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOut)      CF (dataOut, dataOutValid, read, write);
    schedule (dataOutValid) CF (dataOut, dataOutValid, read, write);
    schedule (read)         CF (write);
    schedule (write)        C  (write);
    schedule (read)         C  (read);
  endmodule


import "BVI" VerilogBlockRAM_TrueDualPort_OneCycle =
  module mkDualPortBlockRAM_Verilog(BlockRamTrueDualPort#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth));

    parameter ADDR_WIDTH     = valueOf(addrWidth);
    parameter DATA_WIDTH     = valueOf(dataWidth);

    method putA(WE_A, ADDR_A, DI_A) enable (EN_A) clocked_by(clk);
    method DO_A dataOutA;
    method DO_VALID_A dataOutValidA;

    method putB(WE_B, ADDR_B, DI_B) enable (EN_B) clocked_by(clk);
    method DO_B dataOutB;
    method DO_VALID_B dataOutValidB;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOutA)      CF (dataOutA, dataOutB, putA, putB);
    schedule (dataOutB)      CF (dataOutA, dataOutB, putA, putB);
    schedule (dataOutValidA) CF (dataOutValidA,dataOutValidB,dataOutA,dataOutB,putA,putB);
    schedule (dataOutValidB) CF (dataOutValidA,dataOutValidB,dataOutA,dataOutB,putA,putB);
    schedule (putA)          CF (putB);
    schedule (putB)          CF (putA);
    schedule (putA)          C  (putA);
    schedule (putB)          C  (putB);
  endmodule


// =====================================================
// Bluespec modules that use the Verilog BRAM primatives
// =====================================================

// True dual-port mixed-width block RAM with byte-enables
// (Port B has the byte enables and must be smaller than port A)

interface BlockRamTrueMixedByteEn#
            (type addrA, type dataA,
             type addrB, type dataB,
             numeric type dataBBytes);
  // Port A
  method Action putA(Bool wr, addrA a, dataA x);
  method dataA dataOutA;
  method Bool dataOutValidA; // added to original interface to indicate when data is available
  // Port B
  method Action putB(Bool wr, addrB a, dataB x, Bit#(dataBBytes) be);
  method dataB dataOutB;
  method Bool dataOutValidB; // added to original interface to indicate when data is available
endinterface


module mkBlockRamTrueMixedBE
      (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
    provisos(Bits#(addrA, awidthA), Bits#(dataA, dwidthA),
             Bits#(addrB, awidthB), Bits#(dataB, dwidthB),
             Bounded#(addrA),       Bounded#(addrB),
             Add#(awidthA, aExtra, awidthB),
	     Log#(expaExtra, aExtra),
             Mul#(expaExtra, dwidthB, dwidthA),
             Mul#(dataBBytes, 8, dwidthB),
             Div#(dwidthB, dataBBytes, 8),
             Mul#(dataABytes, 8, dwidthA),
             Div#(dwidthA, dataABytes, 8),
             Mul#(expaExtra, dataBBytes, dataABytes),
	     Log#(dataABytes, logdataABytes),
	     Log#(dataBBytes, logdataBBytes),
	     Add#(aExtra, logdataBBytes, logdataABytes));

  // Instatitate byte-wide RAMs to fit the data width of port A since it is the widest port
  Vector#(dataABytes, BlockRamTrueDualPort#(Bit#(awidthA), Bit#(8))) rams <- replicateM(mkDualPortBlockRAM_Verilog);
  // addrB needed during read to select the right word
  Reg#(addrB) save_addrB <- mkReg(unpack(0));
  Wire#(Maybe#(addrA)) check_addrA <- mkDWire(Invalid);
  Wire#(Maybe#(addrB)) check_addrB <- mkDWire(Invalid);
  
  rule assert_no_write_collision(isValid(check_addrA) && isValid(check_addrB));
    Bit#(awidthA) addrA = pack(fromMaybe(?, check_addrA));
    Bit#(awidthA) addrB = truncate(pack(fromMaybe(?, check_addrB))>>valueOf(aExtra));
    if(addrA == addrB) // TODO: turn this into a dynamic assertion
      $display("ERROR in mkBlockRamTrueMixedBE: address collision on two writes");
  endrule
  
  method Action putA(wr, a, x);
    Bit#(dwidthA) data = pack(x);
    for(Integer n=0; n<valueOf(dataABytes); n=n+1)
	rams[n].putA(wr, pack(a), data[n*8+7:n*8]);
    if(wr) check_addrA <= tagged Valid a;
  endmethod
  
  method Action putB(wr, a, x, be);
    for(Integer n=0; n<valueOf(dataBBytes); n=n+1)
      if(be[n]==1)
	begin
	  Bit#(aExtra) bank_select = truncate(pack(a));
	  Bit#(logdataBBytes) byte_select = fromInteger(n);
	  Bit#(logdataABytes) bram_select = {bank_select, byte_select};
	  Bit#(awidthA) addr = truncate(unpack(pack(a) >> valueOf(aExtra)));
	  Bit#(dwidthB) data = pack(x);
	  rams[bram_select].putB(wr, addr, data[n*8+7:n*8]);
	end
    save_addrB <= a;
    if(wr) check_addrB <= tagged Valid a;
  endmethod
  
  method dataA dataOutA;
     Vector#(dataABytes,Bit#(8)) b;
     for(Integer n=0; n<valueOf(dataABytes); n=n+1)
       begin
	 b[n] = rams[n].dataOutA;
	 //dynamicAssert(dataOutValidA[n],"DEBUG: mkBlockRamTrueMixedBE: Reading byte "+integerToString(n)+" from port A but data is not valid");
       end
     return unpack(pack(b));
  endmethod
     
  method dataB dataOutB;
     Vector#(dataBBytes,Bit#(8)) b;
     for(Integer n=0; n<valueOf(dataBBytes); n=n+1)
       begin
	 Bit#(aExtra) bank_select = truncate(pack(save_addrB));
	 Bit#(logdataBBytes) byte_select = fromInteger(n);
	 Bit#(logdataABytes) bram_select = {bank_select, byte_select};
	 b[n] = rams[bram_select].dataOutA;
	 //dynamicAssert(dataOutValidB[n],"DEBUG: mkBlockRamTrueMixedBE: Reading byte "+integerToString(n)+" from port A but data is not valid");
       end
     return unpack(pack(b));
  endmethod  
  
//  method Bool dataOutValidA = fold(\|| , map(getDataOutValidA, rams));
//  method Bool dataOutValidB = fold(\|| , map(getDataOutValidB, rams));
  // just return valid from first RAM since the timing for all of them is the same and all read?
  method Bool dataOutValidA = rams[0].dataOutValidA;
  method Bool dataOutValidB = rams[0].dataOutValidB;

endmodule
	    
endpackage: BlockRAMv
