module PipeReader_V
  (
   input 	CLK,
   input 	RST_N,
   input 	EN_GET,
   output [7:0] GET,
   output 	RDY_GET
   );

   reg [7:0] 	data;
   reg 		valid;
   
   integer fdr;
   integer c;
   initial begin
      fdr = $fopen("bytepipe-host2hw", "rb");
      valid <= 0;
   end

   assign RDY_GET = valid;
   assign GET = data;

   always @(posedge CLK)
     if(!RST_N)
       valid <= 1'b0;
     else
       if(valid && EN_GET)
	 valid <= 1'b0;
       else
	 begin
	    c = $fgetc(fdr);
	    if(c>=0)
	      begin
		 data <= c;
		 valid <= 1'b1;
	      end
	 end
endmodule
