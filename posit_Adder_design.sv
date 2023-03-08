module twoscompl(a,out);
  parameter N = 32;
  input [N-1:0] a;
  output reg [N-1:0] out;
  reg [N-2:0]pseudo ;
  reg [N-2:0]pseudo2 ;
  
  always @*
    begin
      if ( a[N-1] )
        begin
          pseudo2 <= a[N-2:0];
          pseudo <= ~pseudo2+1'b1 ;
          out <= { a[N-1] , pseudo };
        end
      else 
        out <= a;
    end
endmodule

module twoscompl_k(a,out);
  parameter N = 32;
  input [N-1:0] a;
  output reg [N-1:0] out;
  reg [N-2:0]pseudo ;
  reg [N-2:0]pseudo2 ;
  
  always @*
    begin
      if ( a[N-1] )
        begin
          pseudo2 <= a[N-2:0];
          pseudo <= ~pseudo2+1'b1 ;
          out <= { a[N-1] , pseudo };
        end
      else 
        out <= a;
    end
endmodule

module operand(common_operand , carryx, final_expo,final_k );
  parameter N=32, ES=4;
  input [0:31]common_operand ;
  input [0:31] carryx;
  output [0:ES-1]final_expo;
  output [0:31]final_k;
  
  wire [0:31]final_operand; 
  
  wire [0:31]k_final ;
  wire [0:31] k_interim, k_interim2 , k_interim3 , k_interim5;
  wire [0:32] k_interim4 ;
  wire k_sign ;
   
  assign final_operand = common_operand + carryx ;
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
  parameter N=32;
  input [N-1:0]inp;
  output reg [31:0]k;
  output reg [31:0]arr;
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

module twoscompl_m(a,out);
  parameter M = 32,ES=4;
  parameter N=35;
  input [N-1:0] a;
  output reg [N-1:0] out;
  reg [N-2:0]pseudo ;
  reg [N-2:0]pseudo2 ;
  
  always @*
    begin
      if ( a[N-1] )
        begin
          pseudo2 <= a[N-2:0];
          pseudo <= ~pseudo2+1'b1 ;
          out <= { a[N-1] , pseudo };
        end
      else 
        out <= a;
    end
endmodule
////////////////////////////////////////////////////////

module mantisa(mantisa_a, mantisa_b, ext_a , ext_b , sign_a,sign_b,sign_out, carryx, mantisa_out);
  parameter N=32, ES=4 ;
  input [0:N-1]mantisa_a, mantisa_b;
  input [0:31]ext_a ,ext_b ;
  input sign_a , sign_b;
  output [0:31]carryx ;
  output sign_out ;
  output [0:N-1]mantisa_out;
  reg [0:31]carryx_i ;
  reg [0:N+1]mantisa_out_i ;
  wire [0:N+1]x;
  wire [0:N+1]y;
  wire [0:N+2] x_final ;
  wire [0:N+2] y_final ;
  wire [0:N+2] x_zz ;
  wire [0:N+2] y_zz ;
  wire [0:N+2] z    ;
  wire [0:N+2] z_zz ;
  wire [0:N+1] z_nn ;
  assign x = { 1'b0 , 1'b1, mantisa_a[0:N-1] }>>ext_a ;
  assign y = { 1'b0 , 1'b1, mantisa_b[0:N-1] }>>ext_b ;
  assign x_final = { sign_a , x } ;
  assign y_final = { sign_b , y } ;
  
  twoscompl_m a1( x_final ,x_zz ); 
  twoscompl_m a2( y_final ,y_zz );
  
  assign z = x_zz + y_zz ;
  twoscompl_m a3( z , z_zz) ;  
  assign sign_out = z_zz[0];
  assign z_nn = z_zz[1:N+1] <<1 ;

  integer index = 0 ;
  integer flag = 0 ;
  integer i ;
  always @* 
    begin
        for (i=0 ; i< (N+2) ; i=i+1 ) 
          begin 
            if(flag == 0)
              begin
                if (z_nn[i] == 0)
                  index = index+1 ;
                else 
                  begin 
                    if (z_nn[i] == 1)
                      begin
                        index = index + 1 ;
                        flag = flag + 1 ;
                      end
                  end
              end
            else
              index = index + 0 ;
          end
      carryx_i = 32'b0000_0000_0000_0000_0000_0000_0000_0010  - index ;
      mantisa_out_i = z_nn<<index ;
      index =0 ;
      i =0     ;
      flag = 0 ;
    end
  
  assign carryx = carryx_i ;
  assign mantisa_out = mantisa_out_i[0:N-1] ;
endmodule
///////////////////////////////////////////////////////
module k_to_regime(k,regime);
  parameter N= 32 ;
  input [0:31]k;
  output [0:N-1]regime ;
  wire sign ;
  wire [0:31]magnitude ;
  wire [0:31]magnitude2 ;
  wire [0:31]magnitude3 ;
  reg [0:N-1]r ;
  
  assign sign =  k [0] ;
  
  twoscompl_k a1(k , magnitude3 );
  assign magnitude = magnitude3<<1;
  assign magnitude2 = magnitude>>1; 

  genvar i3 ;
  generate
    //begin : Regime
      for (i3 =0 ; i3<N ; i3=i3+1 )
      begin: Regime
        always @(*)        // always added 
        begin
            r[i3] <= 1'b0 ;
        end
      end 
    //end
  endgenerate
  integer i1 = 0 ;
  integer i2 = 0 ;
  integer i;
 always @*
    begin
      if (sign)
        r[magnitude2] = 1'b1 ;
      else
      
        begin
        
          for (i =0 ; i<32 ; i=i+1)
            begin
              //i2=i2+1;
              r[i] = 1'b1 ;
            end
          //i2=i2+1 ;
          r[magnitude2+1] = 1'b0 ;
        end
            
    end
  
  assign regime = r  ;  
endmodule
/////////////////////////////////////////////////////   
module sub_Posit_Adder(sign_a, sign_b,expo_a,expo_b, k_a,k_b,mantisa_a, mantisa_b, Final_posit);
  parameter N=32, ES =4;
  input sign_a,sign_b;
  input [0:ES-1] expo_a;
  input [0:ES-1] expo_b;
  input [0:31]k_a;
  input [0:31]k_b;
  input [0:N-1]mantisa_a, mantisa_b;
  wire [0:31]carryx;
  wire sign_out;
  wire [0:ES-1]final_expo;
  wire [0:31]final_k;
  wire [0:N-1]mantisa_out;
  wire [0:N-1]regime_out ;
  wire [0:31]   final_regime_len ;
  wire [0:31]   dummy_k ;
  wire [0:N-1] A ;
  wire [0:N-1]      A_rshift ;
  wire [0: 2*N +ES] A_big ;
  wire [0: 2*N +ES]      A_reqd ;
  output [0:N-1]Final_posit;
  wire [0:31]operand_a ;
  wire [0:31]operand_b ;
  wire [0:31]common_operand ;
  wire [0:31]ext_a ;
  wire [0:31]ext_b ;
  wire [0:31] op_a1;
  wire [0:31] op_b1;
  wire sign_op_a1,sign_op_b1;
  reg [0:31] common_operand_1;
  
  assign operand_a = expo_a + (2**ES)*(k_a) ;
  assign operand_b = expo_b + (2**ES)*(k_b) ;

  twoscompl_k j1(operand_a, op_a1);
  twoscompl_k m1(operand_b, op_b1);
  
  assign sign_op_a1 = op_a1[0];
  assign sign_op_b1 = op_b1[0];
  
  always @*
    begin 
      if(sign_op_a1==1 && sign_op_b1==0)
          common_operand_1 = operand_b;
      else if (sign_op_a1==0 && sign_op_b1==1)
        common_operand_1 = operand_a;
      else if(sign_op_a1==0 && sign_op_b1==0)
        common_operand_1 = (op_a1 > op_b1 )? operand_a : operand_b ;
      else if(sign_op_a1==1 && sign_op_b1==1)
        common_operand_1 = (op_a1 < op_b1 )? operand_a : operand_b ; 
    end
  
  assign common_operand = common_operand_1 ;
  assign ext_a = common_operand - operand_a ;
  assign ext_b = common_operand - operand_b ;

  mantisa     a1 (mantisa_a, mantisa_b, ext_a , ext_b , sign_a,sign_b,sign_out, carryx, mantisa_out);
  operand     a2 (common_operand ,carryx, final_expo,final_k);
  k_to_regime a3 (final_k , regime_out) ;

  assign A = { sign_out , regime_out[0:N-2] } ;
  regime_bit_detector a4(A, dummy_k , final_regime_len) ;
  assign A_rshift = A>>(N - final_regime_len -1'b1);
  assign A_big = { A_rshift , final_expo , mantisa_out } ;
  assign A_reqd = A_big<<(N - final_regime_len)  ;
  assign Final_posit = A_reqd[0:N-1] ;
endmodule
////////////////////////////////////////////////////
module extraction(inpt, r, sign, exp,frac);
  parameter N=32,ES=4 ;
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
module Posit_Adder(A1,B1,clk, reset,OUT);
  parameter N=32,ES=4;
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
  wire [0:31]r_a, r_b ;
  
  twoscompl a1(a,A);
  twoscompl a2(b,B);
  
    
  regime_bit_detector a3(A, k_a , r_a); 
  regime_bit_detector a4(B, k_b , r_b); 
  
  extraction a5(A, r_a, sign_a, expo_a, mantisa_a);
  extraction a6(B, r_b, sign_b, expo_b, mantisa_b);
  
  sub_Posit_Adder  a7(sign_a, sign_b,expo_a,expo_b, k_a,k_b,mantisa_a, mantisa_b, Final_posit);
  twoscompl a12(Final_posit,Final_posit_perfect);
  
  //assign out =  Final_posit_perfect;
  
  always @(posedge clk)
    begin
      if(A=='b0)
        out <= b;
      else if(B=='b0)
        out <= a;
      else if((a[0]==1'b1 & a[1:N-1]=='b0) | (b[0]==1'b1 & b[1:N-1]=='b0) )
        out <= 1'b1 << (N-1);  
      
      else if(A[1:N-1]==B[1:N-1] & A[0]==!B[0])
        begin
          out <= 'b0;
        end
      else
        begin
          out <= Final_posit_perfect;
        end
    end
  
endmodule

