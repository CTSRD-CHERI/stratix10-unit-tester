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
   reg [11:0] 	read_slow_down;  // HACK: avoid blocking on $fgetc when other work needs to be done
   
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
       begin
	  valid <= 1'b0;
	  read_slow_down <= 0;
       end
     else
       if(valid && EN_GET)
	 valid <= 1'b0;
       else
	 begin
	    read_slow_down <= read_slow_down+1;
	    if(read_slow_down==0)
	      begin
		 c = $fgetc(fdr);  // TODO: this appears to be blocking despite the named pipe being setup non-blocking
		 if(c<0) $finish(0);
		 if(c>=0)
		   begin
		      data <= c;
		      valid <= 1'b1;
		   end
	      end
	 end // else: !if(valid && EN_GET)

endmodule
