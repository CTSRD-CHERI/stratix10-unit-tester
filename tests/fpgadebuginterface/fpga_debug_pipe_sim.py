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
# Library to use the hardware FPGADebugInterface comms pipe in simulation

import os
import fcntl
import time
from enum import Enum

# default pipe FIFO names in the file system
FIFO_PY2V = 'bytepipe-host2hw'
FIFO_V2PY = 'bytepipe-hw2host'

class pipe_interface:
    def __init__(self):
        self.fifo_tx = open(FIFO_PY2V,'wb')
        self.fifo_rx = open(FIFO_V2PY,'rb', buffering=0)
        fd_rx = self.fifo_rx.fileno()
        flag_rx = fcntl.fcntl(fd_rx, fcntl.F_GETFL)
        fcntl.fcntl(fd_rx, fcntl.F_SETFL, flag_rx | os.O_NONBLOCK | os.O_ASYNC)
        fd_tx = self.fifo_tx.fileno()
        flag_tx = fcntl.fcntl(fd_tx, fcntl.F_GETFL)
        fcntl.fcntl(fd_tx, fcntl.F_SETFL, flag_tx | os.O_NONBLOCK | os.O_ASYNC)

    # send a byte over the communications channel
    def put_byte(self, b: int):
        self.fifo_tx.write(b.to_bytes(1,"little"))
        self.fifo_tx.flush()

    def get_byte_async(self):
        return self.fifo_rx.read(1)  # returns None if nothing to read

    def clear_read_buf(self):
        for try_read in range(100):
            c = self.get_byte_async()
            time.sleep(0.01)
        
    def get_byte(self):
        try_read = 1000
        # self.put_byte(0);  # HACK!!! - unblock $fgetc() in PipeReader_V.v
        while(try_read>0):
            c = self.get_byte_async()
            if(c!=None):
                b = int.from_bytes(c,"little")
                try_read = -1
            else:
                try_read = try_read-1;
                if(try_read<100):
                    time.sleep(0.1)
                else:
                    time.sleep(0.01)
        if(try_read==0):
            print("Failed to read a byte over the debug channel")
        if(c!=None):
            i = int.from_bytes(c,"little")
            return i
        else:
            return None
