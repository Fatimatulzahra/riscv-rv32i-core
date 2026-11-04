// control_tb.sv - Self-checking testbench for the RV32I control unit
`timescale 1ns/1ps

module control_tb;

  logic [31:0] instr;
  logic        reg_write, alu_b_sel, mem_write, branch, jump, jalr;
  logic [2:0]  imm_sel;
  logic [1:0]  alu_a_sel, result_sel;
  logic [3:0]  alu_ctrl;

  int tests  = 0;
  int errors = 0;

  // Slice the instruction here
  control dut (
    .opcode(instr[6:0]), .funct3(instr[14:12]), .funct7b5(instr[30]),
    .reg_write(reg_write), .imm_sel(imm_sel),
    .alu_a_sel(alu_a_sel), .alu_b_sel(alu_b_sel),
    .mem_write(mem_write), .result_sel(result_sel),
    .branch(branch), .jump(jump), .jalr(jalr),
    .alu_ctrl(alu_ctrl)
  );

  logic [16:0] got;
  assign got = {reg_write, imm_sel, alu_a_sel, alu_b_sel, mem_write,
                result_sel, branch, jump, jalr, alu_ctrl};

  task check(input logic [31:0] in_instr,
             input logic [16:0] expected,
             input string       name);
    begin
      instr = in_instr;
      #1;
      tests++;
      if (got !== expected) begin
        errors++;
        $display("FAIL  %-20s instr=%h", name, in_instr);
        $display("      got      %b_%b_%b_%b_%b_%b_%b_%b_%b_%b",
                 got[16], got[15:13], got[12:11], got[10], got[9],
                 got[8:7], got[6], got[5], got[4], got[3:0]);
        $display("      expected %b_%b_%b_%b_%b_%b_%b_%b_%b_%b",
                 expected[16], expected[15:13], expected[12:11], expected[10], expected[9],
                 expected[8:7], expected[6], expected[5], expected[4], expected[3:0]);
      end else begin
        $display("pass  %s", name);
      end
    end
  endtask

  initial begin
    $dumpfile("build/control_tb.vcd");
    $dumpvars(0, control_tb);

    // Field order in each expected value:
    // reg_write _ imm_sel _ alu_a_sel _ alu_b_sel _ mem_write _ result_sel _ branch _ jump _ jalr _ alu_ctrl

    // R-type
    check(32'h002081B3, 17'b1_000_00_0_0_00_0_0_0_0000, "add  x3,x1,x2");
    check(32'h402081B3, 17'b1_000_00_0_0_00_0_0_0_0001, "sub  x3,x1,x2");
    check(32'h4020D1B3, 17'b1_000_00_0_0_00_0_0_0_0111, "sra  x3,x1,x2");

    // I-type ALU
    check(32'hFFF00093, 17'b1_000_00_1_0_00_0_0_0_0000, "addi x1,x0,-1");
    check(32'h40315093, 17'b1_000_00_1_0_00_0_0_0_0111, "srai x1,x2,3");
    check(32'hFFF14093, 17'b1_000_00_1_0_00_0_0_0_0100, "xori x1,x2,-1");

    // Memory
    check(32'h00812083, 17'b1_000_00_1_0_01_0_0_0_0000, "lw   x1,8(x2)");
    check(32'h0020A423, 17'b0_001_00_1_1_00_0_0_0_0000, "sw   x2,8(x1)");

    // Control flow
    check(32'h00208863, 17'b0_010_00_0_0_00_1_0_0_0000, "beq  x1,x2,+16");
    check(32'h001000EF, 17'b1_100_00_0_0_10_0_1_0_0000, "jal  x1,+2048");
    check(32'h000100E7, 17'b1_000_00_1_0_10_0_1_1_0000, "jalr x1,0(x2)");

    // Upper immediates
    check(32'h123450B7, 17'b1_011_10_1_0_00_0_0_0_0000, "lui  x1,0x12345");
    check(32'h12345097, 17'b1_011_01_1_0_00_0_0_0_0000, "auipc x1,0x12345");

    // Unsupported instruction must do nothing
    check(32'h00000073, 17'b0_000_00_0_0_00_0_0_0_0000, "ecall (unsupported)");

    $display("--------------------------------");
    $display("%0d / %0d tests passed", tests - errors, tests);
    $finish;
  end

endmodule