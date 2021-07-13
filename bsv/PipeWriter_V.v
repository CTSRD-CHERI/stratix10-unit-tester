module PipeWriter_V
  (
   input       CLK,
   input       RST_N,
   input [7:0] PUT,
   input       EN_PUT,
   output      RDY_PUT
   );

   integer fdw;
   initial begin
      fdw = $fopen("bytepipe-hw2host", "wb");
   end

   assign RDY_PUT = 1'b1;
   always @(posedge CLK)
     if(EN_PUT)
       begin
	  $fwrite(fdw, "%c", PUT);
	  $fflush(fdw);
       end
endmodule
