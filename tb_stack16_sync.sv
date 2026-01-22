module tb_stack16_sync;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n;

  logic push, pop;
  logic [15:0] push_data;

  logic mem_we;
  logic [15:0] mem_addr, mem_wdata;
  logic [15:0] mem_rdata;

  logic [15:0] sp;
  logic [15:0] pop_data;
  logic pop_valid;
  logic busy;

  // RAM simplu sync-read (1 ciclu)
  logic [15:0] mem [0:65535];

  always_ff @(posedge clk) begin
    if (mem_we) mem[mem_addr] <= mem_wdata;
    mem_rdata <= mem[mem_addr];
  end

  // DUT
  stack16_sync #(.SP_RESET(16'h0010)) dut (
    .clk, .rst_n,
    .push, .pop,
    .push_data,
    .mem_we, .mem_addr, .mem_wdata, .mem_rdata,
    .sp,
    .pop_data, .pop_valid,
    .busy
  );

  task automatic do_push(input logic [15:0] v);
    begin
      @(negedge clk);
      push_data = v;
      push = 1; pop = 0;
      @(negedge clk);
      push = 0;
    end
  endtask

  task automatic do_pop_expect(input logic [15:0] expected);
    begin
      @(negedge clk);
      pop = 1; push = 0;
      @(negedge clk);
      pop = 0;

      // așteaptă pop_valid (ar trebui să vină în 1 ciclu)
      wait (pop_valid === 1'b1);
      if (pop_data !== expected) begin
        $display("FAIL: expected %h, got %h at time %0t", expected, pop_data, $time);
        $fatal;
      end else begin
        $display("OK: pop_data=%h at time %0t", pop_data, $time);
      end

      // pop_valid e pulse (1 ciclu)
      @(posedge clk);
    end
  endtask

  initial begin
    // init
    rst_n = 0;
    push = 0; pop = 0;
    push_data = 16'h0000;

    // init mem
    for (int i=0; i<256; i++) mem[i] = 16'h0000;

    repeat (2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // verifică SP reset
    if (sp !== 16'h0010) begin
      $display("FAIL: SP after reset expected 0010 got %h", sp);
      $fatal;
    end

    // PUSH A, PUSH B
    do_push(16'hAAAA);
    if (sp !== 16'h000F) begin
      $display("FAIL: SP after push AAAA expected 000F got %h", sp);
      $fatal;
    end
    do_push(16'hBBBB);
    if (sp !== 16'h000E) begin
      $display("FAIL: SP after push BBBB expected 000E got %h", sp);
      $fatal;
    end

    // POP => BBBB, POP => AAAA
    do_pop_expect(16'hBBBB);
    if (sp !== 16'h000F) begin
      $display("FAIL: SP after pop BBBB expected 000F got %h", sp);
      $fatal;
    end

    do_pop_expect(16'hAAAA);
    if (sp !== 16'h0010) begin
      $display("FAIL: SP after pop AAAA expected 0010 got %h", sp);
      $fatal;
    end

    $display("ALL TESTS PASSED.");
    $finish;
  end

endmodule