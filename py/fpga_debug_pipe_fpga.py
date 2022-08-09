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
# Library to use the hardware FPGADebugInterface via Jtag Atlantic on FPGA

import intel_jtag_uart
import time
from functools import reduce

class pipe_interface:
    def __init__(self, cable_name = None, device_nr = -1, instance_nr = -1):
        print("DEBUG: cable_name=%s, device_nr=%d, instance_nr=%d"%("None" if cable_name==None else cable_name,device_nr,instance_nr))
        self.uart = intel_jtag_uart.intel_jtag_uart(cable_name = cable_name, device_nr = device_nr, instance_nr = instance_nr)
        self.read_buf = list()

    def calc_checksum(self, packet_list) -> int:
        return reduce(lambda a,b: a+b, packet_list + [0x55,0x00]) & 0xff
    
    def put_bytes(self, bytes_list):
        self.uart.write(bytes(bytes_list))

    def get_bytes(self, nbytes):
        try_read = 1000
        while((len(self.read_buf) < nbytes) and (try_read>0)):
            try_read = try_read-1
            if(self.uart.bytes_available()>0):
                new_bytes = list(self.uart.read())
                self.read_buf = self.read_buf + new_bytes
                try_read = -1
            else:
                time.sleep(0.1 if try_read<20 else 0.01)
        if(len(self.read_buf) >= nbytes):
            r = self.read_buf[0:nbytes]
            self.read_buf = self.read_buf[nbytes:]
            return r
        else:
            raise PipeReadError

    def clear_read_buf(self):
        while(self.uart.bytes_available()>0):
            b = self.get_bytes(self.uart_bytes_available())
        
class PipeReadError(Exception):
    pass
