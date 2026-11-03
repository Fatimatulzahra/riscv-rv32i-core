// imm_gen.sv - Extracts and sign-extends immediates for RV32I
module imm_gen (
  input  logic [31:0] instr,    // the full 32-bit instruction
  input  logic [2:0]  imm_sel,  // which format (from the control unit)
  output logic [31:0] imm       // sign-extended 32-bit immediate
);

  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

  assign imm_i = {{20{instr[31]}}, instr[31:20]};
  assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  assign imm_u = {instr[31:12], 12'b0};
  assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

  always_comb begin
    case (imm_sel)
      3'b000:  imm = imm_i;
      3'b001:  imm = imm_s;
      3'b010:  imm = imm_b;
      3'b011:  imm = imm_u;
      3'b100:  imm = imm_j;
      default: imm = 32'b0;
    endcase
  end

endmodule