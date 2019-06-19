


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


  `define GATE_0 9'b000000000
  `define GATE_H 9'b000000001
  `define GATE_X90 9'b000000010
  `define GATE_Y90 9'b000000011
  `define GATE_CNOTS 9'b000000100
  `define GATE_CNOTT 9'b000000101

  `define SMIS_S6_010100 {8'b0,9'b000010100,5'b0,5'b00110,`opcode_00,`opcode_11,`flag_0}
  `define SMIS_S7_101000 {8'b0,9'b000101000,5'b0,5'b00111,`opcode_00,`opcode_11,`flag_0}
  `define SMIS_S8_100100 {8'b0,9'b000100100,5'b0,5'b01000,`opcode_00,`opcode_11,`flag_0}
  `define SMIS_S9_001100 {8'b0,9'b000001100,5'b0,5'b01001,`opcode_00,`opcode_11,`flag_0}
  `define T0_H_S6_X90_S7 {3'b000,5'b00110,`GATE_H,5'b00111,`GATE_X90,`flag_1}
  `define T1_CNOTS_S2_CNOTT_S3 {3'b001,5'b00010,`GATE_CNOTS,5'b00011,`GATE_CNOTT,`flag_1}
  `define T2_Y90_S8 {3'b010,5'b01000,`GATE_Y90,5'b00000,`GATE_0,`flag_1}
  `define T1_MEASURE_S9 {3'b001,5'b0,9'b0,5'b01001,9'b111111111,`flag_1}
  `define QWAIT_30 {3'b0,5'b0,9'b000011110,5'b0,5'b0,`opcode_10,`opcode_01,`flag_0}
  `define ADDI_R1_R0_001100 {`func_000,5'b0,9'b000001100,5'b00000,5'b00001,`opcode_00,`opcode_01,`flag_0}
  `define FMR_R2_S9 {`func_000,5'b0,9'b0,5'b01001,5'b00010,`opcode_11,`opcode_01,`flag_0}
  `define BEQ_R1_R2_CASE2 {`func_000,5'b00010,9'b000000010,5'b00001,5'b00000,`opcode_11,`opcode_00,`flag_0}
  //CASE1:
  `define T0_X90_S2 {3'b000,5'b00010,`GATE_X90,5'b00000,`GATE_0,`flag_1}
  `define QWAIT_1 {3'b001,5'b0,9'b000000001,5'b0,5'b0,`opcode_10,`opcode_01,`flag_0}
  `define BEQ_R0_R0_NEXT {`func_000,5'b00000,9'b000000100,5'b00000,5'b00000,`opcode_11,`opcode_00,`flag_0}
  //CASE2:
  `define T0_H_S2 {3'b000,5'b00010,`GATE_H,5'b00000,`GATE_0,`flag_1}
  //QWAIT 1;
  //NEXT:
  `define T0_MEASURE_S2 {3'b000,5'b0,9'b0,5'b00010,9'b111111111,`flag_1}
  //QWAIT 30;