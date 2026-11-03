// alu.sv - Arithmetic Logic Unit for an RV32I single-cycle CPU
module alu (
  input  logic [31:0] a,        // operand A (usually the value from rs1)
  input  logic [31:0] b,        // operand B (rs2 or an immediate)
  input  logic [3:0]  alu_ctrl, // selects which operation to perform
  output logic [31:0] result    // output of the operation
);
  logic [4:0] shamt;           // shift amount: only the bottom 5 bits of b
  assign shamt = b[4:0];
  always_comb begin
    case (alu_ctrl)
      4'b0000: result = a + b;  // ADD
      4'b0001: result = a - b; // SUB
      4'b0010: result = a & b; // AND
      4'b0011: result = a | b; // OR
      4'b0100: result = a ^ b; // XOR
      4'b0101: result = a << shamt; // SLL  (shift left logical)
      4'b0110: result = a >> shamt; // SRL  (shift right logical)
      4'b0111: result = $signed(a) >>> shamt; // SRA  (shift right arithmetic)
      4'b1000: result = $signed(a) < $signed(b); // SLT  (set less than, signed)
      4'b1001: result = a < b; // SLTU (set less than, unsigned)
      default: result = 32'b0;
    endcase
  end

endmodule