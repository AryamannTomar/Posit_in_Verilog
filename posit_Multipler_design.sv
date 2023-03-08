//                 TO DO                      

//          Test cases and Run                


///////////////////////////////////////////////////////////////////////////////////////////////////////
module twoscompl(a,out);
  parameter N = 16;
  input [N-1:0] a;
  output reg [N-1:0] out;
  reg [N-2:0]pseudo ;
  reg [N-2:0]pseudo2 ;
  
  always @*
    begin
      if ( a[N-1] )
        begin
          assign pseudo2 = a[N-2:0];
          assign pseudo = ~pseudo2+1'b1 ;
          assign out = { a[N-1] , pseudo };
        end
      else 
        assign out = a;
      
    end
endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////

// operand module
module twoscompl_k(a,out);
  parameter N = 32; // not for parameterization.
  input [N-1:0] a;
  output reg [N-1:0] out;
  reg [N-2:0]pseudo ;
  reg [N-2:0]pseudo2 ;
  
  always @*
    begin
      if ( a[N-1] )
        begin
          assign pseudo2 = a[N-2:0];
          assign pseudo = ~pseudo2+1'b1 ;
          assign out = { a[N-1] , pseudo };
        end
      else 
        assign out = a;
    end
endmodule


module operand(expo_a,expo_b, k_a,k_b,carryx, final_expo,final_k);
  parameter N=16, ES=2;
  input [0:ES-1] expo_a;
  input [0:ES-1] expo_b;
  input [0:31]k_a;
  input [0:31]k_b;
  input carryx;
  output [0:ES-1]final_expo;
  output [0:31]final_k;
  wire [0:31]final_operand;
  
  wire [0:31] k_final ;
  wire [0:31] k_interim, k_interim2 , k_interim3 , k_interim5;
  wire [0:32] k_interim4 ;
  wire k_sign ;

  assign final_operand = expo_a+expo_b+carryx+(2**ES)*(k_a+k_b);
  assign final_expo = final_operand%(2**ES);

  twoscompl_k a1( final_operand , k_interim );
  assign k_sign = k_interim[0] ;
  assign k_interim2 = k_interim << 1'b1 ; 
  assign k_interim3 = k_interim2 >> (ES) ;
  assign k_interim4 = { k_sign , k_interim3}>> 1'b1 ;
  assign k_interim5 = k_interim4 [1:32] ;

  twoscompl_k a2(k_interim5, k_final);  
  assign final_k = k_final ;
endmodule

module regime_bit_detector(inp, k, arr);
  parameter N=16;
  input [N-1:0]inp;
  output reg [31:0]k;
  output reg [9:0]arr;
  integer flag=0;
  integer count=0;
  integer i;
  always @(inp)
    begin
      for(i=N-2; i>0; i=i-1)
        begin
          if (inp[i]==1'b1)
            begin
              if (flag==0)
                begin
                  count=count+1;
                  if (inp[i-1]==1'b0)
                    begin
                      flag=1;
                      arr=count+1'b1;                     
                    end
                end
            end
          else if (inp[i]==1'b0)
            begin
              if (flag==0)
                begin
                  count=count+1;
                  if (inp[i-1]==1'b1)
                    begin
                      flag=1;
                      arr=count+1'b1;
                    end
                end
            end
        end
      if (inp[N-2]==1'b1)
        k = {1'b0,count-1'b1};
      else if (inp[N-2]==1'b0)
        k = {1'b1,~count+1'b1}; 
      flag = 0;
      count = 0;
    end
endmodule 



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module mantisa(mantisa_a, mantisa_b, carryx, mantisa_out);
  parameter N=16 , ES=2 ;
  input [0:N-1]mantisa_a, mantisa_b;
  output reg carryx;
  output reg [0:N-1]mantisa_out;
  wire [0:N]x;
  wire [0:N]y;
  wire [0:2*N+1]z;
  assign x = {1'b1, mantisa_a[0:N-1] };
  assign y = {1'b1, mantisa_b[0:N-1] };
  assign z = x*y;
  
  assign carryx = z[0] ;
  
  always @*
    begin
      case (carryx)
        1'b1 : mantisa_out <= z[1:N] ;
        1'b0 : mantisa_out <= z[2:N+1]  ; 
      	default : mantisa_out <= 32'b0 ;
      endcase

    end


 
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module k_to_regime(k,regime);
  parameter N= 16 ;
  input [0:31]k;
  output [0:N-1]regime ; 

  reg sign ;
  wire [0:31]magnitude ;
  wire [0:31]magnitude2 ;
  wire [0:31]magnitude3 ;
  reg [0:N-1]r ;
  
  assign sign =  k [0] ;
  
  twoscompl_k a1(k , magnitude3 );
  assign magnitude = magnitude3<<1;
  assign magnitude2 = magnitude>>1; 
  
  //always @* $display("f :%b" , magnitude3) ;
  
  genvar i3 ;
  generate
    begin : Regime
      for (i3 =0 ; i3<N ; i3++ )
        assign r[i3] = 'b0 ;
    end
  endgenerate
  
  integer i1 = 0 ;
  integer i2 = 0 ;
  
  always @*
    begin
      if (sign)
        r[magnitude2] = 1'b1 ;
      else
        begin
          for (int i =0 ; i<magnitude2+1 ; i++ /*,i2++*/ )
            begin
              r[i] = 1'b1 ;
            end
          /*i2++ ;
          r[i2] = 1'b0 ;*/
        end
    end
  
  assign regime = r  ;
  
endmodule
   

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module sub_Posit_Multiplier(sign_a, sign_b,expo_a,expo_b, k_a,k_b,mantisa_a, mantisa_b, Final_posit);
  parameter N=16, ES =2;
  input sign_a,sign_b;
  input [0:ES-1] expo_a;
  input [0:ES-1] expo_b;
  input [0:31]k_a;
  input [0:31]k_b;
  input [0:N-1]mantisa_a, mantisa_b;
  wire carryx;
  wire sign_out;
  wire [0:ES-1]final_expo;
  wire [0:31]final_k;
  wire [0:N-1]mantisa_out;
  wire [0:N-1]regime_out ;
  wire [0:9]   final_regime_len ;
  wire [0:31]   dummy_k ;
  wire [0:N-1] A ;
  wire [0:N-1] A_rshift ;
  wire [0: 2*N +ES] A_big ;
  wire [0:2*N +ES] A_reqd ;
  output [0:N-1]Final_posit;
  
  xor x11(sign_out,sign_a,sign_b);
  
  mantisa     a1 (mantisa_a, mantisa_b, carryx, mantisa_out);
  operand     a2 (expo_a,expo_b, k_a,k_b,carryx, final_expo,final_k);
  k_to_regime a3 (final_k , regime_out) ;
  
  assign A = { sign_out , regime_out[0:N-2] } ;
  
  regime_bit_detector a4(A, dummy_k , final_regime_len) ;
  
  assign A_rshift = A>>(N - final_regime_len - 1'b1 );
  assign A_big = { A_rshift , final_expo , mantisa_out } ;
  assign A_reqd = A_big<<(N - final_regime_len ) ;
  assign Final_posit = A_reqd[0:N-1] ;
  
  //always @* $display("f :%b" , final_k) ;
  
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Code your design here
module extraction(inpt, r, sign, exp,frac);
  parameter N=16,ES=2 ;
  input [N-1:0]inpt;
  input [9:0]r ;
  output sign;
  output [ES-1:0]exp;
  output [N-1:0]frac;
  
  wire [N-1:0]inpt1,inpt2 ;
  
  assign sign = inpt[N-1];
 
  assign inpt1 = inpt<<(1+r) ;
  assign exp = inpt1[N-1:N-ES];
  
  assign inpt2 = inpt1<<ES ;
  assign frac = inpt2;
  
endmodule 

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module Posit_Multiplier(A1,B1,clk, reset,OUT);
  parameter N=16,ES=2;
  input [0:N-1] A1,B1 ;
  input clk, reset;
  output reg [0: N-1] OUT ;
  reg [0:N-1] a,b ;
  reg [0: N-1] out ;
 
  always@(posedge clk) begin
    if(reset) begin
      a<=32'b0;
      b<=32'b0;
      OUT<=32'b0;
    end
    else begin
      a<=A1;
      b<=B1;
      OUT<=out;
    end
  end
  wire sign_a,sign_b;
  wire [0:ES-1] expo_a;
  wire [0:ES-1] expo_b;
  wire [0:31] k_a;
  wire [0:31] k_b;
  wire [0:N-1] mantisa_a, mantisa_b;
  wire [0:N-1]Final_posit ;
  wire [0:N-1]Final_posit_perfect ;
  wire [0:N-1]A;
  wire [0:N-1]B;
  wire [0:9]r_a, r_b ;
  
  twoscompl a1(a,A);
  twoscompl a2(b,B);
  regime_bit_detector a3(A, k_a , r_a); 
  regime_bit_detector a4(B, k_b , r_b); 

  extraction a5(A, r_a, sign_a, expo_a, mantisa_a);
  extraction a6(B, r_b, sign_b, expo_b, mantisa_b);

  sub_Posit_Multiplier  a7(sign_a, sign_b,expo_a,expo_b, k_a,k_b,mantisa_a, mantisa_b, Final_posit);
  twoscompl a12(Final_posit,Final_posit_perfect);
  
  
  //assign out =  Final_posit_perfect;
    always @(*)
    begin
      if(a=='b0 || b=='b0)
        out <= 'b0;
      else if((a[0]==1 && a[1:N-1]=='b0) || (b[0]==1 && b[1:N-1]=='b0) )
        out <= 1'b1 << (N-1);  
      else
        begin
          out <= Final_posit_perfect;
        end
    end
  
  
  
endmodule

