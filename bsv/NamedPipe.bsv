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
 * simulation.  Notes that it relies on Verilog modules for read and write so
 * is usable in a Verilog simulator like Icarus Verilog, but not the Bluespec
 * simulator.
 */

package NamedPipe;

export mkPipeReader;
export mkPipeWriter;

import GetPut :: *;

import "BVI" PipeReader_V =
module mkPipeReader(Get#(Bit#(8)));
  method GET get ready (RDY_GET) enable (EN_GET);
  default_clock clk (CLK, (*unused*) clk_gate);
  default_reset rst (RST_N);
  schedule get C get;
endmodule: mkPipeReader


import "BVI" PipeWriter_V =
module mkPipeWriter(Put#(Bit#(8)));
  method put(PUT) enable (EN_PUT) ready (RDY_PUT);
  default_clock clk (CLK, (*unused*) clk_gate);
  default_reset rst (RST_N);
  schedule put C put;
endmodule: mkPipeWriter
  
endpackage: NamedPipe
