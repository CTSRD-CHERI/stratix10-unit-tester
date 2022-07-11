// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) Matthew Naylor, Jon Woodruff

package BlockRam;

// =======
// Imports
// =======

import BRAMCore  :: *;
import Vector    :: *;
import Assert    :: *;
import ConfigReg :: *;

// ==========
// Interfaces
// ==========

// Basic dual-port block RAM with a read port and a write port
(* always_enabled *)
interface BlockRam#(type addr, type data);
  method Action read(addr a);
  method Action write(addr a, data x);
  method data dataOut;
endinterface

// This version provides byte-enables
(* always_enabled *)
interface BlockRamByteEn#(type addr, type data, numeric type dataBytes);
  method Action read(addr a);
  method Action write(addr a, data x, Bit#(dataBytes) be);
  method data dataOut;
endinterface

// Short-hand for byte-enables version
typedef BlockRamByteEn#(addr, data, TDiv#(SizeOf#(data), 8))
  BlockRamBE#(type addr, type data);


// True dual-port mixed-width block RAM
(* always_enabled *)
interface BlockRamTrueMixed#
            (type addrA, type dataA,
             type addrB, type dataB);
  // Port A
  method Action putA(Bool wr, addrA a, dataA x);
  method dataA dataOutA;
  // Port B
  method Action putB(Bool wr, addrB a, dataB x);
  method dataB dataOutB;
endinterface

// True dual-port mixed-width block RAM
(* always_enabled *)
interface BlockRamTrueMixedPadded#
            (type addrA, type dataA,
             type addrB, type dataB,
             numeric type paddedWidthA, numeric type paddedWidthB);
  // Port A
  method Action putA(Bool wr, addrA a, dataA x);
  method dataA dataOutA;
  // Port B
  method Action putB(Bool wr, addrB a, dataB x);
  method dataB dataOutB;
endinterface


// Non-mixed-width variant
typedef BlockRamTrueMixed#(addr, data, addr, data)
  BlockRamTrue#(type addr, type data);

// True dual-port mixed-width block RAM with byte-enables
// (Port B has the byte enables and must be smaller than port A)
(* always_enabled, always_ready *)
interface BlockRamTrueMixedByteEn#
            (type addrA, type dataA,
             type addrB, type dataB,
             numeric type dataBBytes);
  // Port A
  method Action putA(Bool wr, addrA a, dataA x);
  method dataA dataOutA;
  // Port B
  method Action putB(Bool wr, addrB a, dataB x, Bit#(dataBBytes) be);
  method dataB dataOutB;
endinterface

// True dual-port mixed-width block RAM with byte-enables
// (Port B has the byte enables and must be smaller than port A)
(* always_enabled *)
interface BlockRamTrueMixedByteEnPadded#
            (type addrA, type dataA,
             type addrB, type dataB,
             numeric type dataBBytes,
             numeric type paddedWidthA, numeric type paddedWidthB
             );
  // Port A
  method Action putA(Bool wr, addrA a, dataA x);
  method dataA dataOutA;
  // Port B
  method Action putB(Bool wr, addrB a, dataB x, Bit#(dataBBytes) be);
  method dataB dataOutB;
endinterface


// Short-hand for byte-enables version
typedef BlockRamTrueMixedByteEn#(
          addrA, dataA, addrB, dataB, TDiv#(SizeOf#(dataB), 8))
  BlockRamTrueMixedBE#(type addrA, type dataA, type addrB, type dataB);

// =======
// Options
// =======

// For simultaneous read and write to same address,
// read old data or don't care?
typedef enum {
  DontCare, OldData
} ReadDuringWrite deriving (Eq);

// Block RAM options
typedef struct {
  ReadDuringWrite readDuringWrite;

  // Implementation style
  // Defaults to "AUTO", but can be "MLAB" or "M20K"
  String style;

  // Is the data output registered? (i.e. two cycle read latency)
  Bool registerDataOut;

  // If Valid, initialise to file contents
  // If Invalid, initialise to all zeros
  Maybe#(String) initFile;
} BlockRamOpts;

// Default options
BlockRamOpts defaultBlockRamOpts =
  BlockRamOpts {
    readDuringWrite: DontCare,
    //readDuringWrite: OldData,
    style: "AUTO",
    registerDataOut: True,
    initFile: Invalid
  };

// =========================
// Basic dual-port block RAM
// =========================

module mkBlockRam (BlockRam#(addr, data))
    provisos(Bits#(addr, awidth), Bits#(data, dwidth), Bounded#(addr));
  let ram <- mkBlockRamOpts(defaultBlockRamOpts); return ram;
endmodule

// BSV implementation using BRAMCore
module mkBlockRamOpts_SIMULATED#(BlockRamOpts opts) (BlockRam#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth),
                  Bounded#(addr));
  // For simulation, use a BRAMCore
  let ram <-
      mkBRAMCore2Load(valueOf(TExp#(addrWidth)), opts.registerDataOut,
                        fromMaybe("Zero", opts.initFile) + ".hex", False);

  method Action read(addr address);
    ram.a.put(False, address, ?);
  endmethod

  method Action write(addr address, data val);
    ram.b.put(True, address, val);
  endmethod

  method data dataOut = ram.a.read;
endmodule

// to support simulation, we need to define the imported BVI modules - but they should assert
`ifndef SIMULATE

import "BVI" AlteraBlockRam =
  module mkBlockRamOpts_ALTERA#(BlockRamOpts opts) (BlockRam#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth));

    parameter ADDR_WIDTH     = valueOf(addrWidth);
    parameter DATA_WIDTH     = valueOf(TMul#(TDiv#(dataWidth, 8), 8));
    parameter NUM_ELEMS      = valueOf(TExp#(addrWidth));
    parameter BE_WIDTH       = valueOf(TDiv#(dataWidth, 8)); // sx10 has BE for all BRAMs
    parameter RD_DURING_WR =
      opts.readDuringWrite == OldData ? "OLD_DATA" : "DONT_CARE";
    parameter DO_REG         =
      opts.registerDataOut ? "CLOCK0" : "UNREGISTERED";
    parameter INIT_FILE      =
      case (opts.initFile) matches
        tagged Invalid: return "UNUSED";
        tagged Valid .str: return (str + ".mif");
      endcase;
    parameter DEV_FAMILY = `DeviceFamily;
    parameter STYLE = opts.style;

    method read(RD_ADDR) enable (RE) clocked_by(clk);
    method write(WR_ADDR, DI) enable (WE) clocked_by(clk);
    method DO dataOut;

    port BE clocked_by(clk) = ~0;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOut) CF (dataOut);
    schedule (dataOut) CF (read);
    schedule (dataOut) CF (write);
    schedule (read)    CF (write);
    schedule (write)   C  (write);
    schedule (read)    C  (read);
  endmodule

`else

module mkBlockRamOpts_ALTERA#(BlockRamOpts opts) (BlockRam#(addr, data));
  staticAssert(False, "Altera BVI module used in sim enviroment.");
endmodule

`endif

`ifdef SIMULATE

module mkBlockRamOpts#(BlockRamOpts opts) (BlockRam#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth),
                  Bounded#(addr));
  // For simulation, use a BRAMCore
  BlockRam#(addr, data) bram <- mkBlockRamOpts_SIMULATED(opts);
  return bram;
endmodule

`else

// Altera implementation
module mkBlockRamOpts#(BlockRamOpts opts) (BlockRam#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth),
                  Bounded#(addr));
  // For simulation, use a BRAMCore
  BlockRam#(addr, data) bram <- mkBlockRamOpts_ALTERA(opts);
  return bram;
endmodule

`endif

// ===========================================
// Basic dual-port block RAM with byte-enables
// ===========================================

module mkBlockRamBE (BlockRamByteEn#(addr, data, dataBytes))
    provisos(Bits#(addr, awidth), Bits#(data, dwidth),
             Bounded#(addr), Mul#(dataBytes, 8, dwidth),
             Div#(dwidth, dataBytes, 8));
  BlockRamByteEn#(addr, data, dataBytes) ram <- mkBlockRamBEOpts(defaultBlockRamOpts); return ram;
endmodule

// BSV implementation using BRAMCore
module mkBlockRamBEOpts_SIMULATED#(BlockRamOpts opts)
         (BlockRamByteEn#(addr, data, dataBytes))
         provisos(Bits#(addr, addrWidth), Bits#(data, dataWidth),
                  Bounded#(addr), Mul#(dataBytes, 8, dataWidth),
                  Div#(dataWidth, dataBytes, 8));
  // For simulation, use a BRAMCore
  let ram <-
      mkBRAMCore2BELoad(valueOf(TExp#(addrWidth)), opts.registerDataOut,
                          fromMaybe("Zero", opts.initFile) + ".hex", False);

  method Action read(addr address);
    ram.a.put(0, address, ?);
  endmethod

  method Action write(addr address, data val, Bit#(dataBytes) be);
    ram.b.put(be, address, val);
  endmethod

  method data dataOut = ram.a.read;
endmodule

`ifndef SIMULATE

// Altera implementation
import "BVI" AlteraBlockRam =
  module mkBlockRamBEOpts_ALTERA#(BlockRamOpts opts)
         (BlockRamByteEn#(addr, data, dataBytes))
         provisos(Bits#(addr, addrWidth), Bits#(data, dataWidth),
                  Bounded#(addr), Mul#(dataBytes, 8, dataWidth),
                  Div#(dataWidth, dataBytes, 8));

    parameter ADDR_WIDTH     = valueOf(addrWidth);
    parameter DATA_WIDTH     = valueOf(dataWidth);
    parameter NUM_ELEMS      = valueOf(TExp#(addrWidth));
    parameter BE_WIDTH       = valueOf(dataBytes);
    parameter RD_DURING_WR =
      opts.readDuringWrite == OldData ? "OLD_DATA" : "DONT_CARE";
    parameter DO_REG         =
      opts.registerDataOut ? "CLOCK0" : "UNREGISTERED";
    parameter INIT_FILE      =
      case (opts.initFile) matches
        tagged Invalid: return "UNUSED";
        tagged Valid .x: return (x + ".mif");
      endcase;
    parameter DEV_FAMILY = `DeviceFamily;
    parameter STYLE = opts.style;

    method read(RD_ADDR) enable (RE) clocked_by(clk);
    method write(WR_ADDR, DI, BE) enable (WE) clocked_by(clk);
    method DO dataOut;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOut) CF (dataOut);
    schedule (dataOut) CF (read);
    schedule (dataOut) CF (write);
    schedule (read)    CF (write);
    schedule (write)   C  (write);
    schedule (read)    C  (read);
  endmodule

`else

module mkBlockRamBEOpts_ALTERA#(BlockRamOpts opts) (BlockRam#(addr, data));
  staticAssert(False, "Altera BVI module used in sim enviroment.");
endmodule

`endif


`ifdef SIMULATE

module mkBlockRamBEOpts#(BlockRamOpts opts)
         (BlockRamByteEn#(addr, data, dataBytes))
         provisos(Bits#(addr, addrWidth), Bits#(data, dataWidth),
                  Bounded#(addr), Mul#(dataBytes, 8, dataWidth),
                  Div#(dataWidth, dataBytes, 8));
  // For simulation, use a BRAMCore
  BlockRamByteEn#(addr, data, dataBytes) ram <- mkBlockRamBEOpts_SIMULATED(opts);
  return ram;
endmodule

`else

module mkBlockRamBEOpts#(BlockRamOpts opts)
         (BlockRamByteEn#(addr, data, dataBytes))
         provisos(Bits#(addr, addrWidth), Bits#(data, dataWidth),
                  Bounded#(addr), Mul#(dataBytes, 8, dataWidth),
                  Div#(dataWidth, dataBytes, 8));
  // For simulation, use a BRAMCore
  BlockRamByteEn#(addr, data, dataBytes) ram <- mkBlockRamBEOpts_ALTERA(opts);
  return ram;
endmodule

`endif



// ====================================
// True dual-port mixed-width block RAM
// ====================================

module mkBlockRamTrueMixed
         (BlockRamTrueMixed#(addrA, dataA, addrB, dataB))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
                  Literal#(addrA), Literal#(addrB)

                  `ifdef Stratix10
                  , Div#(TMul#(TDiv#(dataWidthA, 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8), 8),
                  Add#(a__, dataWidthA, TMul#(TDiv#(dataWidthA, 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), 8, TDiv#(dataWidthA, 8)),
                  Add#(b__, TMul#(TDiv#(dataWidthB, 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                  Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(dataWidthB, 8), 8),TExp#(aExtra)),
                  Add#(c__, dataWidthB, TMul#(TDiv#(dataWidthB, 8), 8)),
                  Mul#(TDiv#(dataWidthB, 8), TExp#(aExtra), TDiv#(dataWidthA, 8)),
                  Mul#(TDiv#(dataWidthA, dataWidthB), dataWidthB, dataWidthA),
                  Add#(d__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8))
                  `endif // Stratix10

                 );
  let ram <- mkBlockRamTrueMixedOpts(defaultBlockRamOpts); return ram;
endmodule

// BSV implementation using BlockRam.c routines.
typedef Bit#(64) BlockRamHandle;
import "BDPI" function ActionValue#(BlockRamHandle) createBlockRam(
  Bit#(32) sizeInBits);
import "BDPI" function Action blockRamWrite(
  BlockRamHandle handle, Bit#(m) addr, Bit#(n) data,
    Bit#(32) dataWidth, Bit#(32) addrWidth);
import "BDPI" function ActionValue#(Bit#(n)) blockRamRead(
  BlockRamHandle handle, Bit#(m) addr,
    Bit#(32) dataWidth, Bit#(32) addrWidth);

module mkBlockRamTrueMixedOpts_SIMULATE#(BlockRamOpts opts)
         (BlockRamTrueMixed#(addrA, dataA, addrB, dataB))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Mul#(TExp#(aExtra), dataWidthB, dataWidthA));
  // For simulation, use C interface
  Bit#(32) sizeInBits = fromInteger(2**valueOf(addrWidthA) *
                                       valueOf(dataWidthA));
  Bit#(32) addrWidthAInt = fromInteger(valueOf(addrWidthA));
  Bit#(32) addrWidthBInt = fromInteger(valueOf(addrWidthB));
  Bit#(32) dataWidthAInt = fromInteger(valueOf(dataWidthA));
  Bit#(32) dataWidthBInt = fromInteger(valueOf(dataWidthB));
  staticAssert(! isValid(opts.initFile), "Initialistion not supported");

  // State
  Reg#(BlockRamHandle) ramReg <- mkReg(0);
  Reg#(dataA) dataAReg1 <- mkConfigRegU;
  Reg#(dataA) dataAReg2 <- mkConfigRegU;
  Reg#(dataB) dataBReg1 <- mkConfigRegU;
  Reg#(dataB) dataBReg2 <- mkConfigRegU;

  // Wires
  Wire#(BlockRamHandle) ram <- mkBypassWire;

  // Rules
  rule create;
    BlockRamHandle h = ramReg;
    if (h == 0) begin
      h <- createBlockRam(sizeInBits);
      ramReg <= h;
    end
    ram <= h;
  endrule

  rule update;
    dataAReg2 <= dataAReg1;
    dataBReg2 <= dataBReg1;
  endrule

  // Port A
  method Action putA(Bool wr, addrA address, dataA x);
    if (wr) begin
      blockRamWrite(ram, pack(address), pack(x),
                      dataWidthAInt, addrWidthAInt);
      dataAReg1 <= x;
    end else begin
      let out <- blockRamRead(ram, pack(address),
                                dataWidthAInt, addrWidthAInt);
      dataAReg1 <= unpack(out);
    end
  endmethod

  method dataA dataOutA = opts.registerDataOut ? dataAReg2 : dataAReg1;

  // Port B
  method Action putB(Bool wr, addrB address, dataB x);
    if (wr) begin
      blockRamWrite(ram, pack(address), pack(x),
                      dataWidthBInt, addrWidthBInt);
      dataBReg1 <= x;
    end else begin
      let out <- blockRamRead(ram, pack(address),
                                dataWidthBInt, addrWidthBInt);
      dataBReg1 <= unpack(out);
    end
  endmethod

  method dataB dataOutB = opts.registerDataOut ? dataBReg2 : dataBReg1;

endmodule

`ifndef SIMULATE
// define the IP wrappers. s10 has additional conditions relative to sV
import "BVI" AlteraBlockRamTrueMixed =
  module mkBlockRamMaybeTrueMixedOpts_ALTERA#(BlockRamOpts opts)
         (BlockRamTrueMixed#(addrA, dataA, addrB, dataB))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB)
                  `ifdef Stratix10
                  , Add#(0, dataWidthA, dataWidthB) // s10 requirement; equal sized dual ports!
                  `endif // s10
                  );

    parameter ADDR_WIDTH_A = valueOf(addrWidthA);
    parameter ADDR_WIDTH_B = valueOf(addrWidthB);
    parameter DATA_WIDTH_A = valueOf(dataWidthA);
    parameter DATA_WIDTH_B = valueOf(dataWidthB);
    parameter NUM_ELEMS_A  = valueOf(TExp#(addrWidthA));
    parameter NUM_ELEMS_B  = valueOf(TExp#(addrWidthB));
    parameter RD_DURING_WR =
      opts.readDuringWrite == OldData ? "OLD_DATA" : "DONT_CARE";
    parameter DO_REG_A       =
      opts.registerDataOut ? "CLOCK0" : "UNREGISTERED";
    parameter DO_REG_B       =
      opts.registerDataOut ? "CLOCK0" : "UNREGISTERED";
    parameter INIT_FILE      =
      case (opts.initFile) matches
        tagged Invalid: return "UNUSED";
        tagged Valid .x: return (x + ".mif");
      endcase;
    parameter DEV_FAMILY = `DeviceFamily;
    parameter STYLE = opts.style;

    // Port A
    method putA(WE_A, ADDR_A, DI_A) enable (EN_A) clocked_by(clk);
    method DO_A dataOutA;

    // Port B
    method putB(WE_B, ADDR_B, DI_B) enable (EN_B) clocked_by(clk);
    method DO_B dataOutB;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOutA, dataOutB) CF (dataOutA, dataOutB, putA, putB);
    schedule (putA)               CF (putB);
    schedule (putA)               C  (putA);
    schedule (putB)               C  (putB);
  endmodule



`else

module mkBlockRamMaybeTrueMixedOpts_ALTERA#(BlockRamOpts opts) (BlockRam#(addr, data));
  staticAssert(False, "Altera BVI module used in sim enviroment.");
endmodule

`endif

// In order to work around the proviso match restrictions, this module calculates the required padding to build a
// arbitary width bram packed into a byte-alligned store
module mkBlockRamTrueMixedOpts_S10#(BlockRamOpts opts)
         (BlockRamTrueMixed#(addrA, dataA, addrB, dataB))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Literal#(addrA), Literal#(addrB),

                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8), 8),
                  Add#(a__, dataWidthA, TMul#(TDiv#(dataWidthA, 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), 8, TDiv#(dataWidthA, 8)),
                  Add#(b__, TMul#(TDiv#(dataWidthB, 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                  Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(dataWidthB, 8), 8),TExp#(aExtra)),
                  Add#(c__, dataWidthB, TMul#(TDiv#(dataWidthB, 8), 8)),
                  Mul#(TDiv#(dataWidthB, 8), TExp#(aExtra), TDiv#(dataWidthA, 8)),

                  Mul#(TDiv#(dataWidthA, dataWidthB), dataWidthB, dataWidthA),
                  Add#(d__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8))

                 );

  BlockRamTrueMixedPadded#(addrA, dataA, addrB, dataB,
                           TMul#(TDiv#(SizeOf#(dataA), 8), 8),
                           TMul#(TDiv#(SizeOf#(dataB), 8), 8)
                          ) bram <- mkBlockRamTrueMixedOptsPadded_S10(opts);

  method Action putA(Bool wr, addrA a, dataA x);
    bram.putA(wr, a, x);
  endmethod

  method dataA dataOutA;
    return bram.dataOutA;
  endmethod

  method Action putB(Bool wr, addrB a, dataB x);
    bram.putB(wr, a, x);
  endmethod

  method dataB dataOutB;
    return bram.dataOutB;
  endmethod

endmodule

// If s10, we need to add width adaptors to get a true dual port
module mkBlockRamTrueMixedOptsPadded_S10#(BlockRamOpts opts)
  (BlockRamTrueMixedPadded#(addrA, dataA, addrB, dataB, paddedWidthA, paddedWidthB))

  provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
           Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
           Bounded#(addrA), Bounded#(addrB),
           Add#(addrWidthA, aExtra, addrWidthB),
           Mul#(TExp#(aExtra), paddedWidthB, paddedWidthA), // we only care the padded widths add up
           Literal#(addrA), Literal#(addrB),

           // Mul#(TAdd#(bpadding, dataWidthB), TExp#(aExtra), TAdd#(apadding, dataWidthA)),

           Add#(apadding, dataWidthA, paddedWidthA), Add#(bpadding, dataWidthB, paddedWidthB), // define padding
           Max#(bpadding, 7, 7), Max#(apadding, 7, 7), // constrain to the smallest possible padding
           Mul#(TDiv#(paddedWidthA, 8), 8, paddedWidthA), Mul#(TDiv#(paddedWidthB, 8), 8, paddedWidthB), // enforce padded width % 8 == 0
           Div#(paddedWidthA, 8, paddedBytesA), Div#(paddedWidthB, 8, paddedBytesB), // byte counts for the padded backing store
           Mul#(paddedBytesB, 8, paddedWidthB), Mul#(paddedBytesA, 8, paddedWidthA),

           // compiler generated provisos I don't understand yet...
           Div#(paddedWidthA, paddedWidthB, TExp#(aExtra)),
           Div#(paddedWidthA, TDiv#(paddedWidthA, 8), 8),
           Add#(TDiv#(paddedaExtra, 8), TDiv#(paddedWidthB, 8), TDiv#(paddedWidthA, 8)),
           Add#(paddedaExtra, paddedWidthB, paddedWidthA),
           Div#(dataWidthA, dataWidthB, widthRatio),
           Mul#(widthRatio, dataWidthB, dataWidthA),
           Div#(paddedWidthA, 8, TDiv#(dataWidthA, 8)),
           Add#(a__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8))

          );

  `ifdef SIMULATE
  BlockRamTrueMixedByteEn#(addrA, Bit#(paddedWidthA), // port A
                           addrA, Bit#(paddedWidthA), // port B
                           TDiv#(paddedWidthA, 8) // Port B byte enables width
                          ) bram <- mkBlockRamTrueMixedBEOpts_SIMULATE(opts);
  `else
  BlockRamTrueMixedByteEn#(addrA, Bit#(paddedWidthA), // port A
                           addrA, Bit#(paddedWidthA), // port B
                           TDiv#(paddedWidthA, 8) // Port B byte enables width
                          ) bram <- mkBlockRamMaybeTrueMixedBEOpts_ALTERA(opts);
  `endif

  Wire#(addrB) baddr_1 <- mkConfigRegU();
  Wire#(addrB) baddr_2 <- mkConfigRegU();
  Wire#(dataB) bout <- mkDWire(?);

  rule move;
    baddr_2 <= baddr_1;
  endrule

  rule calc_outdata;
    let idx = pack(opts.registerDataOut ? baddr_2 : baddr_1) % fromInteger(valueOf(widthRatio));
    Bit#(paddedWidthA) x_packed = bram.dataOutB;
    Vector#(widthRatio, Bit#(paddedWidthB)) xv_b = unpack(x_packed);
    dataB x = unpack(truncate(xv_b[idx]));
    // $display($time, " BRAM fakemixed pB reading from addr ", opts.registerDataOut ? baddr_2 : baddr_1,
    //          " data type A intep as vec of B %x", xv_b,
    //          " with shifted data %x", x, " from internal idx ", idx );
    // for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
    //   $display($time, "xv_b[",elab_idx, "]=%x", xv_b[elab_idx]);
    // end
    bout <= x;
  endrule

  // A, the wide side, is trivial
  method Action putA(Bool wr, addrA addr, dataA data_a);
    // $display($time, " BRAM fakemixed pA got req for addr ", a, " data %x", x);

    // need to pack A intyo a vec of b's, in order to allign to the byte enables
    Vector#(widthRatio, Bit#(dataWidthB)) data_a_bvec = unpack(pack(data_a));
    Vector#(widthRatio, Bit#(paddedWidthB)) data_a_padded_bvec = unpack(0);
    for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
      data_a_padded_bvec[elab_idx] = zeroExtend(data_a_bvec[elab_idx]);
    end
    //
    // for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
    //   $display($time, "data_a_padded_bvec[",elab_idx, "]=%x", data_a_padded_bvec[elab_idx]);
    // end


    Bit#(paddedWidthA) data_packed = pack(data_a_padded_bvec);
    bram.putA(wr, addr, data_packed);
  endmethod

  method dataA dataOutA();
    Vector#(widthRatio, Bit#(paddedWidthB)) data_a_padded_bvec = unpack(bram.dataOutA);
    Vector#(widthRatio, Bit#(dataWidthB)) data_a_bvec = unpack(0);
    for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
      data_a_bvec[elab_idx] = truncate(data_a_padded_bvec[elab_idx]);
    end

    return unpack(pack(data_a_bvec));
  endmethod

  method Action putB(Bool wr, addrB addr_into_b, dataB x);
    // // the port is sizeOf(A) wide; we can enable 8 bits at a time by setting b_enables
    // calculate the effective address;
    baddr_1 <= addr_into_b;
    let idx = pack(addr_into_b) % fromInteger(valueOf(widthRatio));
    addrA addr_into_a = unpack(truncateLSB(pack(addr_into_b)));

    Bit#(TDiv#(dataWidthB, 8)) b_lane_base_mask = fromInteger(2**(valueOf(paddedWidthB)/8)-1); // all ones vector the width of dataB in bytes
    Bit#(TDiv#(dataWidthA, 8)) b_enables = zeroExtend(b_lane_base_mask) << (idx*(fromInteger(valueOf(paddedWidthB))/8)); // good

    // Vector#(widthRatio, dataB) xv_b = unpack(0);
    Vector#(widthRatio, Bit#(paddedWidthB)) xv_padded = unpack(0);
    xv_padded[idx] = zeroExtend(pack(x));

    // for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
    //   x_padded[elab_idx] = zeroExtend(xv_b[elab_idx]);
    //   $display($time, " write x_padded[",elab_idx, "]=%x", x_padded[elab_idx]);
    // end
    //
    // xv_b[idx] = x;
    // for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
    //   $display($time, " write xv_b[",elab_idx, "]=%x", xv_b[elab_idx]);
    // end


    Bit#(paddedWidthA) x_buffer = pack(xv_padded);
    // need to move the B data into the correct portion
    // $display($time, " BRAM fakemixed pB got req for addr ", addr_into_b,
    //                 " data %x", x, " and will write to addr ", addr_into_a,
    //                 " packed data %x", x_buffer, " BE: %b", b_enables, " b idx ", idx);
    bram.putB(wr, addr_into_a, unpack(x_buffer), b_enables);
  endmethod

  method dataB dataOutB;
    return bout;
  endmethod

endmodule


`ifdef Stratix10

module mkBlockRamTrueMixedOpts#(BlockRamOpts opts)
  (BlockRamTrueMixed#(addrA, dataA, addrB, dataB))

  provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
           Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
           Bounded#(addrA), Bounded#(addrB),
           Add#(addrWidthA, aExtra, addrWidthB),
           Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
           Literal#(addrA), Literal#(addrB),
           Div#(TMul#(TDiv#(dataWidthA, 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8), 8),
           Add#(a__, dataWidthA, TMul#(TDiv#(dataWidthA, 8), 8)),
           Div#(TMul#(TDiv#(dataWidthA, 8), 8), 8, TDiv#(dataWidthA, 8)),
           Add#(b__, TMul#(TDiv#(dataWidthB, 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
           Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
           Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(dataWidthB, 8), 8),TExp#(aExtra)),
           Add#(c__, dataWidthB, TMul#(TDiv#(dataWidthB, 8), 8)),
           Mul#(TDiv#(dataWidthB, 8), TExp#(aExtra), TDiv#(dataWidthA, 8)),

           Mul#(TDiv#(dataWidthA, dataWidthB), dataWidthB, dataWidthA),
           Add#(d__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8))


          );

  BlockRamTrueMixed#(addrA, dataA, addrB, dataB) bram <- mkBlockRamTrueMixedOpts_S10(opts);
  return bram;
endmodule

`endif // s10

`ifdef StratixV
// No adaptors needed; mixed width is natively supported

module mkBlockRamTrueMixedOpts#(BlockRamOpts opts)
  (BlockRamTrueMixed#(addrA, dataA, addrB, dataB))

  provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
           Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
           Bounded#(addrA), Bounded#(addrB),
           Add#(addrWidthA, aExtra, addrWidthB),
           Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
           Literal#(addrA), Literal#(addrB)
          );

  `ifdef SIMULATE
  BlockRamTrueMixed#(addrA, dataA, addrB, dataB) bram <- mkBlockRamMaybeTrueMixedOpts_ALTERA(opts);
  `else // not SIMULATE
  BlockRamTrueMixed#(addrA, dataA, addrB, dataB) bram <- mkBlockRamMaybeTrueMixedOpts_SIMULATE(opts);
  `endif // not SIMULATE

  return bram;
endmodule

`endif // StratixV

// ======================================================
// True dual-port mixed-width block RAM with byte-enables
// ======================================================

module mkBlockRamTrueMixedBE
         (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
                  Mul#(dataBBytes, 8, dataWidthB),
                  Div#(dataWidthB, dataBBytes, 8),
                  Mul#(dataABytes, 8, dataWidthA),
                  Div#(dataWidthA, dataABytes, 8),
                  Mul#(TExp#(aExtra), dataBBytes, dataABytes)

                  `ifdef Stratix10
                   , Literal#(addrA), Literal#(addrB),
                   // Div#(dataWidthA, 8, dataBBytes),

                   Div#(TMul#(TDiv#(dataWidthA, 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8), 8),
                   Add#(a__, dataWidthA, TMul#(TDiv#(dataWidthA, 8), 8)),
                   Div#(TMul#(TDiv#(dataWidthA, 8), 8), 8, TDiv#(dataWidthA, 8)),
                   Add#(b__, TMul#(TDiv#(dataWidthB, 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                   Mul#(TDiv#(dataWidthB, 8), TExp#(aExtra), TDiv#(dataWidthA, 8)),

                   Mul#(TDiv#(dataWidthA, dataWidthB), dataWidthB, dataWidthA),
                   Add#(d__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8)),
                   Mul#(TDiv#(dataWidthA, TMul#(dataBBytes, 8)), TMul#(dataBBytes, 8), dataWidthA),
                   Add#(e__, TDiv#(TMul#(dataBBytes, 8), 8), TDiv#(dataWidthA, 8)),
                   Add#(f__, TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                   Add#(TDiv#(f__, 8), TDiv#(TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                   Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), TExp#(aExtra)),
                   Add#(g__, TMul#(dataBBytes, 8), TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8)),
                   Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                   Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                   Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(dataWidthB, 8), 8), TExp#(aExtra)),
                   Add#(c__, dataWidthB, TMul#(TDiv#(dataWidthB, 8), 8))
                  `endif // Stratix10
                );

  BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes) ram <- mkBlockRamTrueMixedBEOpts(defaultBlockRamOpts);
  return ram;
endmodule

// BSV implementation using BRAMCore
module mkBlockRamTrueMixedBEOpts_SIMULATE#(BlockRamOpts opts)
         (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
                  Mul#(dataBBytes, 8, dataWidthB),
                  Div#(dataWidthB, dataBBytes, 8),
                  Mul#(dataABytes, 8, dataWidthA),
                  Div#(dataWidthA, dataABytes, 8),
                  Mul#(TExp#(aExtra), dataBBytes, dataABytes));
  // For simulation, use a BRAMCore
  BRAM_DUAL_PORT_BE#(addrA, dataA, dataABytes) ram <-
      mkBRAMCore2BELoad(valueOf(TExp#(addrWidthA)), False,
                          fromMaybe("Zero", opts.initFile) + ".hex", False);

  // State
  Reg#(dataA) dataAReg <- mkConfigRegU;
  Reg#(dataA) dataBReg <- mkConfigRegU;
  Reg#(Bit#(aExtra)) offsetB1 <- mkConfigRegU;
  Reg#(Bit#(aExtra)) offsetB2 <- mkConfigRegU;

  // Rules
  rule update;
    offsetB2 <= offsetB1;
    dataAReg <= ram.a.read;
    dataBReg <= ram.b.read;
  endrule

  // Port A
  method Action putA(Bool wr, addrA address, dataA x);
    // $display("BRAM BE SIM pA writing ", x, " to addr ", address);
    ram.a.put(wr ? -1 : 0, address, x);
  endmethod

  method dataA dataOutA = opts.registerDataOut ? dataAReg : ram.a.read;

  // Port B
  method Action putB(Bool wr, addrB address, dataB val, Bit#(dataBBytes) be);
    // $display("BRAM BE SIM pB writing ", val, " to addr ", address);
    Bit#(aExtra) offset = truncate(pack(address));
    offsetB1 <= offset;
    Bit#(addrWidthA) addr = truncateLSB(pack(address));
    Bit#(dataWidthA) vals = pack(replicate(val));
    Vector#(TExp#(aExtra), Bit#(dataBBytes)) paddedBE;
    for (Integer i = 0; i < valueOf(TExp#(aExtra)); i=i+1)
      paddedBE[i] = (offset == fromInteger(i)) ? be : unpack(0);
    ram.b.put(wr ? pack(paddedBE) : 0, unpack(addr), unpack(vals));
  endmethod

  method dataB dataOutB;
    Vector#(TExp#(aExtra), dataB) vec = unpack(pack(
      opts.registerDataOut ? dataBReg : ram.b.read));
    return vec[opts.registerDataOut ? offsetB2 : offsetB1];
  endmethod
endmodule

`ifndef SIMULATE
// Altera implementation
import "BVI" AlteraBlockRamTrueMixedBE =
  module mkBlockRamMaybeTrueMixedBEOpts_ALTERA#(BlockRamOpts opts) // mkBlockRamTrueMixedBEOpts_EQUALONLY
         (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Mul#(dataBBytes, 8, dataWidthB),
                  Div#(dataWidthB, dataBBytes, 8)
                  `ifdef Stratix10
                  , Add#(0, dataWidthA, dataWidthB) // s10 requirement; equal sized dual ports!
                  `endif // Stratix10
                 );

    parameter ADDR_WIDTH_A = valueOf(addrWidthA);
    parameter ADDR_WIDTH_B = valueOf(addrWidthB);
    parameter DATA_WIDTH_A = valueOf(dataWidthA);
    parameter DATA_WIDTH_B = valueOf(dataWidthB);
    parameter NUM_ELEMS_A  = valueOf(TExp#(addrWidthA));
    parameter NUM_ELEMS_B  = valueOf(TExp#(addrWidthB));
    parameter BE_WIDTH = valueOf(dataBBytes);
    parameter RD_DURING_WR =
      opts.readDuringWrite == OldData ? "OLD_DATA" : "DONT_CARE";
    parameter DO_REG_A       =
      opts.registerDataOut ? "CLOCK0" : "UNREGISTERED";
    parameter DO_REG_B       =
      opts.registerDataOut ? "CLOCK0" : "UNREGISTERED";
    parameter INIT_FILE      =
      case (opts.initFile) matches
        tagged Invalid: return "UNUSED";
        tagged Valid .x: return (x + ".mif");
      endcase;
    parameter DEV_FAMILY = `DeviceFamily;
    parameter STYLE = opts.style;

    // Port A
    method putA(WE_A, ADDR_A, DI_A) enable (EN_A) clocked_by(clk);
    method DO_A dataOutA;

    // Port B
    method putB(WE_B, ADDR_B, DI_B, BE_B) enable (EN_B) clocked_by(clk);
    method DO_B dataOutB;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOutA, dataOutB) CF (dataOutA, dataOutB, putA, putB);
    schedule (putA)               CF (putB);
    schedule (putA)               C  (putA);
    schedule (putB)               C  (putB);
  endmodule

// define the IP wrappers. s10 has additional conditions relative to sV
import "BVI" AlteraBlockRamTrueBEInfer =
  module mkBlockRamMaybeTrueMixedBEOpts_ALTERA_Inferred#(BlockRamOpts opts)
        (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
        provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                 Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                 Bounded#(addrA), Bounded#(addrB),
                 Mul#(dataBBytes, 8, dataWidthB),
                 Div#(dataWidthB, dataBBytes, 8)
                 `ifdef Stratix10
                 , Add#(0, dataWidthA, dataWidthB) // s10 requirement; equal sized dual ports!
                 `endif // Stratix10
                );
    staticAssert(opts.readDuringWrite == DontCare, "Inferred dual port RAM does not support defined RdW behaviour.");
    staticAssert(opts.registerDataOut == False, "Inferred dual port RAM does not support reg data out.");
    staticAssert(opts.initFile == tagged Invalid, "Inferred dual port RAM does not support init file (yet).");
    // parameter INIT_FILE      =
    //   case (opts.initFile) matches
    //     tagged Invalid: return "UNUSED";
    //     tagged Valid .x: return (x + ".mif");
    //   endcase;
    staticAssert(opts.style == "AUTO", "Inferred dual port RAM does not support defining a style.");

    parameter ADDRESS_WIDTH = valueOf(addrWidthA);
    parameter BYTES = valueOf(dataWidthA)/8;
    parameter BYTE_WIDTH = 8; // does not infer if not a mul of 8

    // Port A
    method putA(we1, addr1, data_in1) enable((* inhigh *) EN_A) clocked_by(clk);
    method data_out1 dataOutA;

    // Port B
    method putB(we2, addr2, data_in2, be2) enable((* inhigh *) EN_B) clocked_by(clk);
    method data_out2 dataOutB;

    default_clock clk(clk, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOutA, dataOutB) CF (dataOutA, dataOutB, putA, putB);
    schedule (putA)               CF (putB);
    schedule (putA)               C  (putA);
    schedule (putB)               C  (putB);
  endmodule


`else

module mkBlockRamMaybeTrueMixedBEOpts_ALTERA#(BlockRamOpts opts) (BlockRam#(addr, data));
  staticAssert(False, "Altera BVI module used in sim enviroment.");
endmodule

`endif


// In order to work around the proviso match restrictions, this module calculates the required padding to build a
// arbitary width bram packed into a byte-alligned store
module mkBlockRamTrueMixedBEOpts_S10#(BlockRamOpts opts)
         (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Literal#(addrA), Literal#(addrB),
                  Div#(dataWidthB, 8, dataBBytes),

                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8), 8),
                  Add#(a__, dataWidthA, TMul#(TDiv#(dataWidthA, 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), 8, TDiv#(dataWidthA, 8)),
                  Add#(b__, TMul#(TDiv#(dataWidthB, 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                  Mul#(TDiv#(dataWidthB, 8), TExp#(aExtra), TDiv#(dataWidthA, 8)),

                  Mul#(TDiv#(dataWidthA, dataWidthB), dataWidthB, dataWidthA),
                  Add#(d__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8)),
                  Mul#(TDiv#(dataWidthA, TMul#(dataBBytes, 8)), TMul#(dataBBytes, 8), dataWidthA),
                  Add#(e__, TDiv#(TMul#(dataBBytes, 8), 8), TDiv#(dataWidthA, 8)),
                  Add#(f__, TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                  Add#(TDiv#(f__, 8), TDiv#(TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), TExp#(aExtra)),
                  Add#(g__, TMul#(dataBBytes, 8), TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8)),
                  Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(dataWidthB, 8), 8), TExp#(aExtra)),
                  Add#(c__, dataWidthB, TMul#(TDiv#(dataWidthB, 8), 8))

                 );

  BlockRamTrueMixedByteEnPadded#(addrA, dataA, addrB, dataB,
                           dataBBytes,
                           TMul#(TDiv#(SizeOf#(dataA), 8), 8),
                           TMul#(TDiv#(SizeOf#(dataB), 8), 8)
                          ) bram <- mkBlockRamTrueMixedBEOptsPadded_S10(opts);

    method Action putA(Bool wr, addrA a, dataA x);
      bram.putA(wr, a, x);
    endmethod

    method dataA dataOutA;
      return bram.dataOutA;
    endmethod

    method Action putB(Bool wr, addrB a, dataB x, Bit#(dataBBytes) be);
      bram.putB(wr, a, x, be);
    endmethod

    method dataB dataOutB;
      return bram.dataOutB;
    endmethod

endmodule

module mkBlockRamTrueMixedBEOptsPadded_S10#(BlockRamOpts opts)
  (BlockRamTrueMixedByteEnPadded#(addrA, dataA, addrB, dataB, dataBBytes, paddedWidthA, paddedWidthB))

  provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
           Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
           Bounded#(addrA), Bounded#(addrB),
           Add#(addrWidthA, aExtra, addrWidthB),
           Mul#(TExp#(aExtra), paddedWidthB, paddedWidthA), // we only care the padded widths add up
           Literal#(addrA), Literal#(addrB),
           Mul#(dataBBytes, 8, dataWidthB),

           Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
           Add#(apadding, dataWidthA, paddedWidthA), Add#(bpadding, dataWidthB, paddedWidthB), // define padding
           Max#(bpadding, 7, 7), Max#(apadding, 7, 7), // constrain to the smallest possible padding
           Mul#(TDiv#(paddedWidthA, 8), 8, paddedWidthA), Mul#(TDiv#(paddedWidthB, 8), 8, paddedWidthB), // enforce padded width % 8 == 0
           Div#(paddedWidthA, 8, paddedBytesA), Div#(paddedWidthB, 8, paddedBytesB), // byte counts for the padded backing store
           Mul#(paddedBytesB, 8, paddedWidthB), Mul#(paddedBytesA, 8, paddedWidthA),
           Bits#(Vector::Vector#(widthRatio, Bit#(paddedWidthB)), paddedWidthA),
           Div#(dataWidthB, 8, dataBBytes),

           // compiler generated provisos I don't understand yet...
           Div#(paddedWidthA, paddedWidthB, TExp#(aExtra)),
           Div#(paddedWidthA, TDiv#(paddedWidthA, 8), 8),
           Add#(TDiv#(paddedaExtra, 8), TDiv#(paddedWidthB, 8), TDiv#(paddedWidthA, 8)),
           Add#(paddedaExtra, paddedWidthB, paddedWidthA),
           Div#(dataWidthA, dataWidthB, widthRatio),
           Mul#(widthRatio, dataWidthB, dataWidthA),
           Div#(paddedWidthA, 8, TDiv#(dataWidthA, 8)),
           Add#(a__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8))
          );

  `ifdef SIMULATE
  BlockRamTrueMixedByteEn#(addrA, Bit#(paddedWidthA), // port A
                           addrA, Bit#(paddedWidthA), // port B
                           TDiv#(paddedWidthA, 8) // Port B byte enables width
                          ) bram <- mkBlockRamTrueMixedBEOpts_SIMULATE(opts);
  `else
  BlockRamTrueMixedByteEn#(addrA, Bit#(paddedWidthA), // port A
                           addrA, Bit#(paddedWidthA), // port B
                           TDiv#(paddedWidthA, 8) // Port B byte enables width
                          ) bram <- mkBlockRamMaybeTrueMixedBEOpts_ALTERA(opts);
  `endif

  Wire#(addrB) baddr_1 <- mkConfigRegU();
  Wire#(addrB) baddr_2 <- mkConfigRegU();
  Wire#(dataB) bout <- mkDWire(?);

  rule move;
    baddr_2 <= baddr_1;
  endrule

  rule calc_outdata;
    let idx = pack(opts.registerDataOut ? baddr_2 : baddr_1) % fromInteger(valueOf(widthRatio));
    Bit#(paddedWidthA) x_packed = bram.dataOutB;
    Vector#(widthRatio, Bit#(paddedWidthB)) xv_b = unpack(x_packed);
    dataB x = unpack(truncate(xv_b[idx]));
    bout <= x;
  endrule

  // A, the wide side, is trivial
  method Action putA(Bool wr, addrA addr, dataA data_a);
    // $display($time, " BRAM fakemixed pA got req for addr ", a, " data %x", x);

    // need to pack A intyo a vec of b's, in order to allign to the byte enables
    Vector#(widthRatio, Bit#(dataWidthB)) data_a_bvec = unpack(pack(data_a));
    Vector#(widthRatio, Bit#(paddedWidthB)) data_a_padded_bvec = unpack(0);
    for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
      data_a_padded_bvec[elab_idx] = zeroExtend(data_a_bvec[elab_idx]);
    end

    Bit#(paddedWidthA) data_packed = pack(data_a_padded_bvec);
    bram.putA(wr, addr, data_packed);
  endmethod

  method dataA dataOutA();
    Vector#(widthRatio, Bit#(paddedWidthB)) data_a_padded_bvec = unpack(bram.dataOutA);
    Vector#(widthRatio, Bit#(dataWidthB)) data_a_bvec = unpack(0);
    for (Integer elab_idx=0; elab_idx<valueOf(widthRatio); elab_idx=elab_idx+1) begin
      data_a_bvec[elab_idx] = truncate(data_a_padded_bvec[elab_idx]);
    end

    return unpack(pack(data_a_bvec));
  endmethod

  method Action putB(Bool wr, addrB addr_into_b, dataB x, Bit#(dataBBytes) be);
    // // the port is sizeOf(A) wide; we can enable 8 bits at a time by setting b_enables
    // calculate the effective address;
    baddr_1 <= addr_into_b;
    let idx = pack(addr_into_b) % fromInteger(valueOf(widthRatio));
    addrA addr_into_a = unpack(truncateLSB(pack(addr_into_b)));

    Bit#(TDiv#(dataWidthB, 8)) b_lane_base_mask = be; // all ones vector the width of dataB in bytes
    Bit#(TDiv#(dataWidthA, 8)) b_enables = zeroExtend(b_lane_base_mask) << (idx*(fromInteger(valueOf(paddedWidthB))/8)); // good
    Vector#(widthRatio, Bit#(paddedWidthB)) xv_padded = unpack(0);
    xv_padded[idx] = zeroExtend(pack(x));

    Bit#(paddedWidthA) x_buffer = pack(xv_padded);
    bram.putB(wr, addr_into_a, unpack(x_buffer), b_enables);
  endmethod

  method dataB dataOutB;
    return bout;
  endmethod

endmodule


`ifdef Stratix10
//
module mkBlockRamTrueMixedBEOpts#(BlockRamOpts opts)
         (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Literal#(addrA), Literal#(addrB),
                  Div#(dataWidthA, 8, dataBBytes),

                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8), 8),
                  Add#(a__, dataWidthA, TMul#(TDiv#(dataWidthA, 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), 8, TDiv#(dataWidthA, 8)),
                  Add#(b__, TMul#(TDiv#(dataWidthB, 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                  Mul#(TDiv#(dataWidthB, 8), TExp#(aExtra), TDiv#(dataWidthA, 8)),

                  Mul#(TDiv#(dataWidthA, dataWidthB), dataWidthB, dataWidthA),
                  Add#(d__, TDiv#(dataWidthB, 8), TDiv#(dataWidthA, 8)),
                  Mul#(TDiv#(dataWidthA, TMul#(dataBBytes, 8)), TMul#(dataBBytes, 8), dataWidthA),
                  Add#(e__, TDiv#(TMul#(dataBBytes, 8), 8), TDiv#(dataWidthA, 8)),
                  Add#(f__, TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), TMul#(TDiv#(dataWidthA, 8), 8)),
                  Add#(TDiv#(f__, 8), TDiv#(TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8), TExp#(aExtra)),
                  Add#(g__, TMul#(dataBBytes, 8), TMul#(TDiv#(TMul#(dataBBytes, 8), 8), 8)),
                  Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Add#(TDiv#(b__, 8), TDiv#(TMul#(TDiv#(dataWidthB, 8), 8), 8), TDiv#(TMul#(TDiv#(dataWidthA, 8), 8), 8)),
                  Div#(TMul#(TDiv#(dataWidthA, 8), 8), TMul#(TDiv#(dataWidthB, 8), 8), TExp#(aExtra)),
                  Add#(c__, dataWidthB, TMul#(TDiv#(dataWidthB, 8), 8))

                  );
  // For simulation, use a BRAMCore
  BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes) ram <- mkBlockRamTrueMixedBEOpts_S10(opts); // swapping to S10 crashes bsc.
  return ram;
endmodule

// ======================================================
// True dual-port mixed-width block RAM with byte-enables
// ======================================================

// Don't rely on support for mixed-width true dual-port BRAMs, which
// are no longer available on the Stratix 10.
`ifdef SIMULATE

module mkBlockRamTrueBEOpts#(BlockRamOpts opts)
      (BlockRamTrueMixedByteEn#(addrA, dataA, addrA, dataA, dataABytes))
    provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
             Bounded#(addrA),
             Mul#(dataABytes, 8, dataWidthA),
             Div#(dataWidthA, dataABytes, 8));

  // For simulation, use a BRAMCore
  BRAM_DUAL_PORT_BE#(addrA, dataA, dataABytes) ram <-
      mkBRAMCore2BELoad(valueOf(TExp#(addrWidthA)), False,
                          fromMaybe("Zero", opts.initFile) + ".hex", False);

  // State
  Reg#(dataA) dataAReg <- mkConfigRegU;
  Reg#(dataA) dataBReg <- mkConfigRegU;

  // Rules
  rule update;
    dataAReg <= ram.a.read;
    dataBReg <= ram.b.read;
  endrule

  // Port A
  method Action putA(Bool wr, addrA address, dataA x);
    ram.a.put(wr ? -1 : 0, address, x);
  endmethod

  method dataA dataOutA = opts.registerDataOut ? dataAReg : ram.a.read;

  // Port B
  method Action putB(Bool wr, addrA addr, dataA val, Bit#(dataABytes) be);
    ram.b.put(wr ? be : 0, addr, val);
  endmethod

  method dataA dataOutB = opts.registerDataOut ? dataBReg : ram.b.read;

endmodule

`endif

(* always_ready, always_enabled *)
module mkLUTRamTrueMixedBEOpts#(BlockRamOpts opts)
      (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
    provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
             Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
             Div#(dataWidthA, 8, dataABytes),
             Mul#(dataABytes, 8, dataWidthA),
             Bounded#(addrA), Bounded#(addrB),
             Add#(addrWidthA, aExtra, addrWidthB),
             Literal#(addrA), Literal#(addrB),
             Literal#(dataA), Literal#(dataB),
             Div#(dataWidthB, 8, dataBBytes),
             Mul#(dataBBytes, 8, dataWidthB),
             Add#(addrWidthA, TLog#(dataABytes), backingStoreAddrWidth),
             Add#(TLog#(dataBBytes), addrWidthB, backingStoreAddrWidth));

  Integer sizeOfDataA_v = valueOf(SizeOf#(dataA));
  UInt#(backingStoreAddrWidth) dataABytes_v = fromInteger(sizeOfDataA_v)/8;

  Integer sizeOfDataB_v = valueOf(SizeOf#(dataB));
  UInt#(backingStoreAddrWidth) dataBBytes_v = fromInteger(sizeOfDataB_v)/8;

  Vector#(TExp#(backingStoreAddrWidth), Array#(Reg#(Bit#(8)))) store <- replicateM(mkCRegU(5)); // newVector();

  // data in A
  // latch the address, so we read from the most recent location on same cycle.
  // 0: before Put*, 1: write, 2: after/forwarded.
  Reg#(Bool) dinA_wr[3] <- mkCReg(3, False);
  Reg#(UInt#(backingStoreAddrWidth)) dinA_backing_address[3] <- mkCReg(3, 0);
  Reg#(dataA) dinA_x[3] <- mkCReg(3, 0);
  PulseWire putA_fired <- mkPulseWire();

  // data in B
  Reg#(Bool) dinB_wr[3] <- mkCReg(3, False);
  Reg#(UInt#(backingStoreAddrWidth)) dinB_backing_address[3] <- mkCReg(3, 0);
  Reg#(dataB) dinB_x[3] <- mkCReg(3, 0);
  Reg#(Bit#(dataBBytes)) dinB_be[3] <- mkCReg(3, 0);

  // data out: wire and reg versions
  // we write to [0]; reading from [1] gives wire (unreg) behaviour, [0] reg.
  Wire#(dataA) doutA[2] <- mkCReg(2, 0);
  Wire#(dataB) doutB[2] <- mkCReg(2, 0);
  Reg#(dataB) doutB_reg <- mkReg(0);


  Integer dataInA_r_sample_order = 2;
  Integer dataInA_r_store_order = 2;
  Integer dataInB_r_sample_order = 2;
  Integer dataInB_r_store_order = 0; // ref model stores to B first.


  // following behav. rules are ordered by the order of access to the
  // (* no_implicit_conditions, fire_when_enabled *)
  rule dataInB_r;
    UInt#(backingStoreAddrWidth) backing_address = dinB_backing_address[dataInB_r_sample_order];
    Vector#(dataBBytes, Bool) be_bools = unpack(pack(dinB_be[dataInB_r_sample_order]));
    if (dinB_wr[dataInB_r_sample_order]) begin
      Vector#(TDiv#(SizeOf#(dataB), 8), Bit#(8)) x_b = unpack(pack(dinB_x[dataInB_r_sample_order]));
      for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataBBytes_v); i=i+1) begin
        if (be_bools[i]) begin
          store[backing_address+i][dataInB_r_store_order] <= x_b[i];
        end
      end
    end
  endrule

  rule dataOutB_r;
    Integer sample_order = 2;
    Integer load_order = 1;
    UInt#(backingStoreAddrWidth) backing_address = dinB_backing_address[sample_order];

    // // the only s10 true dual port read behaviour is New_data; build the backing array we read from
    // Vector#(TExp#(backingStoreAddrWidth), Bit#(8)) store_with_pA_writes = newVector();
    // for (Integer i=0; i<valueOf(TExp#(backingStoreAddrWidth)); i=i+1) begin
    //    store_with_pA_writes[i] = store[i][store_order];
    // end
    //
    // Vector#(dataBBytes, Bool) be_bools = unpack(pack(dinB_be[2]));
    // if (dinB_wr[2]) begin
    //   Vector#(TDiv#(SizeOf#(dataB), 8), Bit#(8)) x_b_B = unpack(pack(dinB_x[2]));
    //   for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataBBytes_v); i=i+1) begin
    //     if (be_bools[i]) begin
    //       store_with_pA_writes[backing_address+i] = x_b_B[i];
    //     end
    //   end
    // end
    //
    // Integer dataInA_r_bypass_sample_order = 2;
    // UInt#(backingStoreAddrWidth) backing_address_portA = dinA_backing_address[dataInA_r_bypass_sample_order];
    // if (dinA_wr[dataInA_r_bypass_sample_order]) begin
    //   $display($time, " [dataOutB_r] ovveriding output with port A data");
    //   Vector#(TDiv#(SizeOf#(dataA), 8), Bit#(8)) x_b_A = unpack(pack(dinA_x[dataInA_r_bypass_sample_order]));
    //   for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataABytes_v); i=i+1) begin
    //     store_with_pA_writes[backing_address_portA+i] = store[backing_address_portA+i][4]; //x_b_A[i];
    //   end
    // end



    Vector#(TDiv#(SizeOf#(dataB), 8), Bit#(8)) x_b = newVector();
    for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataBBytes_v); i=i+1) begin
       x_b[i] = store[backing_address+i][load_order];
    end
    doutB[0] <= unpack(pack(x_b));
  endrule

  rule doutB_cpy;
    doutB_reg <= doutB[1];
  endrule



  // (* no_implicit_conditions, fire_when_enabled *)
  // this should write to store later.
  rule dataInA_r;
    UInt#(backingStoreAddrWidth) backing_address = dinA_backing_address[dataInA_r_sample_order];
    if (dinA_wr[dataInA_r_sample_order]) begin
      Vector#(TDiv#(SizeOf#(dataA), 8), Bit#(8)) x_b = unpack(pack(dinA_x[dataInA_r_sample_order]));
      for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataABytes_v); i=i+1) begin
        store[backing_address+i][dataInA_r_store_order] <= x_b[i];
      end
    end
    putA_fired.send();
  endrule

  // (* no_implicit_conditions, fire_when_enabled *)
  rule dataOutA_r;
    Integer sample_order = 2;
    Integer load_order = 3;
    UInt#(backingStoreAddrWidth) backing_address = dinA_backing_address[sample_order];

    // // the only s10 true dual port read behaviour is New_data; build the backing array we read from
    // Vector#(TExp#(backingStoreAddrWidth), Bit#(8)) store_with_pA_writes = newVector();
    // for (Integer i=0; i<valueOf(TExp#(backingStoreAddrWidth)); i=i+1) begin
    //    store_with_pA_writes[i] = store[i][load_order];
    // end
    //
    // if (dinA_wr[sample_order]) begin
    //   Vector#(TDiv#(SizeOf#(dataA), 8), Bit#(8)) x_b_A = unpack(pack(dinA_x[sample_order]));
    //   for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataABytes_v); i=i+1) begin
    //     store_with_pA_writes[backing_address+i] = x_b_A[i];
    //   end
    // end


    Vector#(TDiv#(SizeOf#(dataA), 8), Bit#(8)) x_b = newVector();
    for (UInt#(backingStoreAddrWidth) i=0; i<extend(dataABytes_v); i=i+1) begin
       x_b[i] = store[backing_address+i][load_order];
    end
    doutA[0] <= unpack(pack(x_b));
  endrule

  // Port A
  method Action putA(Bool wr, addrA address, dataA x);
    $display($time, " [PutA] called");
    dinA_wr[1] <= wr;
    UInt#(backingStoreAddrWidth) backing_address = unpack(extend(pack(address))) * dataABytes_v;
    dinA_backing_address[1] <= backing_address;
    dinA_x[1] <= x;
  endmethod

  method dataA dataOutA = doutA[0];

  method Action putB(Bool wr, addrB address, dataB x, Bit#(dataBBytes) be);
    dinB_wr[1] <= wr;
    UInt#(backingStoreAddrWidth) backing_address = unpack(extend(pack(address))) * dataBBytes_v;
    dinB_backing_address[1] <= backing_address;
    dinB_x[1] <= x;
    dinB_be[1] <= be;
  endmethod

  // if output data is registered, we read from the first loc in the CReg; this is SB the write, so adds a cycle of delay.
  method dataB dataOutB = doutB_reg; // opts.registerDataOut ? doutB[1] : doutB[1];
endmodule


module mkBlockRamPortableTrueMixedBEOpts#(BlockRamOpts opts)
         (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
         provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
                  Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
                  Bounded#(addrA), Bounded#(addrB),
                  Add#(addrWidthA, aExtra, addrWidthB),
                  Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
                  Mul#(dataBBytes, 8, dataWidthB),
                  Div#(dataWidthB, dataBBytes, 8),
                  Mul#(dataABytes, 8, dataWidthA),
                  Div#(dataWidthA, dataABytes, 8),
                  Mul#(TExp#(aExtra), dataBBytes, dataABytes));

  BlockRamOpts internalOpts = opts;
  // staticAssert(opts.registerDataOut, "mkBlockRamPortableTrueMixedBEOpts needs internal reg");
  internalOpts.registerDataOut = False;

  `ifdef SIMULATE
  BlockRamTrueMixedByteEn#(addrA, dataA, addrA, dataA, dataABytes) ram <-
    mkBlockRamTrueBEOpts(internalOpts);
  `else
  BlockRamTrueMixedByteEn#(addrA, dataA, addrA, dataA, dataABytes) ram <-
    mkBlockRamMaybeTrueMixedBEOpts_ALTERA(internalOpts);
  `endif

  // State
  Reg#(dataA) dataAReg <- mkConfigRegU;
  Reg#(dataA) dataBReg <- mkConfigRegU;
  Reg#(Bit#(aExtra)) offsetB1 <- mkConfigRegU;
  Reg#(Bit#(aExtra)) offsetB2 <- mkConfigRegU;

  // Rules
  rule update;
    offsetB2 <= offsetB1;
    dataAReg <= ram.dataOutA;
    dataBReg <= ram.dataOutB;
  endrule

  // Port A
  method Action putA(Bool wr, addrA address, dataA x);
    ram.putA(wr, address, x);
  endmethod

  method dataA dataOutA = opts.registerDataOut ? dataAReg : ram.dataOutA;

  // Port B
  method Action putB(Bool wr, addrB address, dataB val, Bit#(dataBBytes) be);
    Bit#(aExtra) offset = truncate(pack(address));
    offsetB1 <= offset;
    Bit#(addrWidthA) addr = truncateLSB(pack(address));
    Bit#(dataWidthA) vals = pack(replicate(val));
    Vector#(TExp#(aExtra), Bit#(dataBBytes)) paddedBE;
    for (Integer i = 0; i < valueOf(TExp#(aExtra)); i=i+1)
      paddedBE[i] = (offset == fromInteger(i)) ? be : unpack(0);
    ram.putB(wr, unpack(addr), unpack(vals), pack(paddedBE));
  endmethod

  method dataB dataOutB;
    Vector#(TExp#(aExtra), dataB) vec = unpack(pack(
      opts.registerDataOut ? dataBReg : ram.dataOutB));
    return vec[opts.registerDataOut ? offsetB2 : offsetB1];
  endmethod

endmodule


`endif // Stratix10

`ifdef StratixV

// module mkBlockRamTrueMixedBEOpts#(BlockRamOpts opts)
//          (BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes))
//          provisos(Bits#(addrA, addrWidthA), Bits#(dataA, dataWidthA),
//                   Bits#(addrB, addrWidthB), Bits#(dataB, dataWidthB),
//                   Bounded#(addrA), Bounded#(addrB),
//                   Add#(addrWidthA, aExtra, addrWidthB),
//                   Mul#(TExp#(aExtra), dataWidthB, dataWidthA),
//                   Mul#(dataBBytes, 8, dataWidthB),
//                   Div#(dataWidthB, dataBBytes, 8),
//                   Mul#(dataABytes, 8, dataWidthA),
//                   Div#(dataWidthA, dataABytes, 8),
//                   Mul#(TExp#(aExtra), dataBBytes, dataABytes));
//   // For simulation, use a BRAMCore
//
//   `ifdef SIMULATE
//   BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes) ram <- mkBlockRamMaybeTrueMixedBEOpts_ALTERA(opts);
//   `else // not SIMULATE
//   BlockRamTrueMixedByteEn#(addrA, dataA, addrB, dataB, dataBBytes) ram <- mkBlockRamTrueMixedBEOptsPadded_S10(opts);
//   `endif // not SIMULATE
//
//   return ram;
// endmodule

`endif // StratixV

endpackage
