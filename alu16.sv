module alu16

 #(parameter control_alu = 5)

 (input logic [15:0] a,b,input logic [control_alu-1:0] func,input logic [5:0] flagsin,output logic [5:0] flagsout,output logic [15:0] y);
 
 //ADD = 0,SUB,MUL,DIV,MOD,MVN,OR,AND,ORN,ANDN,EOR,EON,REV,LSL,LSR,ASR,NOP,CMP = 17



 always_comb begin

	flagsout = 'b0;
	y = 'b0;

	case(func)
	
		0: {flagsout[4],y} = a+b+flagsin[3]; // [0] Cin

		1: {flagsout[4],y} = a-b-flagsin[3];

		2: {flagsout[4],y} = a*b;

		3: {flagsout[4],y} = a/b;
		
		4: y = a%b;

		5: y = ~b;

		6: y = a|b;

		7: y = a&b;

		8: y = ~(a|b);

		9: y = ~(a&b);
		
		10: y = a^b;

		11: y = ~(a^b);

		12: begin
			y[7:0] = b[15:8];
			y[15:8] = b[7:0];
		    end
		13: {flagsout[3],y} = a << b;

		14: {flagsout[3],y} = a >> b;

		15: {flagsout[3],y} = a >>> b;

		16: y = y;

		17: begin

		flagsout[5] = (a == b);
		flagsout[2] = (y%2);
		flagsout[1] = (a>b);
		flagsout[0] = (a<b);// ZF,PF,GF,LF
		end

		default: begin
			y = 'b0;
			flagsout = 'b0;
		 end
	endcase

 end	 
 
  
endmodule

module tb_alu16;
//Inputs
 reg[15:0] a,b;
 reg[4:0] func;
 reg[5:0] flagsin;
//Outputs
 wire[5:0] flagsout;
 wire[15:0] y;
 // Verilog code for ALU
 integer i;
 alu16 test_unit(
            a,b,               
            func,
            flagsin,
            flagsout,
            y
     );
    initial begin
    // hold reset state for 100 ns.
      flagsin = 6'b0;
      a = 10000;
      b = 2;
      func = 5'h0;
      
      for (i=0;i<=15;i=i+1)
      begin
       #10;
       func = func + 5'h01;
       #10;
      end;
      
      a = 16'hF6;
      b = 16'h0A;
      
    end
endmodule