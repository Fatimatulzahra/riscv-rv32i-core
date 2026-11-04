// branch_comp_tb.sv - Self-checking testbench for the branch comparator
`timescale 1ns/1ps

module branch_comp_tb;

  logic [31:0] a, b;
  logic [2:0]  funct3;
  logic        taken;

  int tests  = 0;
  int errors = 0;

  branch_comp dut (.a(a), .b(b), .funct3(funct3), .taken(taken));

  task check(input logic [2:0]  f3,
             input logic [31:0] in_a,
             input logic [31:0] in_b,
             input logic        expected,
             input string       name);
    begin
      funct3 = f3; a = in_a; b = in_b;
      #1;
      tests++;
      if (taken !== expected) begin
        errors++;
        $display("FAIL  %-22s a=%h b=%h  got=%b expected=%b", name, in_a, in_b, taken, expected);
      end else begin
        $display("pass  %s", name);
      end
    end
  endtask

  initial begin
    $dumpfile("build/branch_comp_tb.vcd");
    $dumpvars(0, branch_comp_tb);

    //     f3      a             b             exp   name
    check(3'b000, 32'd5,        32'd5,        1'b1, "BEQ equal");
    check(3'b000, 32'd5,        32'd6,        1'b0, "BEQ not equal");
    check(3'b001, 32'd5,        32'd6,        1'b1, "BNE not equal");
    check(3'b001, 32'd5,        32'd5,        1'b0, "BNE equal");
    check(3'b100, 32'hFFFFFFFF, 32'd1,        1'b1, "BLT -1 < 1");
    check(3'b100, 32'd1,        32'hFFFFFFFF, 1'b0, "BLT 1 < -1");
    check(3'b101, 32'd5,        32'd5,        1'b1, "BGE equal counts");
    check(3'b101, 32'h80000000, 32'h7FFFFFFF, 1'b0, "BGE min >= max");
    check(3'b110, 32'hFFFFFFFF, 32'd1,        1'b0, "BLTU big < 1");
    check(3'b110, 32'd1,        32'hFFFFFFFF, 1'b1, "BLTU 1 < big");
    check(3'b111, 32'hFFFFFFFF, 32'd1,        1'b1, "BGEU big >= 1");
    check(3'b111, 32'd0,        32'd0,        1'b1, "BGEU equal counts");
    check(3'b010, 32'd5,        32'd5,        1'b0, "invalid funct3");

    $display("--------------------------------");
    $display("%0d / %0d tests passed", tests - errors, tests);
    $finish;
  end

endmodule