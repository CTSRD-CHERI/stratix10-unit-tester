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
# Library to use the hardware FPGADebugInterface via Jtag Atlantic on FPGA

import intel_jtag_uart
import time

class pipe_interface:
    def __init__(self):
        self.uart = intel_jtag_uart.intel_jtag_uart()
        self.read_buf = []

    # send a byte over the communications channel
    def put_byte(self, b: int):
        self.uart.write(b.to_bytes(1,"little"))

    def get_byte_async(self):
        if(len(self.read_buf)==0):
            if(self.uart.bytes_available()>0):
                self.read_buf=list(self.uart.read())
                print("DEBUG: read in bytes: ")
                print(self.read_buf)
                print("DEBUG: read len: ",len(self.read_buf))
            else:
                return None
        first_byte = self.read_buf[0]
        self.read_buf.pop(0)
        print("DEBUG: get_byte_async returning: 0x%02x" % (first_byte))
        return first_byte

    def clear_read_buf(self):
        while(self.uart.bytes_available()>0):
            b = self.uart.read()
        self.read_buf=b''
        
    def get_byte(self):
        try_read = 1000
        c=None
        while(try_read>0):
            c = self.get_byte_async()
            if(c!=None):
                try_read = -1
            else:
                try_read = try_read-1;
                if(try_read<100):
                    time.sleep(0.1)
        if(try_read==0):
            print("Time out trying to read a byte over the debug channel")
        return c
