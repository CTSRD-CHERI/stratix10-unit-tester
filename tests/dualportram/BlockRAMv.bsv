package BlockRAMv;

/*****************************************************************************
 * Builds on BlockRAM by Matt Naylor, et al.
 * This "v" version uses pure Verilog to describe basic single and
 * true dual-port RAMs that can be inferred as BRAMs like M20K on Stratix 10.
 *****************************************************************************/


// ==========
// Interfaces
// ==========

// Basic dual-port block RAM with a read port and a write port
interface BlockRamv#(type addr, type data);
  method Action read(addr a);
  method Action write(addr a, data d);
  method data dataOut;
  method Bool dataOutValid;
endinterface


// =====================
// Verilog Instatiations
// =====================

import "BVI" VerilogBlockRAM_OneCycle =
  module mkBlockRAM_Verilog(BlockRamv#(addr, data))
         provisos(Bits#(addr, addrWidth),
                  Bits#(data, dataWidth));

    parameter ADDR_WIDTH     = valueOf(addrWidth);
    parameter DATA_WIDTH     = valueOf(dataWidth);

    method read(RD_ADDR) enable (RE) clocked_by(clk);
    method write(WR_ADDR, DI) enable (WE) clocked_by(clk);
    method DO dataOut;
    method DO_VALID dataOutValid;

    default_clock clk(CLK, (*unused*) clk_gate);
    default_reset no_reset;

    schedule (dataOut) CF (dataOut);
    schedule (dataOut) CF (read);
    schedule (dataOut) CF (write);
    schedule (dataOutValid) CF (dataOutValid);
    schedule (dataOutValid) CF (read);
    schedule (dataOutValid) CF (write);
    schedule (read)    CF (write);
    schedule (write)   C  (write);
    schedule (read)    C  (read);
  endmodule

endpackage: BlockRAMv
