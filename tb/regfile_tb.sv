// regfile_tb.sv - Self-checking testbench for the RV32I register file
`timescale 1ns/1ps

module regfile_tb;

  logic        clk = 0;
  logic        we;
  logic [4:0]  rs1, rs2, rd;
  logic [31:0] wdata, rdata1, rdata2;

  int tests  = 0;
  int errors = 0;

  regfile dut (
    .clk(clk), .we(we),
    .rs1(rs1), .rs2(rs2), .rd(rd),
    .wdata(wdata),
    .rdata1(rdata1), .rdata2(rdata2)
  );

  // Clock: flips every 5 ns -> 10 ns period
  always #5 clk = ~clk;

  // Set up a write on the falling edge; it happens on the next rising edge
  task write_reg(input logic [4:0] r, input logic [31:0] d, input logic en);
    begin
      @(negedge clk);
      we = en; rd = r; wdata = d;
      @(negedge clk);
      we = 0;
    end
  endtask

  // Read both ports and compare against expected values
  task check(input logic [4:0]  r1, r2,
             input logic [31:0] exp1, exp2,
             input string       name);
    begin
      rs1 = r1; rs2 = r2;
      #1;
      tests++;
      if (rdata1 !== exp1 || rdata2 !== exp2) begin
        errors++;
        $display("FAIL  %-18s rs1=x%0d got=%h exp=%h | rs2=x%0d got=%h exp=%h",
                 name, r1, rdata1, exp1, r2, rdata2, exp2);
      end else begin
        $display("pass  %s", name);
      end
    end
  endtask

  initial begin
    $dumpfile("build/regfile_tb.vcd");
    $dumpvars(0, regfile_tb);

    we = 0; rd = 0; wdata = 0; rs1 = 0; rs2 = 0;

    // Basic write, then read
    write_reg(5'd5, 32'hDEADBEEF, 1);
    check(5'd5, 5'd0, 32'hDEADBEEF, 32'd0, "write/read x5");

    // Both read ports at once
    write_reg(5'd31, 32'h12345678, 1);
    check(5'd5, 5'd31, 32'hDEADBEEF, 32'h12345678, "dual-port read");

    // x0 must stay zero even when written
    write_reg(5'd0, 32'hFFFFFFFF, 1);
    check(5'd0, 5'd0, 32'd0, 32'd0, "x0 ignores writes");

    // Write enable off -> nothing changes
    write_reg(5'd5, 32'h00000000, 0);
    check(5'd5, 5'd5, 32'hDEADBEEF, 32'hDEADBEEF, "we=0 blocks write");

    // Overwrite an existing value
    write_reg(5'd5, 32'h00000001, 1);
    check(5'd5, 5'd31, 32'h00000001, 32'h12345678, "overwrite x5");

    // Every register x1-x31 gets its own value, then read them all back
    for (int i = 1; i < 32; i++) write_reg(i, 32'hA0000000 + i, 1);
    for (int i = 1; i < 32; i++) check(i, 5'd0, 32'hA0000000 + i, 32'd0, "all registers");

    $display("--------------------------------");
    $display("%0d / %0d tests passed", tests - errors, tests);
    $finish;
  end

endmodule