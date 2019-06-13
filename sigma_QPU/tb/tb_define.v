


  `define func_000 3'b000
  `define func_001 3'b001
  `define func_010 3'b010
  `define func_011 3'b011

  `define imm_13_9 5'b10101
  `define imm_8_0 9'b101010101

  `define rs2 5'b01010
  `define rs1 5'b01001
  `define rd 5'b10010

  `define opcode_00 2'b00
  `define opcode_01 2'b01
  `define opcode_10 2'b10
  `define opcode_11 2'b11

  `define flag_0 1'b0
  `define flag_1 1'b1

  `define GATE1 9'b111100001
  `define GATE2 9'b000011110
  
  `define instr_LOAD {`func_010,`imm_13_9,`imm_8_0,`rs1,`rd,`opcode_00,`opcode_00,`flag_0}
  `define instr_STORE {`func_010,`rs2,`imm_8_0,`rs1,`imm_13_9,`opcode_01,`opcode_00,`flag_0}

  `define instr_BEQ {`func_000,`rs2,`imm_8_0,`rs1,`imm_13_9,`opcode_11,`opcode_00,`flag_0}
  `define instr_BNE {`func_001,`rs2,`imm_8_0,`rs1,`imm_13_9,`opcode_11,`opcode_00,`flag_0}
  `define instr_BLT {`func_010,`rs2,`imm_8_0,`rs1,`imm_13_9,`opcode_11,`opcode_00,`flag_0}
  `define instr_BGT {`func_011,`rs2,`imm_8_0,`rs1,`imm_13_9,`opcode_11,`opcode_00,`flag_0}

  `define instr_ADDI {`func_000,`imm_13_9,`imm_8_0,`rs1,`rd,`opcode_00,`opcode_01,`flag_0}
  `define instr_XORI {`func_001,`imm_13_9,`imm_8_0,`rs1,`rd,`opcode_00,`opcode_01,`flag_0}
  `define instr_ORI {`func_010,`imm_13_9,`imm_8_0,`rs1,`rd,`opcode_00,`opcode_01,`flag_0}
  `define instr_ANDI {`func_011,`imm_13_9,`imm_8_0,`rs1,`rd,`opcode_00,`opcode_01,`flag_0}

  `define instr_ADD {`func_000,`rs2,9'b0,`rs1,`rd,`opcode_01,`opcode_01,`flag_0}
  `define instr_XOR {`func_001,`rs2,9'b0,`rs1,`rd,`opcode_01,`opcode_01,`flag_0}
  `define instr_OR {`func_010,`rs2,9'b0,`rs1,`rd,`opcode_01,`opcode_01,`flag_0}
  `define instr_AND {`func_011,`rs2,9'b0,`rs1,`rd,`opcode_01,`opcode_01,`flag_0}


  `define instr_QWAIT {`func_010,`rs2,`imm_8_0,`imm_13_9,`rd,`opcode_10,`opcode_01,`flag_0}
  `define instr_FMR {`func_000,5'b0,9'b0,`rs1,`rd,`opcode_11,`opcode_01,`flag_0}
  `define instr_SMIS {`func_010,`rs2,`imm_8_0,`imm_13_9,`rd,`opcode_00,`opcode_11,`flag_0}
  `define instr_QI {3'b111,`rs2,`GATE2,`rs1,`GATE1,`flag_1}
  `define instr_measure{3'b011,5'b0,9'b0,`rs1,9'b111111111,`flag_1}

  `define instr_WFI {27'b0,`opcode_00,`opcode_10,`flag_0}