#!/usr/bin/env python3

# Copyright (c) 2021 Simon W. Moore
# All rights reserved.
#
# This software was developed at the University of Cambridge Computer
# Laboratory (Department of Computer Science and Technology) based
# upon work supported by the DoD Information Analysis Center Program
# Management Office (DoD IAC PMO), sponsored by the Defense
# Technical Information Center (DTIC) under Contract No. FA807518D0004.
#
# @BERI_LICENSE_HEADER_START@
#
# Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  BERI licenses this
# file to you under the BERI Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.beri-open-systems.org/legal/license-1-0.txt
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @BERI_LICENSE_HEADER_END@
# 
# ----------------------------------------------------------------------------
# Simple test of FPGADebugInterface

import sys
sys.path.append(r'../../py')
import fpga_debug_interface
import argparse

if __name__ == "__main__":
    # keep arguments to be consistent with other tests even though
    # --fpga is the only valid option
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--fpga', help='test on FPGA', action="store_true")
    group.add_argument('--sim', help='test in simulation (Icarus Verilog)', action="store_true")
    args = parser.parse_args()
    if not((args.fpga and not(args.sim)) or (not(args.fpga) and args.sim)):
        parser.error('Select --fpga or --sim')
    if(args.fpga):
        dbg = fpga_debug_interface.debug_interface(False)  # True=simulate, False=on FPGA
        print("Reading ChipID: 0x%016x" % (dbg.read(0)))
    if(args.sim):
        print("ERROR: Simulation is not an option for this test")
        exit(-1)
    
exit(0)
