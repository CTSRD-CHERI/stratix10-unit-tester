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
# Build BSV test (TODO: and FPGA image)

SIM_NAME = FPGADebugInterface
RTL_PATH = ../bsv
TOP_RTL = ../tests/fpgadebuginterface/tst$(SIM_NAME).bsv
# Directory for generated Verilog version of the DUT (design under test)
DUT_DIR = ./dut_generated

VERILOG_INCLUDES =				\
	$(DUT_DIR)/mkFPGADebugInterface.v

TOP_MODULE = top

PYTHON_TESTER = ../tests/fpgadebuginterface/tstdebug.py

GENERIC_SIM_DIR = ./
IVERILOG_WRAPPER = wrapper-iverilog.v

IVERILOG_SIM  = $(DUT_DIR)/sim_$(TOP_MODULE)

BLUESPEC_INSTALL_ROOT = $(BLUESPEC)
BLUESPEC_VERILOG = $(BLUESPEC_INSTALL_ROOT)/lib/Verilog
BSV_LIBS = $(RTL_PATH)/*.bsv
BSC_FLAGS = -opt-undetermined-vals		\
	    -unspecified-to X			\
	    -aggressive-conditions		\
	    -D BSV_NO_INITIAL_BLOCKS		\
	    -verilog

VERILOG_SRC = DE10_Pro.v			\
	      $(wildcard Fan/*.v)

.PHONY: help
help:
	@echo "Build steps"
	@echo "0. Compile Bluespec design under test (DUT): compile_dut"
	@echo "1. Generate the FPGA image (also does step 0): make clean;make fpga_image"
	@echo "2. Program FPGA: make program_fpga"
	@echo "3. Run test: make test"
	@echo "Alternatively, do all of the above in one go (without make clean): make all"

.PHONY: all
all: compile_dut fpga_image program_fpga test

.phony: fpga_image
fpga_image: output_files/DE10_Pro.sof
output_files/DE10_Pro.sof: $(DUT_DIR)/$(TOP_MODULE).v $(VERILOG_SRC)
	quartus_sh --flow compile DE10_Pro.qpf

#-----------------------------------------------------------------------------
# compile the Bluespec design under test (DUT)
.phony: compile_dut
compile_dut: $(DUT_DIR)/$(TOP_MODULE).v
$(DUT_DIR)/$(TOP_MODULE).v: $(DUT_DIR) $(TOP_RTL) $(BSV_LIBS)
	bsc $(BSC_FLAGS) 				\
	    	-vdir $(DUT_DIR)			\
		-p +:$(RTL_PATH)                        \
	    	-g $(TOP_MODULE) -u $(TOP_RTL)

$(DUT_DIR):
	mkdir -p $(DUT_DIR)

#-----------------------------------------------------------------------------
# program the FPGA
.PHONY: program_fpga
program_fpga:
	quartus_pgm DE10_Pro.cdf

.PHONY: clean_fpga_download_hack
clean_fpga_download_hack:
	quartus_pgm ~/Projects/de10-soak-test-copy/de10-pro/output_files/DE10_Pro.cdf

#-----------------------------------------------------------------------------
# run a test
.PHONY: test
test: 
	python3 $(PYTHON_TESTER) --fpga

#-----------------------------------------------------------------------------
# clean up
clean:
	rm -rf $(DUT_DIR)
	rm -rf output_files tmp-clearbox qdb
	make -C $(RTL_PATH) clean
