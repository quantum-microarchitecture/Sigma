//=====================================================================
// Designer   : HL
//
// Description:
//  The mini-decode module to decode the instruction in IFU 
//
// ====================================================================
`include "QPU_defines.v"

module qpu_ifu_minidec(

  //////////////////////////////////////////////////////////////
  // The IR stage to Decoder
  input  [`QPU_INSTR_SIZE-1:0] instr,
  
  //////////////////////////////////////////////////////////////
  // The Decoded Info-Bus

  output dec_rs1en,
  output dec_rs2en,
  output [`QPU_RFIDX_WIDTH-1:0] dec_rs1idx,
  output [`QPU_RFIDX_WIDTH-1:0] dec_rs2idx,


  output dec_bxx,
  output [`QPU_XLEN-1:0] dec_bjp_imm 

  );

  qpu_exu_decode u_qpu_exu_decode(

  .i_instr(instr),
  .i_pc(`QPU_PC_SIZE'b0),
  .i_prdt_taken(1'b0), 

  .dec_rs1x0(),
  .dec_rs2x0(),
  .dec_rs1en(dec_rs1en),
  .dec_rs2en(dec_rs2en),
  .dec_rdwen(),
  .dec_rs1idx(dec_rs1idx),
  .dec_rs2idx(dec_rs2idx),
  .dec_rdidx(),
  .dec_info(),  
  .dec_imm(),
  .dec_pc(),

  .dec_new_timepoint(),
  .dec_need_qubitflag(),
  .dec_measure(),

  .dec_bxx (dec_bxx ),
  .dec_bjp_imm    (dec_bjp_imm    )  

  );


endmodule