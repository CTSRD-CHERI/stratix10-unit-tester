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

import sys, os
import subprocess as sp
sys.path.append(r'../../py')
import fpga_debug_interface
import argparse
import progallde10pro

canned_sof = 'prebuilt_image.sof'

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    devices = progallde10pro.find_de10pro_devices()
    k = list(devices.keys())
    device_zero = '' if(len(k)==0) else k[0]
    parser.add_argument('-p', '--program_fpgas', action='store_true', help='program FPGAs')
    parser.add_argument('-b', '--bitimage', type=str, action='store', default=canned_sof,
                        help='specify SOF file to program (defaults to %s)'%(canned_sof))
    parser.add_argument('-s', '--sequential', action='store_true', default=False,
                        help='program FPGAs sequentially')
    group = parser.add_mutually_exclusive_group() 
    group.add_argument('-a', '--all', action='store_true', default=False, help='Read ID from all FPGAs')
    group.add_argument('-c', '--cable', type=str, action='store', default=device_zero,
              help='Specify cable corresponding to FPGA (obtained from jtagconfig, e.g. "DE10-Pro [5-2.3.1]")')
    args = parser.parse_args()
    if(args.program_fpgas):
        print("Programming all DE10Pro FPGA boards with %s image"%(args.bitimage))
        if(args.bitimage==canned_sof):
            if(not(os.path.exists(canned_sof)) and os.path.exists(canned_sof+'.bz2')):
                sp.run(['bunzip2','-k',canned_sof+'.bz2'], timeout=20, check=True)
        process_list = progallde10pro.spawn_quartus_pgm(devices=devices,sof=args.bitimage,sequential=args.sequential)
        progallde10pro.report_process_status(devices, process_list)
    if(args.all):
        cables = devices.keys()
    else:
        cables = [args.cable]
    for c in cables:
        dbg = fpga_debug_interface.debug_interface(sim=False, cable_name=c)
        print("Cable: %s, ChipID: 0x%016x" % (c,dbg.read(0)))
    
exit(0)
