module sim(output CLK, output RST_N);
   reg CLK;
   reg RST_N;

   top dut(CLK,RST_N);

   initial begin
      CLK <= 1'b0;
      RST_N <= 1'b0;
      #20 RST_N <= 1'b1;
   end

   always #5 CLK <= !CLK;
endmodule

   
   


