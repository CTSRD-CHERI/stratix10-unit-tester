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
# Simple loop-back test of a named FIFO 

import os
import fcntl
import time

FIFO_PY2V = 'bytepipe-host2hw'
FIFO_V2PY = 'bytepipe-hw2host'

fifo_tx = open(FIFO_PY2V,'wb')
fifo_rx = open(FIFO_V2PY,'rb', buffering=0)
fd_tx = fifo_tx.fileno()
fd_rx = fifo_rx.fileno()
flag_tx = fcntl.fcntl(fd_tx, fcntl.F_GETFL)
flag_rx = fcntl.fcntl(fd_rx, fcntl.F_GETFL)
#fcntl.fcntl(fd_tx, fcntl.F_SETFL, flag_tx | os.O_NONBLOCK)
fcntl.fcntl(fd_rx, fcntl.F_SETFL, flag_rx | os.O_NONBLOCK)

error = False
for j in range(255,0,-1):
    fifo_tx.write(j.to_bytes(1,"little"))
    fifo_tx.flush()
    print("Wrote %02x" % (j))
    b = 0
    try_read = 500;
    while(try_read>0):
        c = fifo_rx.read(1)
        if(c!=None):
            b = int.from_bytes(c,"little")
            print("\t\t\tRead %02x" % (b))
            try_read = 0
        else:
            try_read = try_read-1;
            if(try_read<30):
                print("Read failed - retry")
                time.sleep(0.1)
            else:
                time.sleep(0.01)
    expect = j ^ 0x55
    if(b!=expect):
        print("ERROR: received %02x but expecting %02x" % (b, expect))
        error = True

if(error):
    print("Test result: FAIL")
else:
    print("Test result: PASS")
    
exit(0)
