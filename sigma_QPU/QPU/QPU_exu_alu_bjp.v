                                                          
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  This module to implement the Conditional Branch Instructions,
//  which is mostly share the datapath with ALU adder to resolve the comparasion
//  result to save gatecount to mininum
//
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_alu_bjp(

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Handshake Interface
  //
  input  bjp_i_valid, // Handshake valid
  output bjp_i_ready, // Handshake ready

  input  [`QPU_XLEN-1:0] bjp_i_rs1,
  input  [`QPU_XLEN-1:0] bjp_i_rs2,
  input  [`QPU_DECINFO_BJP_WIDTH-1:0] bjp_i_info,
  
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The BJP Commit Interface
  output bjp_o_valid, // Handshake valid
  input  bjp_o_ready, // Handshake ready
    //   The Write-Back Result for JAL and JALR

    //   The Commit Result for BJP
  output bjp_o_cmt_prdt,// The predicted ture/false  
  output bjp_o_cmt_rslv,// The resolved ture/false

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // To share the ALU datapath
  // 
     // The operands and info to ALU

  output [`QPU_XLEN-1:0] bjp_req_alu_op1,
  output [`QPU_XLEN-1:0] bjp_req_alu_op2,
  output bjp_req_alu_cmp_eq ,
  output bjp_req_alu_cmp_ne ,
  output bjp_req_alu_cmp_lt ,
  output bjp_req_alu_cmp_gt ,

 
  input  bjp_req_alu_cmp_res,


  input  clk,
  input  rst_n
  );


  wire bjp_i_bprdt = bjp_i_info [`QPU_DECINFO_BJP_BPRDT ];

  assign bjp_req_alu_op1 = bjp_i_rs1;
  assign bjp_req_alu_op2 = bjp_i_rs2;

  assign bjp_o_cmt_bjp = 1'b1;

  assign bjp_req_alu_cmp_eq  = bjp_i_info [`QPU_DECINFO_BJP_BEQ  ]; 
  assign bjp_req_alu_cmp_ne  = bjp_i_info [`QPU_DECINFO_BJP_BNE  ]; 
  assign bjp_req_alu_cmp_lt  = bjp_i_info [`QPU_DECINFO_BJP_BLT  ]; 
  assign bjp_req_alu_cmp_gt  = bjp_i_info [`QPU_DECINFO_BJP_BGT  ]; 

  assign bjp_o_valid     = bjp_i_valid;
  assign bjp_i_ready     = bjp_o_ready;
  assign bjp_o_cmt_prdt  = bjp_i_bprdt;
  assign bjp_o_cmt_rslv  = bjp_req_alu_cmp_res;



endmodule
