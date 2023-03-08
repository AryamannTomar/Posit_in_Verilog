
module Testbench();
  parameter N=16,ES=2;
  reg [0:N-1] A,B ;
  reg clk,reset;
  wire [0: N-1] OUT ;
  
  Posit_Multiplier Instance(A,B,clk, reset,OUT);
  
  initial clk=0;
  always #12 clk=~clk;
  
  initial 
    begin
      $dumpfile("dump.vcd");
        $dumpvars(1,Testbench);
      #50;
      reset = 1;
      A = 32'b0101111111111111/*1111111111111111*/ ;
      B = 32'b0101111111111111/*1111111111111111*/ ;
      #50;
      reset=0;

      A = 16'b0000000000000000/*0000000000000000*/ ;
      B = 16'b0000000000000000/*0000000000000000*/ ;
      #50;
      $display("output: %b", OUT);
    end

endmodule
  