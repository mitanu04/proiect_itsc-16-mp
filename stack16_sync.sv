module stack16_sync #(
  parameter logic [15:0] SP_RESET = 16'hFFFE   // alege top-of-stack valid in RAM
) (
  input  logic        clk,
  input  logic        rst_n,

  // comenzi (puls 1 ciclu; ideal mutual exclusive)
  input  logic        push,
  input  logic        pop,

  input  logic [15:0] push_data,

  // interfata RAM 16-bit, 1 port, sync-read:
  // addr in ciclul N -> rdata valabil in ciclul N+1
  output logic        mem_we,
  output logic [15:0] mem_addr,
  output logic [15:0] mem_wdata,
  input  logic [15:0] mem_rdata,

  // stare / rezultate
  output logic [15:0] sp,
  output logic [15:0] pop_data,
  output logic        pop_valid,
  output logic        busy
);

  logic        pop_pending;
  logic [15:0] pop_addr_q;

  assign busy = pop_pending;  // cat timp astepti rdata pentru POP

  // combinational: controleaza memoria
  always_comb begin
    mem_we    = 1'b0;
    mem_wdata = push_data;
    mem_addr  = sp;

    // PUSH: scrie la (sp-1)
    if (push && !pop) begin
      mem_we   = 1'b1;
      mem_addr = sp - 16'd1;
    end

    // POP: initiaza citire de la sp (adresa curenta)
    else if (pop && !push) begin
      mem_we   = 1'b0;
      mem_addr = sp;
    end

    // optional: mentine adresa in ciclul urmator (nu e obligatoriu la multe RAM-uri)
    else if (pop_pending) begin
      mem_we   = 1'b0;
      mem_addr = pop_addr_q;
    end
  end

  // secvential: SP + validare POP
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sp          <= SP_RESET;
      pop_pending <= 1'b0;
      pop_addr_q  <= 16'h0000;
      pop_data    <= 16'h0000;
      pop_valid   <= 1'b0;
    end else begin
      pop_valid <= 1'b0;

      // finalizeaza POP (ciclul N+1)
      if (pop_pending) begin
        pop_data    <= mem_rdata;
        pop_valid   <= 1'b1;
        pop_pending <= 1'b0;
      end

      // comenzi (ciclul N)
      unique case ({push, pop})
        2'b10: begin
          // PUSH: sp-- (scrierea e deja pe mem_addr=sp-1)
          sp <= sp - 16'd1;
        end

        2'b01: begin
          // POP: pornesti citirea din sp (mem_addr=sp in ciclul N)
          // apoi eliberezi elementul: sp++
          pop_pending <= 1'b1;
          pop_addr_q  <= sp;
          sp          <= sp + 16'd1;
        end

        default: begin
          sp <= sp;
        end
      endcase
    end
  end

endmodule
