# Generic Test Framework for DE10Pro Board

# Notes

* The Makefile compiles the design under test (DUT) and puts the generated code in dut_generated/
* Assumes the top-level DUT module is called "top"
* Project configurations assumes:
  * Quartus global library path includes the Bluespec Verilog libraries
  * Quartus local library path has been set to dut_generated/ to pull in any DUT files without
    needing to add the DUT files to the project

