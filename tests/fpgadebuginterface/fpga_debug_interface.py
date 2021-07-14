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

import fpga_debug_pipe_sim
import fpga_debug_pipe_fpga
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

class debug_interface:
    def __init__(self, sim=True):
        self.sim_mode = sim
        if(sim):
            self.pipe = fpga_debug_pipe_sim.pipe_interface()
        else:
            self.pipe = fpga_debug_pipe_fpga.pipe_interface()

    # send a byte over the communications channel
    def put_byte(self, b: int):
        self.pipe.put_byte(b)
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

    def get_byte(self):
        b = self.pipe.get_byte()
        print("DEBUG: get_byte = 0x%02x" % b)
        return b

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
        while(code == DebugResponseCode.Rsp_nop):
            code = self.get_response_code()
            code = self.get_response_code()
        if(code != DebugResponseCode.Rsp_write_ack):
            print("DEBUG: write failed - received response: ",code)
        checksum = self.get_byte()
        if(checksum != self.get_response_checksum):
            print("DEBUG: checksum error")
            
    def read(self, index: int) -> int:
        self.put_command(DebugCommand.Cmd_read_word, index, 0)
        code = self.get_response_code()
        while(code == DebugResponseCode.Rsp_nop):
            code = self.get_response_code()
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

    def clear(self):
        for j in range(12):
            self.put_byte(0)
        self.pipe.clear_read_buf()

    def end_simulation(self):
        if(self.sim_mode):
            self.put_command(DebugCommand.Cmd_end_sim, 0, 0)
