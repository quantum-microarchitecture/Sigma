                                                           
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  The Branch Resolve module to resolve the branch instructions
//
// ====================================================================
`include "QPU_defines.v"


module QPU_exu_branchslv(

  //   The BJP condition final result need to be resolved at ALU
  input  cmt_i_valid,  
  output cmt_i_ready,
  input  cmt_i_bjp,  
  input  cmt_i_bjp_prdt,// The predicted ture/false  
  input  cmt_i_bjp_rslv,// The resolved ture/false
  input  [`QPU_PC_SIZE-1:0] cmt_i_pc,  
  input  [`QPU_XLEN-1:0] cmt_i_imm,// The resolved ture/false

  input  brchmis_flush_ack,
  output brchmis_flush_req,

  output [`QPU_PC_SIZE-1:0] brchmis_flush_add_op1,  
  output [`QPU_PC_SIZE-1:0] brchmis_flush_add_op2
  );

  
  wire brchmis_need_flush = cmt_i_bjp & (cmt_i_bjp_prdt ^ cmt_i_bjp_rslv);
 
  assign brchmis_flush_req = cmt_i_valid & brchmis_need_flush;

  // * If it is a DRET instruction, the new target PC is DPC register
  // * If it is a RET instruction, the new target PC is EPC register
  // * If predicted as taken, but actually it is not taken, then 
  //     The new target PC should caculated by PC+2/4
  // * If predicted as not taken, but actually it is taken, then 
  //     The new target PC should caculated by PC+offset
  assign brchmis_flush_add_op1 = cmt_i_pc; 
  assign brchmis_flush_add_op2 = cmt_i_bjp_prdt ?  (`QPU_PC_SIZE'd4) : cmt_i_imm[`QPU_PC_SIZE-1:0];
  
  assign cmt_i_ready = (~cmt_i_bjp) | 
                             (
                                 (brchmis_need_flush ? brchmis_flush_ack : 1'b1) 
                             );

endmodule                                      
                                               
                                               
                                               
