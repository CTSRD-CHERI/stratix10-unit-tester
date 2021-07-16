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
# Build simulation unit test

SIM_NAME = ChipID
RTL_PATH = ../../bsv
DE10_PATH = ../../de10
PATH_DE10_TO_HERE = ../tests/example_chip_id
TOP_RTL = tst$(SIM_NAME).bsv
TOP_MODULE = top
PYTHON_TESTER = read_chipid.py

# iverilog simulation directory:
SIMI_DIR = ./output_files

VERILOG_INCLUDES = $(SIMI_DIR)/mkFPGADebugInterface.v

GENERIC_SIM_DIR = ./
IVERILOG_WRAPPER = wrapper-iverilog.v

IVERILOG_SIM  = $(SIMI_DIR)/sim_$(TOP_MODULE)

BLUESPEC_INSTALL_ROOT = $(BLUESPEC)
BLUESPEC_VERILOG = $(BLUESPEC_INSTALL_ROOT)/lib/Verilog
BSV_LIBS = $(RTL_PATH)/*.bsv
BSC_SIM_FLAGS = -opt-undetermined-vals		\
		-unspecified-to X		\
		-aggressive-conditions		\
		-D BSV_NO_INITIAL_BLOCKS	\
		-D BSIM				\
		-verilog

IVERILOG_FLAGS = -DBSV_NO_INITIAL_BLOCKS -DBSIM

.PHONY: all
all: simi

.PHONY: test
test: simi
	@rm -f bytepipe-host2hw bytepipe-hw2host
	@mkfifo bytepipe-host2hw
	@mkfifo bytepipe-hw2host
	$(IVERILOG_SIM) > $(SIMI_DIR)/iverilog.log &
	python3 $(PYTHON_TESTER) --sim
	@rm bytepipe-host2hw bytepipe-hw2host

#-----------------------------------------------------------------------------
# iverilog simulation:
.PHONY: simi
simi: $(IVERILOG_SIM)

.PHONY: runsimi
runsimi: $(IVERILOG_SIM)
	rm -f bytepipe-host2hw bytepipe-hw2host
	mkfifo bytepipe-host2hw
	mkfifo bytepipe-hw2host
	@echo "RUN "$(PYTHON_TESTER)" TO PROVIDE INPUT STIUMOUS"
	$(IVERILOG_SIM)
	rm bytepipe-host2hw bytepipe-hw2host

$(IVERILOG_SIM): $(SIMI_DIR) $(SIMI_DIR)/$(TOP_MODULE).v $(GENERIC_SIM_DIR)/$(IVERILOG_WRAPPER) $(VERILOG_INCLUDES)
	cp $(GENERIC_SIM_DIR)/$(IVERILOG_WRAPPER) $(SIMI_DIR)
	iverilog $(IVERILOG_FLAGS) 			\
		 -y $(BLUESPEC_VERILOG) 		\
		 -o $(IVERILOG_SIM)			\
		 -p :./					\
		 -s sim 				\
		 wrapper-iverilog.v			\
		$(VERILOG_INCLUDES)			\
		 $(SIMI_DIR)/top.v

$(SIMI_DIR)/$(TOP_MODULE).v: $(SIMI_DIR) $(TOP_RTL) $(BSV_LIBS)
	bsc $(BSC_SIM_FLAGS) 				\
		-vsim iverilog				\
	    	-simdir $(SIMI_DIR)    			\
	    	-vdir $(SIMI_DIR)			\
		-p +:$(RTL_PATH)                        \
	    	-g $(TOP_MODULE) -u $(TOP_RTL)

$(SIMI_DIR):
	mkdir -p $(SIMI_DIR)

#-----------------------------------------------------------------------------
# clean up
.PHONY: clean
clean:
	rm -rf $(SIMI_DIR)
	rm -rf __pycache__
	rm -f *.bo
	make -C $(RTL_PATH) clean

#-----------------------------------------------------------------------------
# FPGA indirects
.PHONY:
fpga_build:
	make -C $(DE10_PATH) fpga_image 				\
		PYTHON_TESTER=$(PATH_DE10_TO_HERE)/$(PYTHON_TESTER) 	\
		TOP_RTL=$(PATH_DE10_TO_HERE)/$(TOP_RTL)			\
		TEST_PATH=$(PATH_DE10_TO_HERE)

.PHONY: program_fpga
program_fpga:
	make -C $(DE10_PATH) program_fpga

.PHONY: test_fpga
fpga_test:
	python3 $(PYTHON_TESTER) --fpga

.PHONY: fpga_clean
fpga_clean:
	make -C $(DE10_PATH) clean

