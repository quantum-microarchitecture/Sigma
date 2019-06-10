

`include "../QPU/QPU_defines.v"

`timescale 10ns/10ps

module tb_exu_decode();

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


      //////////////////////////////////////////////////////////////
  // The IR stage to Decoder
  reg  [`QPU_INSTR_SIZE-1:0] i_instr;
  reg  [`QPU_PC_SIZE-1:0] i_pc;
  reg  i_prdt_taken; 
  
  //////////////////////////////////////////////////////////////
  // The Decoded Info-Bus

  wire dec_rs1x0;
  wire dec_rs2x0;
  wire dec_rs1en;
  wire dec_rs2en;
  wire dec_rdwen;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rs1idx;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rs2idx;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rdidx;
  wire [`QPU_DECINFO_WIDTH-1:0] dec_info;
  wire [`QPU_XLEN-1:0] dec_imm;
  wire [`QPU_PC_SIZE-1:0] dec_pc;  
  
  //Quantum instruction decode
  wire dec_new_timepoint;
  wire dec_need_qubitflag;
  wire dec_measure;
  wire dec_fmr;
  //Branch instruction decode
  wire dec_bxx;
  wire [`QPU_XLEN-1:0] dec_bjp_imm;

  
  initial
  begin
    #0 i_instr = `instr_LOAD;
    #0 i_pc = `QPU_PC_SIZE'b0;
    #0 i_prdt_taken = 1'b0;
    #2 i_instr = `instr_STORE;

    #5 i_instr = `instr_BEQ;
    #2 i_instr = `instr_BNE;
    #2 i_instr = `instr_BLT;
    #2 i_instr = `instr_BGT;

    #5 i_instr = `instr_ADDI;
    #2 i_instr = `instr_XORI;
    #2 i_instr = `instr_ORI;
    #2 i_instr = `instr_ANDI;

    #5 i_instr = `instr_ADD;
    #2 i_instr = `instr_XOR;
    #2 i_instr = `instr_OR;
    #2 i_instr = `instr_AND;

    #10 i_instr = `instr_QWAIT;
    #2 i_instr = `instr_FMR;
    #2 i_instr = `instr_SMIS;
    #2 i_instr = `instr_QI;
    #2 i_instr = `instr_measure;

    #5 i_instr = `instr_WFI;


  end




  QPU_exu_decode test_exu_decode(
      .i_instr (i_instr),
      .i_pc (i_pc),
      .i_prdt_taken (i_prdt_taken),

      .dec_rs1x0(dec_rs1x0),
      .dec_rs2x0(dec_rs2x0),
      .dec_rs1en(dec_rs1en),
      .dec_rs2en(dec_rs2en),
      .dec_rdwen(dec_rdwen),
      .dec_rs1idx(dec_rs1idx),
      .dec_rs2idx(dec_rs2idx),
      .dec_rdidx(dec_rdidx),
      .dec_info(dec_info),
      .dec_imm(dec_imm),
      .dec_pc(dec_pc),

      .dec_new_timepoint(dec_new_timepoint),
      .dec_need_qubitflag(dec_need_qubitflag),
      .dec_measure(dec_measure),
      .dec_fmr(dec_fmr),

      .dec_bxx(dec_bxx),
      .dec_bjp_imm(dec_bjp_imm)
  );


endmodule
























