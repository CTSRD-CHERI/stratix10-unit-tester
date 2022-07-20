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
# Test various memories

import sys
sys.path.append(r'../../py')
import fpga_debug_interface
import argparse

class simple_test:
    def __init__(self, simulation_mode):
        self.error = False
        self.dbg = fpga_debug_interface.debug_interface(sim=simulation_mode)  # True=simulate, False=on FPGA
        self.init_ram()

    def init_ram(self):
        self.ram = [None] * 1024
        self.ram = [None] * 1024
        self.respAhi = []
        self.respAlo = []
        self.respB = []
        
    def read_check(self, idx, expected):
        try:
            r = self.dbg.read(idx)
            if(r != expected):
                print("ERROR: cmdreg[%1d]=%2d but expected %2d" % (idx, r, expected))
                self.error = True
            else:
                print("cmdreg[%1d] == %2d" % (idx, r))
        except:
            print("Exception during read of idx=%d" % (idx))
            self.error = True

    def write_report(self, idx, data):
        self.dbg.write(idx, data)
        print("cmdreg[%2d] <= 0x%016x" % (idx, data))

    # write command to single read, single write BRAM tester
    def write_cmd_sp(self, re, we, rd_addr, wr_addr, wr_data):
        cmd = ((re & 0x1)<<51) | ((we & 0x1)<<50) | ((rd_addr & 0x1ff)<<41) | ((wr_addr & 0x1ff)<<32) | (wr_data & 0xffffffff)
        self.write_report(0,cmd)

    # write command to true dual-port BRAM tester
    def write_cmd_dp(self, reB, weB, reA, weA, addrB, addrA, wr_dataB, wr_dataA):
        cmd = ((reB & 0x1)<<43) | ((weB & 0x1)<<42) | ((reA & 0x1)<<41) | ((weA & 0x1)<<40) | ((addrB & 0xfff)<<28) | ((addrA & 0xfff)<<16) | ((wr_dataB & 0xff) << 8) | (wr_dataA & 0xff)
        self.write_report(2,cmd)

    # write command to multi-width true dual-port BRAM tester
    def write_cmd_mw(self, reB, weB, reA, weA, beB, addrB, addrA, wr_dataB, wr_dataA_hi, wr_dataA_lo):
        self.write_report(8,wr_dataB);
        self.write_report(7,wr_dataA_hi);
        self.write_report(6,wr_dataA_lo);
        cmd = ((reB & 0x1)<<35) | ((weB & 0x1)<<34) | ((reA & 0x1)<<33) | ((weA & 0x1)<<32) | ((beB & 0xf)<<28) | ((addrB & 0x7fff)<<13) | (addrA & 0x1fff)
        self.write_report(4,cmd)
        if(weA): # ram[] is 32b wide so split 128b writes
            self.ram[addrA*4+0] = (wr_dataA_lo>> 0) & 0xffffffffffffffff
            self.ram[addrA*4+1] = (wr_dataA_lo>>64) & 0xffffffffffffffff
            self.ram[addrA*4+2] = (wr_dataA_hi>> 0) & 0xffffffffffffffff
            self.ram[addrA*4+3] = (wr_dataA_hi>>64) & 0xffffffffffffffff
        if(weB):
            if(beB==0xf):
                self.ram[addrB] = wr_dataB
            else:
                mask = 0
                invmask = 0
                for j in range(4):
                    if((beB>>j) & 0x1 == 1):
                        mask = mask | (0xff<<j*8)
                    else:
                        invmask = invmask | (0xff<<j*8)
                self.ram[addrB] = (wr_dataB & mask) | (self.ram[addrB] & invmask)
        if(reA):
            self.respAlo.append((self.ram[addrA*4+1]<<32) | self.ram[addrA*4+0])
            self.respAhi.append((self.ram[addrA*4+3]<<32) | self.ram[addrA*4+2])
        if(reB):
            self.respB.append(self.ram[addrB])

    def running_sp(self):
        return (self.dbg.read(1)>>4) & 0x1

    def running_dp(self):
        return (self.dbg.read(4)>>6) & 0x1

    def running_mw(self):
        return (self.dbg.read(8)>>6) & 0x1

    # Tests for single read, single write BRAM
    def run_test_spbram(self):
        self.dbg.clear()
        print("Writing command sequence")
        for j in range(16):  # seqence of writes
            self.write_cmd_sp(0,1,0,j,j+10000)
        for j in range(16):  # sequence of reads
            self.write_cmd_sp(1,0,j,0,0)
        for j in range(16):  # sequence of write and reads reads
            self.write_cmd_sp(1,1,j,j,j+20000)
        for j in range(16):  # sequence of write and reads reads
            self.write_cmd_sp(1,1,j^1,j,j+30000)
#            self.write_cmd_sp(1,1,(j+15) % 16,j,j+30000)
        print("Run sequence")
        self.write_report(1,1)
        while(self.running_sp()):
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
    
    # Tests for true dual-port BRAM
    def run_test_dpbram(self):
        self.dbg.clear()
        self.init_ram()
        print("Writing command sequence")
        for j in range(16):  # seqence of writes to Port A and B
            self.write_cmd_dp(0,1, 0,1, j*2+1,j*2, j+200,j+100)
        for j in range(16):  # sequence of reads from Port B and A
            self.write_cmd_dp(1,0, 1,0, j*2,j*2+1, 0,0)
        print("Run sequence")
        self.write_report(3,1)
        while(self.running_dp()):
            print("Waiting for test sequence to finish")
        print("Reading values read from port A")
        for j in range(16):
            d = self.dbg.read(2)
            print("mem[%2d] = %d = 0x%08x" % (j*2+1,d,d))
        print("Reading values read from port B")
        for j in range(16):
            d = self.dbg.read(3)
            print("mem[%2d] = %d = 0x%08x" % (j*2,d,d))
        self.dbg.end_simulation()
    
    # Tests for multi-width true dual-port BRAM
    def run_test_mwbram(self):
        self.dbg.clear()
        
        print("Writing command sequence")
        # write_cmd_mw(reB,weB, reA,weA, beB, addrB,addrA, wr_dataB,wr_dataA_hi,wr_dataA_lo):
        for j in range(16):  # seqence of writes to Port A and B
            self.write_cmd_mw(0,1, 0,1, 0xf, (j*2+1)*4,j*2, j | 0x3000,j | 0x2000,j | 0x1000)
        for j in range(16):  # seqence of writes to Port B
            for k in range(3):
                self.write_cmd_mw(0,1, 0,0, 0xf, (j*2+1)*4+k+1,0, j | 0x1100, 0xdeaddead, 0xdeaddead)
        for j in range(32):  # sequence of reads from Port A
            self.write_cmd_mw(0,0, 1,0, 0xf, 0,j, 3,2,1)
        print("Run sequence")
        self.write_report(9,1)
        while(self.running_mw()):
            print("Waiting for test sequence to finish")
        print("Reading values read from port A")
        for j in range(32):
            d_upper = self.dbg.read(6)
            d_lower = self.dbg.read(5)
            d_upper_check = self.respAhi.pop(0)
            d_lower_check = self.respAlo.pop(0)
            correct = (d_upper == d_upper_check) and (d_lower == d_lower_check)
            self.error = self.error or not(correct)
            print("mem[%2d] = 0x%016x 0x%016x  check = 0x%016x 0x%016x  -  %s"
                  % (j,d_upper,d_lower,d_upper_check,d_lower_check,"pass" if (correct) else "**FAIL**"))
        
        print("Writing command sequence for simultanious writes and reads to the same address")
        # write_cmd_mw(reB,weB, reA,weA, beB, addrB,addrA, wr_dataB,wr_dataA_hi,wr_dataA_lo):
        for j in range(16):
            self.write_cmd_mw(1,1, 0,0, 0xf, j,0, j | 0x4000,0x1111111111111111,0x2222222222222222)
        print("Run sequence")
        self.write_report(9,1)
        while(self.running_mw()):
            print("Waiting for test sequence to finish")
        for j in range(16):
            d = self.dbg.read(7)
            d_check = self.respB.pop(0)
            correct = d == d_check
            self.error = self.error or not(correct)
            print("mem[%2d] = 0x%08x  check = 0x%08x  -  %s"
                  % (j, d, d_check, "pass" if (correct) else "**FAIL**"))

        print("Writing command sequence to test byte writes")
        # write_cmd_mw(reB,weB, reA,weA, beB, addrB,addrA, wr_dataB,wr_dataA_hi,wr_dataA_lo):
        # write initial values as 128b values on port A
        for j in range(4):
            self.write_cmd_mw(0,0, 0,1, 0x0, 0,j, 0xdeaddead, 0xffffffff,0xffffffff)
            # self.write_cmd_mw(0,0, 0,1, 0x0, 0,j, 0xdeaddead, 0x0f0e0d0c0b0a0908,0x0706050403020100)
        # write to even bytes via port B
        for j in range(16):
            k = 15-j
            self.write_cmd_mw(0,1, 0,0, 0xa, j,0, (k<<24) | (k<<8) | 0x20ff10ff, 0xdead0000dead0000, 0xdead0000dead0000)
        # read back result
        for j in range(16):
            self.write_cmd_mw(1,0, 0,0, 0xa, j,0, 0x1413121110, 0xdead0000dead0000, 0xdead0000dead0000)
        print("Run sequence")
        self.write_report(9,1)
        while(self.running_mw()):
            print("Waiting for test sequence to finish")
        for j in range(16):
            d = self.dbg.read(7)
            d_check = self.respB.pop(0)
            correct = d == d_check
            self.error = self.error or not(correct)
            print("mem[%2d] = 0x%08x  check = 0x%08x  -  %s"
                  % (j, d, d_check, "pass" if (correct) else "**FAIL**"))

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
        # test.run_test_spbram() # test single read, single write BRAM
        test.run_test_mwbram()
        # test.run_test_mwbram()  # test true dual-port BRAM
        if(test.error):
            print("Test %d result: FAIL" % (j))
            exit(-1)
        else:
            print("Test %d result: PASS" % (j))
    
exit(0)
