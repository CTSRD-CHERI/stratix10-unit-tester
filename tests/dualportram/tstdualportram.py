#!/usr/bin/env python3

# Copyright (c) 2022 Simon W. Moore
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

class simple_test:
    def __init__(self, simulation_mode):
        self.error = False
        self.dbg = fpga_debug_interface.debug_interface(sim=simulation_mode)  # True=simulate, False=on FPGA

    def read_check(self, idx, expected):
        try:
            r = self.dbg.read(idx)
            if(r != expected):
                print("ERROR: reg[%1d]=%2d but expected %2d" % (idx, r, expected))
                self.error = True
            else:
                print("reg[%1d] == %2d" % (idx, r))
        except:
            print("Exception during read of idx=%d" % (idx))
            self.error = True

    def write_report(self, idx, data):
        self.dbg.write(idx, data)
        print("reg[%1d] <= %2d" % (idx, data))

    def write_cmd(self, re, we, rd_addr, wr_addr, wr_data):
        cmd = ((re & 0x1)<<51) | ((we & 0x1)<<50) | ((rd_addr & 0x1ff)<<41) | ((wr_addr & 0x1ff)<<32) | (wr_data & 0xffffffff)
        self.write_report(0,cmd)

    def running(self):
        return (self.dbg.read(1)>>4) & 0x1
    
    def run_test(self):
        self.dbg.clear()
        print("Writing command sequence")
        for j in range(16):  # seqence of writes
            self.write_cmd(0,1,0,j,j+10000)
        for j in range(16):  # sequence of reads
            self.write_cmd(1,0,j,0,0)
        for j in range(16):  # sequence of write and reads reads
            self.write_cmd(1,1,j,j,j+20000)
        for j in range(16):  # sequence of write and reads reads
            self.write_cmd(1,1,j^1,j,j+30000)
#            self.write_cmd(1,1,(j+15) % 16,j,j+30000)
        print("Run sequence")
        self.write_report(1,1)
        while(self.running()):
            print("Waiting for test sequence to finish")
        print("Reading values read")
        for j in range(16):
            print("mem[%2d] = %d" % (j,self.dbg.read(0)))
        for j in range(16):
            print("mem[%2d] = %d" % (j,self.dbg.read(0)))
        for j in range(16):
            print("mem[%2d] = %d" % (j^1,self.dbg.read(0)))
#            print("mem[%2d] = %d" % ((j+15) % 16,self.dbg.read(0)))
        self.dbg.end_simulation()
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--fpga', help='test on FPGA', action="store_true")
    group.add_argument('--sim', help='test in simulation (Icarus Verilog)', action="store_true")
    parser.add_argument('--n', help='number of iterations', type=int, default=1)
    args = parser.parse_args()
    if not((args.fpga and not(args.sim)) or (not(args.fpga) and args.sim)):
        parser.error('Select --fpga or --sim')
    if(args.fpga):
        print("FPGA test starting for %d iterations" % (args.n))
    if(args.sim):
        print("Simulation starting for %d iterations" % (args.n))
    test = simple_test(args.sim)
    for j in range(args.n):
        test.run_test()
        if(test.error):
            print("Test %d result: FAIL" % (j))
            exit(-1)
        else:
            print("Test %d result: PASS" % (j))
    
exit(0)
