
`ifndef PARAMETER_H_
`define PARAMETER_H_
// fpga4student.com 
// FPGA projects, VHDL projects, Verilog projects 
// Verilog code for RISC Processor 
// Parameter file
`define col 16 // 16 bits instruction memory, data memory
`define row_i 15 // instruction memory, instructions number, this number can be changed. Adding more instructions to verify your design is a good idea.
`define row_d 8 // The number of data in data memory. We only use 8 data. Do not change this number. You can change the value of each data inside test.data file. Total number is fixed at 8. 
`define filename "./test/test_file1.o"
`define simulation_time #160

`endif
module ERM16_microprocessor (input logic init,clk,input logic [15:0] DI,output logic [15:0] ADDR_BUS,DO,output logic wrmem,ioe,intreq);

// data_wires
logic [15:0] WD3,RD1,RD2;
logic [6:0] q_ir;
logic [8:0] q_op;

logic [15:0] imm,a,b,ALUresult;

logic [15:0] DI_PC,DO_PC;

logic [2:0] A1,A3;

logic [2:0] raf_const;

logic [15:0] w1,w2;


logic [15:0] A_ALU,B_ALU;

logic [5:0] flags_in,flags_out;


 // control signals/wires
 
logic decodeinstr,we3,rst,hlt,wrpc,prefix,jump,ch,ret,wrflags,seladdr,state_flag_bit;

 logic [5:0] Jcc;
 logic [4:0] func;
 logic [2:0] stwr;
 
 logic [1:0] spc_a;
 
 logic [2:0] spc_b;
 
 logic [15:0] w_ALUresult;

 logic stk_push, stk_pop;
logic stk_busy, stk_pop_valid;
logic [15:0] stk_addr, stk_wdata, stk_pop_data, sp_value;
logic stk_we;

logic stack_owns_bus;


 
 // start description ERM16

register #(7) IR(DI[15:9],clk,rst,~hlt|decodeinstr,q_ir);

register #(9) AR(DI[8:0],clk,rst,~hlt|decodeinstr,q_op);


muxN #(16,5,3) mux4({DI,a,b,imm,w_ALUresult},stwr,WD3);

assign raf_const = 3'b111; 

muxN #(3) mux_A1 ({raf_const,q_op[8:6]},ret,A1);

muxN #(3) mux_A3 ({raf_const,q_op[8:6]},ch,A3);

reg_file regfile(A1,q_op[5:3],A3,we3,clk,rst,WD3,RD1,RD2);

extension ext16(q_op[5:0],imm);

register #(16*2) DR({RD1,RD2},clk,rst,~hlt,{a,b});

muxN #(16,2,2) mux_spc_a ({DO_PC,a},spc_a,A_ALU);

muxN #(16,3,3) mux_spc_b ({16'b010,imm,b},spc_b,B_ALU);

alu16 ALU(A_ALU,B_ALU,func,flags_out,flags_in,ALUresult);

latch_mem save_aluresultREG(ALUresult,rst,~wrpc,w_ALUresult);

register flags(flags_in,clk,rst,wrflags,flags_out);

muxflags mux_Jcc(flags_out,Jcc[2:0],state_flag_bit);

muxN mux_prefix({imm,a},prefix,w1);

muxN mux_jump({w1,w_ALUresult},jump,DI_PC);

register #(16) PC(DI_PC,clk,rst,wrpc,DO_PC);

muxN mux_sel_addr ({b,DO_PC},seladdr,w2);

logic [15:0] ADDR_BUS_cpu, DO_cpu;

register #(16) ARR(w2,clk,rst,~hlt,ADDR_BUS_cpu);
register #(16) MD(a,clk,rst,~hlt,DO_cpu);


stack16_sync #(.SP_RESET(16'hFFFE)) stack_u (
  .clk       (clk),
  .rst_n     (~rst),          // rst-ul tău e activ pe 1, aici vrem activ-low

  .push      (stk_push),
  .pop       (stk_pop),
  .push_data (a),             // ce pui pe stack: RD1 latch-uit în 'a'

  .mem_we    (stk_we),
  .mem_addr  (stk_addr),
  .mem_wdata (stk_wdata),
  .mem_rdata (DI),

  .sp        (sp_value),
  .pop_data  (stk_pop_data),  // optional (nu e obligatoriu dacă scrii din DI)
  .pop_valid (stk_pop_valid),
  .busy      (stk_busy)
);


logic cpu_wrmem;



control_unit cb(
  .opcode(q_ir),
  .clk(clk),
  .state_flag_bit(state_flag_bit),
  .init(init),

  .stk_pop_valid(stk_pop_valid),

  .wrmem(cpu_wrmem),
  .ioe(ioe),
  .intreq(intreq),
  .decodeinstr(decodeinstr),
  .we3(we3),
  .rst(rst),
  .hlt(hlt),
  .wrpc(wrpc),
  .prefix(prefix),
  .jump(jump),
  .ch(ch),
  .ret(ret),
  .wrflags(wrflags),
  .seladdr(seladdr),

  .stk_push(stk_push),
  .stk_pop(stk_pop),

  .Jcc(Jcc),
  .func(func),
  .stwr(stwr),
  .spc_a(spc_a),
  .spc_b(spc_b)
);

assign wrmem = stack_owns_bus ? stk_we : cpu_wrmem;

assign stack_owns_bus = stk_push | stk_pop | stk_busy;

// MUX pe magistrala de memorie
assign ADDR_BUS = stack_owns_bus ? stk_addr  : ADDR_BUS_cpu;
assign DO       = stack_owns_bus ? stk_wdata : DO_cpu;
assign wrmem    = stack_owns_bus ? stk_we    : cpu_wrmem;




endmodule

module latch_mem (input logic [15:0] DI,input logic rst,wrpc,output logic [15:0] DO);

always_latch begin

	if (wrpc) DO = DI;
	
	else if (rst) DO = 16'h0;
	
	else DO = DO;

end

endmodule

module ERM16_tb;

	 // Inputs
	reg clk;
	reg init;
	reg [15:0] DI;
	wire [15:0] ADDR_BUS, DO;
	wire wrmem,ioe,intreq;
	 // Instantiate the Unit Under Test (UUT)
	ERM16_microprocessor uut (
		.clk(clk),
		.init(init),
		.DI(DI),
		.ADDR_BUS(ADDR_BUS),
		.DO(DO),
		.wrmem(wrmem),
		.ioe(ioe),
		.intreq(intreq)
	);
  
  integer outfile0;
  reg [5:0] prev_op;
  reg [15:0] line;
  initial begin
      prev_op=0;
      clk=0;
      #10;
      init=1;
      #30;
      init=0;
      #30
     outfile0=$fopen("RISC_MC.txt","r");   //"r" means reading and "w" means writing
     //read line by line.
      while (! $feof(outfile0)) begin //read until an "end of file" is reached.
         $fscanf(outfile0,"%b\n",line); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
         DI=line;
         #50;
         if (prev_op==6'b000111) begin
            $display("OUTPUT:%d",DO[10:0]);
         end
         #250; //wait some time as needed.
         prev_op=DI[15:10];
      end 
      //once reading and writing is finished, close the file.
      $fclose(outfile0);
      $finish;
  end
		  
	always begin
		#5 clk = ~clk;
	end

endmodule
  

