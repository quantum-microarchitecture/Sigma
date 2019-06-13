

`include "../QPU/QPU_defines.v"
`include "tb_define.v"

`timescale 10ns/10ps

module tb_exu_decode();

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
























