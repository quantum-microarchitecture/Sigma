//=====================================================================
// Designer   : HL
//
// Description:
//  The Lite-BPU module to handle very simple branch predication at IFU
//
// ====================================================================
`include "QPU_defines.v"

module qpu_ifu_litebpu(

  // Current PC
  input  [`QPU_PC_SIZE-1:0] pc,

  input  dec_bxx,
  input  [`QPU_XLEN-1:0] dec_bjp_imm,

  output prdt_taken,  
  output [`QPU_PC_SIZE-1:0] prdt_pc_add_op1,  
  output [`QPU_PC_SIZE-1:0] prdt_pc_add_op2
  );

  assign prdt_taken   = dec_bxx & dec_bjp_imm[`QPU_XLEN-1];  

  assign prdt_pc_add_op1 = pc[`QPU_PC_SIZE-1:0];

  assign prdt_pc_add_op2 = dec_bjp_imm[`QPU_PC_SIZE-1:0];  

endmodule




























