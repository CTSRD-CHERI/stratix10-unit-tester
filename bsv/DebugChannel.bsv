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
 * Abstracted byte-wide communications channel.
 * Two instatiations:
 *   1. BSIM is not defined: uses a Jtag Atlantic interface to Stratix 10 FPGA
 *   2. BSIM is defined: use a named pipe for communication using a Verilog sim
 */

package DebugChannel;

export DebugChannel;
export mkDebugChannel;

import GetPut         :: *;
import ClientServer   :: *;
`ifdef BSIM
  import NamedPipePure  :: *;
`else
  import AlteraJtagUart :: *;
`endif

typedef Client#(Bit#(8), Bit#(8)) DebugChannel;

module mkDebugChannel(DebugChannel);
`ifdef BSIM
  DebugChannel   uart <- mkPipeClient();
`else
  AlteraJtagUart uart <- mkAlteraJtagUart(6, 6, 0, 0);
`endif
  return uart;
endmodule: mkDebugChannel

endpackage: DebugChannel
