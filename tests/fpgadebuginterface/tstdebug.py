#!/usr/bin/env python3

# Copyright (c) 2021 Simon W. Moore
# All rights reserved.
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

import fpga_debug_interface

dbg = fpga_debug_interface.debug_interface(False)  # True=simulate, False=on FPGA
error = False

def read_check(idx, expected):
    r = dbg.read(idx)
    if(r != expected):
        print("ERROR: reg[%1d]=%2d but expected %2d" % (idx, r, expected))
        error = True

def run_simple_test():
    dbg.clear()
    dbg.write(0,3)
    dbg.write(2,7)
    dbg.write(3,13)
    dbg.write(1,17)
    read_check(0,3)
    read_check(2,7)
    read_check(3,13)
    read_check(1,17)
    dbg.write(4,3)
    dbg.write(5,3)
    dbg.write(6,3)
    dbg.write(7,3)
    read_check(0,6)
    read_check(1,20)
    read_check(2,10)
    read_check(3,16)
    dbg.end_simulation()
    
if __name__ == "__main__":
    run_simple_test()
    if(error):
        print("Test result: FAIL")
    else:
        print("Test result: PASS")
    
exit(0)
