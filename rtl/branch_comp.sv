// branch_comp.sv - Decides whether a conditional branch is taken (RV32I)
module branch_comp (
  input  logic [31:0] a,       // rs1 value
  input  logic [31:0] b,       // rs2 value
  input  logic [2:0]  funct3,  // which branch: beq, bne, blt, ...
  output logic        taken    // 1 = condition is true
);

  logic eq, lt, ltu;

  assign eq  = (a == b);                    // equal
  assign lt  = ($signed(a) < $signed(b));   // less than, signed
  assign ltu = (a < b);                     // less than, unsigned

  always_comb begin
    case (funct3)
      3'b000:  taken = eq;     // BEQ
      3'b001:  taken = !eq;    // BNE
      3'b100:  taken = lt;     // BLT
      3'b101:  taken = !lt;    // BGE
      3'b110:  taken = ltu;    // BLTU
      3'b111:  taken = !ltu;   // BGEU
      default: taken = 1'b0;   // 010, 011 aren't valid branches
    endcase
  end

endmodule