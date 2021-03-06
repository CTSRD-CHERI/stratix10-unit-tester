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

import Vector  :: *;
import Assert  :: *;
import RegFile :: *;
import DReg    :: *;
import BRAMCore:: *;

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
  method Action putA(Bool we, Bool re, addr a, data d); // initiate read or write or both
  method data dataOutA;                        // read result returned
  method Bool dataOutValidA;                   // True when read result available
  // Port B
  method Action putB(Bool we, Bool re, addr a, data d); // initiate read or write or both
  method data dataOutB;                        // read result returned
  method Bool dataOutValidB;                   // True when read result available
endinterface

//function getDataOutValidA(BlockRamTrueDualPort#(addr,data) ram) = ram.dataOutValidA;
//function getDataOutValidB(BlockRamTrueDualPort#(addr,data) ram) = ram.dataOutValidB;
  

// =====================
// Verilog Instatiations
// =====================

`ifndef SIMULATE
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
`endif


`ifndef SIMULATE
// Verilog true dual-port block RAM for Verilog simulation and synthesis
import "BVI" VerilogBlockRAM_TrueDualPort_OneCycle =
  module mkDualPortBlockRAM_Verilog(BlockRamTrueDualPort#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth));

    parameter ADDR_WIDTH     = valueOf(addrWidth);
    parameter DATA_WIDTH     = valueOf(dataWidth);

    method putA(WE_A, RE_A, ADDR_A, DI_A) enable (EN_A) clocked_by(clk);
    method DO_A dataOutA;
    method DO_VALID_A dataOutValidA;

    method putB(WE_B, RE_B, ADDR_B, DI_B) enable (EN_B) clocked_by(clk);
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
`endif


// ===========================================
// Bluespec module memory primates for Bluesim
// ===========================================

`ifdef SIMULATE
module mkBlockRAM_Bluesim(BlockRam#(addr, data))
  provisos(Bits#(addr, addrWidth),
	   Bits#(data, dataWidth),
	   Bounded#(addr));

  RegFile#(addr, data)    ram <- mkRegFileFull;
  Reg#(data)       dataOutReg <- mkReg(unpack(0));
  Reg#(Bool)  dataOutValidReg <- mkDReg(False);
  
  method Action write(addr a, data d) = ram.upd(a, d);
  method Action read(addr a);
    dataOutReg <= ram.sub(a);
    dataOutValidReg <= True;
  endmethod
  method data dataOut = dataOutReg;
  method Bool dataOutValid = dataOutValidReg;
endmodule
`endif

`ifdef SIMULATE
// True dual port block RAM for simulation only.  Uses BRAMCore library.
module mkDualPortBlockRAM_Bluesim(BlockRamTrueDualPort#(addr, data))
  provisos(Bits#(addr, addrWidth),
	   Bits#(data, dataWidth),
	   Bounded#(addr),
	   Literal#(data));
  
  BRAM_DUAL_PORT#(addr,data) ram <- mkBRAMCore2(valueOf(TExp#(addrWidth)), False);
  Reg#(Bool) dataOutValidAReg <- mkDReg(False);
  Reg#(Bool) dataOutValidBReg <- mkDReg(False);

  method Action putA(Bool we, Bool re, addr a, data d);
    ram.a.put(we, a, d);
    dataOutValidAReg <= re;
  endmethod
  
  method Action putB(Bool we, Bool re, addr a, data d);
    ram.b.put(we, a, d);
    dataOutValidBReg <= re;
  endmethod

  method data dataOutA = ram.a.read;
  method data dataOutB = ram.b.read;

  method Bool dataOutValidA = dataOutValidAReg;
  method Bool dataOutValidB = dataOutValidBReg;
  
endmodule
`endif

/*
`ifdef SIMULATE
// Matt Naylor's dual-port BRAM using RegFile, for simulation only
module mkDualPortBlockRAM_Bluesim_Matt(BlockRamTrueDualPort#(addr, data))
  provisos(Bits#(addr, addrWidth),
	   Bits#(data, dataWidth),
	   Bounded#(addr),
	   Literal#(data));

  RegFile#(addr, data) regFileA <- mkRegFileFull;
  RegFile#(addr, data) regFileB <- mkRegFileFull;
  RegFile#(addr, Bit#(64)) regFileALastWriteTime <- mkRegFileFull;
  RegFile#(addr, Bit#(64)) regFileBLastWriteTime <- mkRegFileFull;
  Reg#(Bit#(64)) timer <- mkReg(64'haaaaaaaaaaaaaaab); // gross hack due to the above RegFiles for LastWriteTime being initialsied to this value
  Reg#(data) dataOutAReg <- mkReg(0);
  Reg#(data) dataOutBReg <- mkReg(0);
  Reg#(Bool) dataOutValidAReg <- mkDReg(False);
  Reg#(Bool) dataOutValidBReg <- mkDReg(False);

  rule updateTimer;
    timer <= timer + 1;
    dynamicAssert(timer < 64'hffffffff_ffffffff,
      "End of timer lifetime.  Panic!");
  endrule

  method Action putA(Bool we, Bool re, addr a, data d);
    if (we)
      begin
	regFileA.upd(a, d);
	regFileALastWriteTime.upd(a, timer);
      end
    dataOutValidAReg <= re;
    dataOutAReg <=
      we && re ? d :  // simulate bypass
      regFileALastWriteTime.sub(a) >= regFileBLastWriteTime.sub(a) ?
        regFileA.sub(a) : regFileB.sub(a);
  endmethod
  method data dataOutA = dataOutAReg;
  method Bool dataOutValidA = dataOutValidAReg;

  method Action putB(Bool we, Bool re, addr a, data d);
    if (we)
      begin
	regFileB.upd(a, d);
	regFileBLastWriteTime.upd(a, timer);
      end
    dataOutValidBReg <= re;
    dataOutBReg <=
        we && re ? d :  // simulate bypass
        regFileALastWriteTime.sub(a) >= regFileBLastWriteTime.sub(a) ?
        regFileA.sub(a) : regFileB.sub(a);
  endmethod
  method data dataOutB = dataOutBReg;
  method Bool dataOutValidB = dataOutValidBReg;

endmodule
`endif
*/

  
// ================================================
// Select memory primative based on simulation mode
// ================================================

module mkBlockRAM(BlockRam#(addr, data))
  provisos(Bits#(addr, addrWidth),
	   Bits#(data, dataWidth),
	   Bounded#(addr));
`ifdef SIMULATE
  BlockRam#(addr,data) ram <- mkBlockRAM_Bluesim;
`else
  BlockRam#(addr,data) ram <- mkBlockRAM_Verilog;
`endif
  method write = ram.write;
  method read = ram.read;
  method dataOut = ram.dataOut;
  method dataOutValid = ram.dataOutValid;
endmodule


module mkDualPortBlockRAM(BlockRamTrueDualPort#(addr, data))
  provisos(Bits#(addr, addrWidth),
	   Bits#(data, dataWidth),
	   Bounded#(addr),
	   Literal#(data));

`ifdef SIMULATE
  BlockRamTrueDualPort#(addr,data) ram <- mkDualPortBlockRAM_Bluesim;
`else
  BlockRamTrueDualPort#(addr,data) ram <- mkDualPortBlockRAM_Verilog;
`endif
  method putA = ram.putA;
  method dataOutA = ram.dataOutA;
  method dataOutValidA = ram.dataOutValidA;
  method putB = ram.putB;
  method dataOutB = ram.dataOutB;
  method dataOutValidB = ram.dataOutValidB;
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
  method Action putA(Bool we, Bool re, addrA a, dataA d);
  method dataA dataOutA;
  method Bool dataOutValidA; // added to original interface to indicate when data is available
  // Port B
  method Action putB(Bool we, Bool re, addrB a, dataB d, Bit#(dataBBytes) be);
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
  Vector#(dataABytes, BlockRamTrueDualPort#(Bit#(awidthA), Bit#(8))) rams <- replicateM(mkDualPortBlockRAM);
  
  // addrB needed during read to select the right word
  Reg#(addrB)           save_addrB <- mkReg(unpack(0));
  Reg#(Bool)      dataOutValidBreg <- mkDReg(False);
  Wire#(Maybe#(addrA)) check_addrA <- mkDWire(Invalid);
  Wire#(Maybe#(addrB)) check_addrB <- mkDWire(Invalid);
  
  // For simulation only. Should be optimised away on FPGA.
  rule assert_no_write_collision(isValid(check_addrA) && isValid(check_addrB));
    Bit#(awidthA) addrA = pack(fromMaybe(?, check_addrA));
    Bit#(awidthA) addrB = truncate(pack(fromMaybe(?, check_addrB))>>valueOf(aExtra));
    dynamicAssert(addrA != addrB, "ERROR in mkBlockRamTrueMixedBE: address collision on two writes");
  endrule
  
  method Action putA(we, re, a, d);
    Bit#(dwidthA) data = pack(d);
    $display("mixed dpram putA: we=%1d  re=%1d", we, re);
    for(Integer n=0; n<valueOf(dataABytes); n=n+1)
	rams[n].putA(we, re, pack(a), data[n*8+7:n*8]);
    if(we) check_addrA <= tagged Valid a;
  endmethod
  
  method Action putB(we, re, a, d, be);
    $display("mixed dpram putB: we=%1d  re=%1d", we, re);
    for(Integer n=0; n<valueOf(dataBBytes); n=n+1)
      begin
	Bit#(aExtra) bank_select = truncate(pack(a));
	Bit#(logdataBBytes) byte_select = fromInteger(n);
	Bit#(logdataABytes) bram_select = {bank_select, byte_select};
	Bit#(awidthA) addr = truncate(unpack(pack(a) >> valueOf(aExtra)));
	Bit#(dwidthB) data = pack(d);
	rams[bram_select].putB(we && (be[n]==1), re, addr, data[n*8+7:n*8]);
	$display("Write to ram[%d]",bram_select);
      end
    save_addrB <= a;
    dataOutValidBreg <= re;
    if(we) check_addrB <= tagged Valid a;
  endmethod
  
  method dataA dataOutA;
    Vector#(dataABytes,Bit#(8)) b;
    for(Integer n=0; n<valueOf(dataABytes); n=n+1)
      begin
	b[n] = rams[n].dataOutA;
// Actions are not possible in none Action methods, so no assertions :(
//	 let v = rams[n].dataOutValidA;
//	 dynamicAssert(v,"ERROR in mkBlockRamTrueMixedBE: Reading byte ");  //+integerToString(n)+" from port A but data is not valid");
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
	b[n] = rams[bram_select].dataOutB;
// Actions are not possible in none Action methods, so no assertions :(
//	 dynamicAssert(rams[n].dataOutValidB,"ERROR in mkBlockRamTrueMixedBE: Reading byte "+integerToString(n)+" from port A but data is not valid");
      end
    return unpack(pack(b));
  endmethod  
  
  method Bool dataOutValidA = rams[0].dataOutValidA;
  method Bool dataOutValidB = dataOutValidBreg;

endmodule
	    
endpackage: BlockRAMv
