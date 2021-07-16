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
 */

package FPGADebugInterface;

import DebugChannel   :: *;
import ClientServer   :: *;
import GetPut         :: *;
import Vector         :: *;
import FIFOF          :: *;
import FIFO           :: *;


typedef enum {
     Cmd_nop           =   0,
     Cmd_reset         =   1,  // TODO implement!!!
     Cmd_write_word    =   2,
     Cmd_read_word     =   3,
     Cmd_end_sim       = 254, // simulation only
     Cmd_invalid       = 255
   } DebugCommand deriving (Eq, Bits);

typedef enum {
     Rsp_nop           =   0,
     Rsp_reset_done    =   1,
     Rsp_write_ack     =   2,
     Rsp_read_data     =   3,
     Rsp_checksum_fail = 254,
     Rsp_invalid       = 255
   } DebugResponseCode deriving (Eq, Bits);

typedef Bit#(8) DebugIndex;

typedef Bit#(64) DebugWord;

typedef struct {
   DebugCommand cmd;
   DebugIndex idx;
   DebugWord  dat;
   } DebugRequest deriving (Bits,Eq);


typedef Client#(DebugRequest, DebugWord) FPGADebugInterface;


(* synthesize *)
module mkFPGADebugInterface(FPGADebugInterface);
  DebugChannel                       chan <- mkDebugChannel;
  Vector#(10,Reg#(Bit#(8)))      shift_in <- replicateM(mkReg(0)); // TODO: parameterise size based on Debug types
  FIFO#(DebugRequest)       debug_request <- mkFIFO;
  FIFOF#(DebugWord)        debug_response <- mkGFIFOF(False,True);  // garded enq, ungarded deq
  FIFOF#(DebugResponseCode) response_code <- mkGFIFOF(False,True);  // garded enq, ungarded deq
//  Reg#(Bit#(TAdd#(TLog#(TDiv#(SizeOf#(DebugWord),8)),1)))
  Reg#(Bit#(4))            tx_bytes_to_go <- mkReg(0);
  Reg#(DebugWord)                 tx_word <- mkReg(0);
  Reg#(Bit#(8))               checksum_rx <- mkReg(8'h55);
  Reg#(Bit#(8))               checksum_tx <- mkReg(8'h55);
  
  rule jtag_rx;
    Bit#(8) d <- chan.request.get();
    //$display("DEBUG: RX 0x%02x", d);
    Bool command_received = (shift_in[9] != unpack(pack(Cmd_nop)));
    for(int j=0; j<9; j=j+1)
      shift_in[j+1] <= command_received ? 0: shift_in[j];
    shift_in[0]  <= command_received ? 0 : d;
    checksum_rx <= command_received ? 8'h55 : checksum_rx+d;
    if(command_received)
      if(d == checksum_rx) // valid checksum
	begin
	  //$display("DEBUG: valid check sum");
	  DebugCommand cmd = unpack(shift_in[9]);
	  debug_request.enq(
	     DebugRequest{
		cmd: cmd,
		idx: shift_in[8],
		dat: {shift_in[7], shift_in[6], shift_in[5], shift_in[4],
		      shift_in[3], shift_in[2], shift_in[1], shift_in[0]}
		}
	     );
	  if(cmd == Cmd_write_word)
	    response_code.enq(Rsp_write_ack);
	  if(cmd == Cmd_end_sim)
	    $finish(0);
	end
      else
	begin
	  response_code.enq(Rsp_checksum_fail);
	  $display("DEBUG: invalid check sum: d=0x%02x  check sum=0x%02x",d,checksum_rx);
	end
  endrule

  rule jtag_tx_checksum (tx_bytes_to_go==1);
    //$display("DEBUG:\t\t\tTX send checksum 0x%02x",checksum_tx);
    chan.response.put(checksum_tx);
    tx_bytes_to_go <= 0;
  endrule
  rule jtag_tx_data (tx_bytes_to_go>1);
    Bit#(8) msb = tx_word[63:56];
    //$display("DEBUG:\t\t\tTX byte of data 0x%02x",msb);
    chan.response.put(msb);
    checksum_tx <= checksum_tx + msb;
    tx_word <= tx_word<<8;
    tx_bytes_to_go <= tx_bytes_to_go-1;
  endrule
  rule jtag_tx_response_code(tx_bytes_to_go==0);
    if(debug_response.notEmpty)
      begin
	chan.response.put(unpack(pack(Rsp_read_data)));
	//$display("DEBUG:\t\t\tTX response code Resp_read_data");
	tx_word <= debug_response.first;
	debug_response.deq();
	// tx_bytes_to_go <= valueOf(TDiv#(SizeOf#(DebugWord),8));
	tx_bytes_to_go <= 9;
	Bit#(8) code = unpack(pack(Rsp_read_data));
	checksum_tx <= 8'h55 + code;
      end
    else if(response_code.notEmpty)
      begin
	Bit#(8) code = unpack(pack(response_code.first));
	chan.response.put(code);
	//$display("DEBUG:\t\t\tTX response code: 0x%02x",code);
	checksum_tx <= 8'h55 + code;
	tx_bytes_to_go <= 1;
	response_code.deq();
      end
  endrule
  
  interface request  = toGet(debug_request);
  interface response = toPut(debug_response);
endmodule

endpackage: FPGADebugInterface
