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
# Library to use the hardware FPGADebugInterface

import os
import fcntl
import time
from enum import Enum

# classes to match the command and response codes in FPGADebugInterface
class DebugCommand(Enum):
    Cmd_nop           =   0
    Cmd_reset         =   1
    Cmd_write_word    =   2
    Cmd_read_word     =   3
    Cmd_end_sim       = 254
    Cmd_invalid       = 255

class DebugResponseCode(Enum):
    Rsp_nop           =   0
    Rsp_reset_done    =   1
    Rsp_write_ack     =   2
    Rsp_read_data     =   3
    Rsp_checksum_fail = 254
    Rsp_invalid       = 255

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
        print("DEBUG: put_byte 0x%02x" % (b))

    def put_command(self, cmd: DebugCommand, index: int, data: int):
        checksum = (0x55 + cmd.value + index) & 0xff
        self.put_byte(cmd.value)
        self.put_byte(index)
        for j in range(8):
            b = data >> (64-8)
            self.put_byte(b)
            checksum = checksum+b
            data = data<<8
        self.put_byte(checksum)

    def get_byte_async(self):
        return self.fifo_rx.read(1)  # returns None if nothing to read

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
        if(try_read==0):
            print("Failed to read a byte over the debug channel")
        if(c!=None):
            i = int.from_bytes(c,"little")
            print("DEBUG: get_byte = 0x%02x" % (i))
            return i
        else:
            return None

    def get_response_code(self):
        b = self.get_byte()
        #print("DEBUG: Response byte: ",b)
        code = DebugResponseCode(b)
        #print("DEBUG: Response code: ",code)
        self.get_response_checksum = (0x55 + code.value) & 0xff
        return code

    def get_response_data(self):
        d = 0;
        for j in range(8):
            b = self.get_byte()
            d = d<<8 | b
            self.get_response_checksum = self.get_response_checksum + b
        return d

    def write(self, index: int, data: int):
        self.put_command(DebugCommand.Cmd_write_word, index, data)
        code = self.get_response_code()
        if(code != DebugResponseCode.Rsp_write_ack):
            print("DEBUG: write failed - received response: ",code)
        checksum = self.get_byte()
        if(checksum != self.get_response_checksum):
            print("DEBUG: checksum error")
            
    def read(self, index: int) -> int:
        self.put_command(DebugCommand.Cmd_read_word, index, 0)
        code = self.get_response_code()
        if(code != DebugResponseCode.Rsp_read_data):
            print("DEBUG: read failed - received response: ",code)
            #################### TODO: drain recieve buffer?
            return None
        else:
            d = self.get_response_data()
            cs = self.get_byte()
            if(cs != self.get_response_checksum):
                print("DEBUG: checksum error")
            return d
        
    def end_simulation(self):
        self.put_command(DebugCommand.Cmd_end_sim, 0, 0)
