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
# Build FPGA image and run test

# The following should be defined in the Makefile that calls this one:
#PYTHON_TESTER = ../tests/fpgadebuginterface/tstdebug.py
#TOP_RTL = tstFPGADebugInterface.bsv
#VERILOG_INCLUDES =				\
#	$(DUT_DIR)/mkFPGADebugInterface.v
#TEST_PATH = ../tests/fpgadebuginterface
# RTL_PATH =

RTL_PATH_FPGA_DEBUG = ../bsv
# Directory for generated Verilog version of the DUT (design under test)
DUT_DIR = ./dut_generated

# Name of top-level module from BSV DUT (assumption in DE10_Pro.v)
TOP_MODULE = top

GENERIC_SIM_DIR = ./
IVERILOG_WRAPPER = wrapper-iverilog.v

IVERILOG_SIM  = $(DUT_DIR)/sim_$(TOP_MODULE)

BLUESPEC_INSTALL_ROOT = $(BLUESPEC)
BLUESPEC_VERILOG = $(BLUESPEC_INSTALL_ROOT)/lib/Verilog
BSV_LIBS = $(RTL_PATH_FPGA_DEBUG)/*.bsv
BSC_FLAGS = -opt-undetermined-vals		\
	    -unspecified-to X			\
	    -aggressive-conditions		\
	    -D BSV_NO_INITIAL_BLOCKS		\
	    -verilog

VERILOG_SRC = DE10_Pro.v			\
	      $(wildcard Fan/*.v)

.PHONY: help
help:
	@echo "This Makefile is typically started by a ../tests/*/Makefile"
	@echo "Build steps:"
	@echo "0. Clean up: make clean"
	@echo "1. Compile Bluespec design under test (DUT): compile_dut"
	@echo "2. Generate the FPGA image (also does step 1): make fpga_image"
	@echo "3. Program FPGA: make program_fpga"
	@echo "4. Run test: make test"
	@echo "Alternatively, do all of the above in one go (without make clean): make all"

.PHONY: all
all: compile_dut fpga_image program_fpga test


#-----------------------------------------------------------------------------
# compile the Bluespec design under test (DUT)
.phony: compile_dut
compile_dut: $(DUT_DIR)/$(TOP_MODULE).v
$(DUT_DIR)/$(TOP_MODULE).v: $(DUT_DIR) $(TOP_RTL) $(BSV_LIBS)
	bsc $(BSC_FLAGS) 				\
	    	-vdir $(DUT_DIR)			\
		-p +:$(RTL_PATH_FPGA_DEBUG)             \
		-p +:$(RTL_PATH)                        \
		-p +:$(TEST_PATH)                       \
	    	-g $(TOP_MODULE) -u $(TOP_RTL)

$(DUT_DIR):
	mkdir -p $(DUT_DIR)

#-----------------------------------------------------------------------------
# build the FPGA image
#  - also generates IP required by DE10_Pro.qsf
.PHONY: fpga_image
fpga_image: output_files/DE10_Pro.sof

output_files/DE10_Pro.sof: $(DUT_DIR)/$(TOP_MODULE).v $(VERILOG_SRC) generate_ip
	quartus_sh --flow compile DE10_Pro.qpf

.PHONY: generate_ip
generate_ip:
	quartus_ipgenerate --generate_project_ip_files -synthesis=verilog DE10_Pro.qpf --clear_ip_generation_dirs

#-----------------------------------------------------------------------------
# program the FPGA
.PHONY: program_fpga
program_fpga:
	../py/flashDE10 output_files/DE10_Pro.sof

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
	rm -rf output_files tmp-clearbox qdb synth_dumps
	quartus_ipgenerate --clear_ip_generation_dirs DE10_Pro.qpf
	make -C $(RTL_PATH) clean
