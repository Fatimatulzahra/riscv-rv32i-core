// control.sv - Main decoder + ALU decoder for a single-cycle RV32I CPU
module control (
  input  logic [6:0] opcode,     // instr[6:0]
  input  logic [2:0] funct3,     // instr[14:12]
  input  logic       funct7b5,   // instr[30]: picks SUB vs ADD, SRA vs SRL

  output logic       reg_write,  // 1 = write a result into rd
  output logic [2:0] imm_sel,    // immediate format, sent to imm_gen
  output logic [1:0] alu_a_sel,  // ALU operand A: 00 = rs1, 01 = PC, 10 = zero
  output logic       alu_b_sel,  // ALU operand B: 0 = rs2, 1 = immediate
  output logic       mem_write,  // 1 = store to data memory
  output logic [1:0] result_sel, // written to rd: 00 = ALU, 01 = memory, 10 = PC+4
  output logic       branch,     // 1 = conditional branch (beq, bne, ...)
  output logic       jump,       // 1 = jal or jalr (always jumps)
  output logic       jalr,       // 1 = jump target is rs1+imm instead of PC+imm
  output logic [3:0] alu_ctrl    // operation code for the ALU
);

  // Opcodes
  localparam [6:0] OP_R      = 7'b0110011;
  localparam [6:0] OP_IMM    = 7'b0010011;
  localparam [6:0] OP_LOAD   = 7'b0000011;
  localparam [6:0] OP_STORE  = 7'b0100011;
  localparam [6:0] OP_BRANCH = 7'b1100011;
  localparam [6:0] OP_JAL    = 7'b1101111;
  localparam [6:0] OP_JALR   = 7'b1100111;
  localparam [6:0] OP_LUI    = 7'b0110111;
  localparam [6:0] OP_AUIPC  = 7'b0010111;

  logic [1:0] alu_op;  // internal: 00 = add, 10 = R-type, 11 = I-type ALU

  // ---------------- Main decoder ----------------
  always_comb begin
    reg_write  = 1'b0;
    imm_sel    = 3'b000;
    alu_a_sel  = 2'b00;
    alu_b_sel  = 1'b0;
    mem_write  = 1'b0;
    result_sel = 2'b00;
    branch     = 1'b0;
    jump       = 1'b0;
    jalr       = 1'b0;
    alu_op     = 2'b00;

    case (opcode)
      OP_R: begin                  // add x1, x2, x3
        reg_write = 1'b1;
        alu_op    = 2'b10;
      end
      OP_IMM: begin                // addi x1, x2, 5
        reg_write = 1'b1;
        alu_b_sel = 1'b1;          // operand B = immediate
        alu_op    = 2'b11;
      end
      OP_LOAD: begin               // lw x1, 8(x2)
        reg_write  = 1'b1;
        alu_b_sel  = 1'b1;         // address = rs1 + imm
        result_sel = 2'b01;        // write the loaded data
      end
      OP_STORE: begin              // sw x2, 8(x1)
        imm_sel   = 3'b001;        // S-type
        alu_b_sel = 1'b1;          // address = rs1 + imm
        mem_write = 1'b1;
      end
      OP_BRANCH: begin             // beq x1, x2, label
        imm_sel = 3'b010;          // B-type
        branch  = 1'b1;
      end
      OP_JAL: begin                // jal x1, label
        reg_write  = 1'b1;
        imm_sel    = 3'b100;       // J-type
        result_sel = 2'b10;        // rd = PC + 4 (return address)
        jump       = 1'b1;
      end
      OP_JALR: begin               // jalr x1, 0(x2)
        reg_write  = 1'b1;
        alu_b_sel  = 1'b1;         // target = rs1 + imm
        result_sel = 2'b10;        // rd = PC + 4
        jump       = 1'b1;
        jalr       = 1'b1;
      end
      OP_LUI: begin                // lui x1, 0x12345
        reg_write = 1'b1;
        imm_sel   = 3'b011;        // U-type
        alu_a_sel = 2'b10;         // A = 0, so result = imm
        alu_b_sel = 1'b1;
      end
      OP_AUIPC: begin              // auipc x1, 0x12345
        reg_write = 1'b1;
        imm_sel   = 3'b011;        // U-type
        alu_a_sel = 2'b01;         // A = PC, so result = PC + imm
        alu_b_sel = 1'b1;
      end
      default: ;                   // unknown opcode: keep the safe defaults
    endcase
  end

  // ---------------- ALU decoder ----------------
  always_comb begin
    case (alu_op)
      2'b10, 2'b11: begin          // R-type and I-type: funct3 picks the operation
        case (funct3)
          3'b000: alu_ctrl = (alu_op == 2'b10 && funct7b5) ? 4'b0001 : 4'b0000; // SUB : ADD
          3'b001: alu_ctrl = 4'b0101;                                           // SLL
          3'b010: alu_ctrl = 4'b1000;                                           // SLT
          3'b011: alu_ctrl = 4'b1001;                                           // SLTU
          3'b100: alu_ctrl = 4'b0100;                                           // XOR
          3'b101: alu_ctrl = funct7b5 ? 4'b0111 : 4'b0110;                      // SRA : SRL
          3'b110: alu_ctrl = 4'b0011;                                           // OR
          3'b111: alu_ctrl = 4'b0010;                                           // AND
          default: alu_ctrl = 4'b0000;
        endcase
      end
      default: alu_ctrl = 4'b0000; // loads, stores, jalr, lui, auipc all use ADD
    endcase
  end

endmodule