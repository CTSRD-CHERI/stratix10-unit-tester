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
# Build ChipIP tester
# FPGA only, no simulation

TEST_NAME = ChipID
RTL_PATH = ../../bsv
DE10_PATH = ../../de10
PATH_DE10_TO_HERE = ../tests/example_chip_id
TOP_RTL = tst$(TEST_NAME).bsv
TOP_MODULE = top
INTEL_IP = chipid.ip
PYTHON_TESTER = read_chipid.py

#-----------------------------------------------------------------------------
# help
.PHONY: help
help:
	@echo "Build sequence:"
	@echo "  make clean"
	@echo "  make fpga_build"
	@echo "  make program_fpga"
	@echo "  make fpga_test"
	@echo "To do all of these:"
	@echo "  make all"

#-----------------------------------------------------------------------------
# all
.PHONY: all
all: clean fpga_build program_fpga fpga_test

#-----------------------------------------------------------------------------
# clean up
.PHONY: clean
clean: fpga_clean
	rm -rf __pycache__
	rm -f *.bo
	make -C $(RTL_PATH) clean

#-----------------------------------------------------------------------------
# FPGA indirects

# Build FPGA image
.PHONY:
fpga_build:
	cp dutip.qsf $(INTEL_IP) $(DE10_PATH)/
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

