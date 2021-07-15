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

    def assert_checksum(self, packet_list, error_message):
        checksum = self.pipe.calc_checksum(packet_list[0:-1])
        if(checksum != packet_list[-1]):
            print(error_message)
            
    def put_command(self, cmd: DebugCommand, index: int, data: int):
        packet = [cmd.value, index]+list(data.to_bytes(8,"big"))
        checksum = self.pipe.calc_checksum(packet)
        # print("DEBUG: put_command sending: [",", ".join(list(map(lambda a: "0x%02x"%(a), packet+[checksum]))),"]")
        self.pipe.put_bytes(packet+[checksum])

    def get_response_code(self):
        resp = self.pipe.get_bytes(2)
        code = DebugResponseCode(resp[0])
        self.assert_checksum(resp, "ERROR: checksum failed on get_response_code")
        return code

    def write(self, index: int, data: int):
        self.put_command(DebugCommand.Cmd_write_word, index, data)
        code = self.get_response_code()
        if(code != DebugResponseCode.Rsp_write_ack):
            print("ERROR write failed - received response: ",code)
            
    def read(self, index: int) -> int:
        self.put_command(DebugCommand.Cmd_read_word, index, 0)
        resp = self.pipe.get_bytes(10)
        code = DebugResponseCode(resp[0])
        if(code != DebugResponseCode.Rsp_read_data):
            print("ERROR read failed - received response: ",code)
            return None
        else:
            self.assert_checksum(resp,"ERROR checksum error for read()")
            return int.from_bytes(bytes(resp[1:9]),"big")

    def clear(self):
        self.pipe.put_bytes([0]*12)
        self.pipe.clear_read_buf()

    def end_simulation(self):
        if(self.sim_mode):
            self.put_command(DebugCommand.Cmd_end_sim, 0, 0)
