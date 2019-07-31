


  `define func_000 3'b000
  `define func_001 3'b001
  `define func_010 3'b010
  `define func_011 3'b011

  `define imm_13_9 5'b00101
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

  `define GATEZ 9'b111100001
  `define GATEXY 9'b100011110

  `define NGATE1 9'b000101010  //无反馈XY单门
  `define NGATE2 9'b010010101  //测量�?1则执行的XY单门
  `define NGATE3 9'b011001010  //测量�?0则执行的XY单门
  `define NGATE4 9'b011101010  //测量相同则执行的XY单门

  
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
  `define instr_measure{3'b011,5'b0,9'b0,`rs1,9'b011111111,`flag_1}

  `define instr_QI_1 {3'b011,`rs2,`NGATE1,`rs1,`NGATE2,`flag_1}
  `define instr_QI_2 {3'b011,`rs2,`NGATE3,`rs1,`NGATE4,`flag_1}
  `define instr_QI_3 {3'b011,`rs2,`GATEZ,`rs1,`GATEXY,`flag_1}

  `define instr_WFI {27'b0,`opcode_00,`opcode_10,`flag_0}


  `define GATE_0 9'b000000000
  `define GATE_H 9'b000000001
  `define GATE_X90 9'b000000010
  `define GATE_Y90 9'b000000011
  `define ZGATE_0 14'b11000_000000001
  `define ZGATE_1 14'b11000_000000010
  `define ZGATE_2 14'b11000_000000100
  `define XYGATE_1 14'b10000_000000001

  `define SMIS_S14_010100 {8'b0,9'b000010100,5'b0,5'b01110,`opcode_00,`opcode_11,`flag_0}                      //1
  `define SMIS_S15_101000 {8'b0,9'b000101000,5'b0,5'b01111,`opcode_00,`opcode_11,`flag_0}                      //2
  `define SMIS_S16_100100 {8'b0,9'b000100100,5'b0,5'b10000,`opcode_00,`opcode_11,`flag_0}                      //3
  `define SMIS_S17_001100 {8'b0,9'b000001100,5'b0,5'b10001,`opcode_00,`opcode_11,`flag_0}                      //4

  `define T0_H_S14_X90_S15 {3'b000,5'b01110,`GATE_H,5'b01111,`GATE_X90,`flag_1}                                //5
  `define T1_Y90_S2_X90_S3 {3'b001,5'b00010,`GATE_Y90,5'b00011,`GATE_X90,`flag_1}                              //6
  `define T2_Y90_S16_GATE0_S0 {3'b010,5'b10000,`GATE_Y90,5'b00000,`GATE_0,`flag_1}                             //7  
  `define T3_ZGATE0_XYGATE1 {3'b010,`ZGATE_0,`XYGATE_1,`flag_1}                                                //8
  `define T4_ZGATE1_X90_S3  {3'b010,`ZGATE_1,5'b00011,`GATE_X90,`flag_1}                                       //9
  `define T5_ZGATE2_GATE0_S0 {3'b010,`ZGATE_2,5'b00000,`GATE_0,`flag_1}                                        //10
  
  `define T1_MEASURE_S17 {3'b001,5'b0,9'b0,5'b10001,9'b011111111,`flag_1}                                     //11
  `define QWAIT_30 {3'b0,5'b0,9'b000011110,5'b0,5'b0,`opcode_10,`opcode_01,`flag_0}                           //12
  `define ADDI_R1_R0_001100 {`func_000,5'b0,9'b000001100,5'b00000,5'b00001,`opcode_00,`opcode_01,`flag_0}     //13
  `define FMR_R2_S17 {`func_000,5'b0,9'b0,5'b10001,5'b00010,`opcode_11,`opcode_01,`flag_0}                    //14
  `define BEQ_R1_R2_CASE2 {`func_000,5'b00010,9'b000000010,5'b00001,5'b00000,`opcode_11,`opcode_00,`flag_0}   //15
  //CASE1:
  `define T0_X90_S2 {3'b000,5'b00010,`GATE_X90,5'b00000,`GATE_0,`flag_1}                                      //16
  `define QWAIT_1 {3'b001,5'b0,9'b000000001,5'b0,5'b0,`opcode_10,`opcode_01,`flag_0}                          //17
  `define BEQ_R0_R0_NEXT {`func_000,5'b00000,9'b000000100,5'b00000,5'b00000,`opcode_11,`opcode_00,`flag_0}    //18
  //CASE2:
  `define T0_H_S2 {3'b000,5'b00010,`GATE_H,5'b00000,`GATE_0,`flag_1}                                          //19
  //QWAIT 1;
  //NEXT:
  `define T0_MEASURE_S2 {3'b000,5'b0,9'b0,5'b00010,9'b111111111,`flag_1}                                      //20
  //QWAIT 30;