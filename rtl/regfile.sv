// regfile.sv - 32 x 32-bit register file for RV32I
module regfile (
  input  logic        clk,
  input  logic        we,             // write enable (RegWrite from control)
  input  logic [4:0]  rs1, rs2,       // which registers to read
  input  logic [4:0]  rd,             // which register to write
  input  logic [31:0] wdata,          // data to write
  output logic [31:0] rdata1, rdata2  // data read out
);

  logic [31:0] regs [31:0];   // 32 registers, each 32 bits wide

// write data
  always_ff @(posedge clk) begin
    if (we && rd != 5'd0) begin
      regs[rd] <= wdata;
    end
  end
  
// read data
  assign rdata1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
  assign rdata2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

endmodule