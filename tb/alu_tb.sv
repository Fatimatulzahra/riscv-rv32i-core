// alu_tb.sv - Self-checking testbench for the RV32I ALU
`timescale 1ns/1ps

module alu_tb;

  // Signals that connect to the ALU
  logic [31:0] a, b;
  logic [3:0]  alu_ctrl;
  logic [31:0] result;

  // Counters for the final report
  int tests  = 0;
  int errors = 0;

  // The "device under test" (DUT): one copy of your ALU
  alu dut (
    .a(a),
    .b(b),
    .alu_ctrl(alu_ctrl),
    .result(result)
  );

  // Applies one set of inputs and checks the output
  task check(input logic [3:0]  ctrl,
             input logic [31:0] in_a,
             input logic [31:0] in_b,
             input logic [31:0] expected,
             input string       name);
    begin
      a = in_a;
      b = in_b;
      alu_ctrl = ctrl;
      #1;                          // wait 1 ns for the logic to settle
      tests++;
      if (result !== expected) begin
        errors++;
        $display("FAIL  %-14s a=%h b=%h  got=%h expected=%h",
                 name, in_a, in_b, result, expected);
      end else begin
        $display("pass  %s", name);
      end
    end
  endtask

  initial begin
    // Save a waveform file you can open in GTKWave
    $dumpfile("build/alu_tb.vcd");
    $dumpvars(0, alu_tb);

    // ---------- Tests ----------
    //     ctrl     a             b             expected      name
    check(4'b0000, 32'd5,        32'd3,        32'd8,        "ADD basic");
    check(4'b0000, 32'hFFFFFFFF, 32'd1,        32'h00000000, "ADD overflow");
    check(4'b0001, 32'd3,        32'd5,        32'hFFFFFFFE, "SUB negative");
    check(4'b0111, 32'hFFFFFFF0, 32'd2,        32'hFFFFFFFC, "SRA negative");
    check(4'b1000, 32'hFFFFFFFF, 32'd1,        32'd1,        "SLT -1 < 1");
    check(4'b0010, 32'hF0F0F0F0, 32'h0F0F00FF, 32'h000000F0, "AND");
    check(4'b0011, 32'hF0F0F0F0, 32'h0F0F00FF, 32'hFFFFF0FF, "OR");
    check(4'b0100, 32'h12345678, 32'h12345678, 32'h00000000, "XOR self");
    check(4'b0101, 32'h00000001, 32'h0000001F, 32'h80000000, "SLL by 31");
    check(4'b0101, 32'h00000001, 32'h00000021, 32'h00000002, "SLL shamt wrap");
    check(4'b0110, 32'h80000000, 32'h0000001F, 32'h00000001, "SRL");
    check(4'b0111, 32'h7FFFFFFF, 32'h00000004, 32'h07FFFFFF, "SRA positive");
    check(4'b1000, 32'h00000005, 32'h00000003, 32'h00000000, "SLT false");
    check(4'b1001, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, "SLTU vs SLT");
    check(4'b1111, 32'hDEADBEEF, 32'h12345678, 32'h00000000, "Unused code");
    // ---------- Report ----------
    $display("--------------------------------");
    $display("%0d / %0d tests passed", tests - errors, tests);
    $finish;
  end

endmodule