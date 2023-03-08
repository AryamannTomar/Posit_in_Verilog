
module Testbench();
  parameter N=32,ES=4;
  reg [0:N-1] a,b ;
  reg clk ,reset ;
  wire [0: N-1] out ;
  
  Posit_Adder Instance(a,b, clk,reset,out);
  
  initial clk=0;
  always #6 clk=~clk;
  
  initial 
    begin
      #500;
      reset = 1;
      /*a = 16'b0101111111111111;/*1111111111111111 ;*/
      /*b = 16'b0101111111111111;*//*1111111111111111 ;*/ 
      #5000;
      reset=0;

      a = 16'b01011111000000000000000000000000 ;
      b = 16'b10100101000000000000000000000000 ;
      #5000;
      $display("o: %b", out);
    end
  
endmodule
  