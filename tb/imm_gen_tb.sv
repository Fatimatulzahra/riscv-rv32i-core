// imm_gen_tb.sv - Self-checking testbench for the immediate generator
`timescale 1ns/1ps

module imm_gen_tb;

  logic [31:0] instr, imm;
  logic [2:0]  imm_sel;

  int tests  = 0;
  int errors = 0;

  imm_gen dut (.instr(instr), .imm_sel(imm_sel), .imm(imm));

  task check(input logic [2:0]  sel,
             input logic [31:0] in_instr,
             input logic [31:0] expected,
             input string       name);
    begin
      imm_sel = sel;
      instr   = in_instr;
      #1;
      tests++;
      if (imm !== expected) begin
        errors++;
        $display("FAIL  %-22s instr=%h  got=%h expected=%h",
                 name, in_instr, imm, expected);
      end else begin
        $display("pass  %s", name);
      end
    end
  endtask

  initial begin
    $dumpfile("build/imm_gen_tb.vcd");
    $dumpvars(0, imm_gen_tb);

    //     sel     instruction   expected      name
    check(3'b000, 32'h00500093, 32'h00000005, "I: addi x1,x0,5");
    check(3'b000, 32'hFFF00093, 32'hFFFFFFFF, "I: addi x1,x0,-1");
    check(3'b001, 32'h0020A423, 32'h00000008, "S: sw x2,8(x1)");
    check(3'b001, 32'hFE20AE23, 32'hFFFFFFFC, "S: sw x2,-4(x1)");
    check(3'b010, 32'h00208863, 32'h00000010, "B: beq x1,x2,+16");
    check(3'b010, 32'hFE208CE3, 32'hFFFFFFF8, "B: beq x1,x2,-8");
    check(3'b011, 32'h123450B7, 32'h12345000, "U: lui x1,0x12345");
    check(3'b011, 32'hFFFFF0B7, 32'hFFFFF000, "U: lui x1,0xFFFFF");
    check(3'b100, 32'h001000EF, 32'h00000800, "J: jal x1,+2048");
    check(3'b100, 32'hFFDFF0EF, 32'hFFFFFFFC, "J: jal x1,-4");
    check(3'b111, 32'hFFFFFFFF, 32'h00000000, "unused sel -> 0");

    $display("--------------------------------");
    $display("%0d / %0d tests passed", tests - errors, tests);
    $finish;
  end

endmodule