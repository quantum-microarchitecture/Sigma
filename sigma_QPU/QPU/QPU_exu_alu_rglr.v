                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  This module to implement the regular ALU instructions
//
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_alu_rglr(

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Handshake Interface 
  //
  input  alu_i_valid, // Handshake valid
  output alu_i_ready, // Handshake ready

  input  [`QPU_XLEN-1:0] alu_i_rs1,
  input  [`QPU_XLEN-1:0] alu_i_rs2,
  input  [`QPU_XLEN-1:0] alu_i_imm,

  input  [`QPU_TIME_WIDTH - 1 : 0] alu_i_clk,
  input  [`QPU_QUBIT_NUM - 1 : 0] alu_i_qmr, ///qubit measure result

  input  [`QPU_DECINFO_ALU_WIDTH-1:0] alu_i_info,
  
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ALU Write-back/Commit Interface
  output alu_o_valid, // Handshake valid
  input  alu_o_ready, // Handshake ready
  //   The Write-Back Interface for Special (unaligned ldst and AMO instructions) 
  output [`QPU_XLEN-1:0] alu_o_wbck_cdata,                  ///to time_reg or classical_reg!!


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // To share the ALU datapath
  // 
  // The operands and info to ALU
  output alu_req_alu_add ,
  output alu_req_alu_sub ,
  output alu_req_alu_xor ,
  output alu_req_alu_or  ,
  output alu_req_alu_and ,
 
  output [`QPU_XLEN-1:0] alu_req_alu_op1,
  output [`QPU_XLEN-1:0] alu_req_alu_op2,


  input  [`QPU_XLEN-1:0] alu_req_alu_res


  );

//对于QI操作，DECINFO_ALU都为0！！！，因此不能根据信息总线判断给wbck以及datapath单元发送什么样的数据！！，也不能根据信息总线决定将什么数据发送到rglr_alu中！
//传给datapath的操作数，以及传回的操作数都是32位，注意位数的转换！

  wire op2imm  = alu_i_info [`QPU_DECINFO_ALU_OP2IMM ];  //for QI & PI>0
  wire op1zero = alu_i_info [`QPU_DECINFO_ALU_SMIS];
  wire op1qmr  = alu_i_info [`QPU_DECINFO_ALU_FMR];
  wire op1clk  = alu_i_info [`QPU_DECINFO_ALU_QWAIT];

  assign alu_req_alu_op1  =   op1zero ? {`QPU_XLEN{1'b0}} 
                           :  op1clk  ?  {{(`QPU_XLEN - `QPU_TIME_WIDTH){1'b0}},alu_i_clk}
                           :  op1qmr  ?  {{(`QPU_XLEN - `QPU_QUBIT_NUM){1'b0}},alu_i_qmr}  
                           :  alu_i_rs1;

  assign alu_req_alu_op2  = op2imm ? alu_i_imm : alu_i_rs2;

  wire smis  = alu_i_info [`QPU_DECINFO_ALU_SMIS];
  wire fmr   = alu_i_info [`QPU_DECINFO_ALU_FMR];
  wire qwait = alu_i_info [`QPU_DECINFO_ALU_QWAIT];


     // The NOP is encoded as ADDI, so need to uncheck it
  assign alu_req_alu_add  = alu_i_info [`QPU_DECINFO_ALU_ADD ] | qwait | smis | fmr;
  assign alu_req_alu_sub  = alu_i_info [`QPU_DECINFO_ALU_SUB ]; 
  assign alu_req_alu_xor  = alu_i_info [`QPU_DECINFO_ALU_XOR ];
  assign alu_req_alu_or   = alu_i_info [`QPU_DECINFO_ALU_OR  ];
  assign alu_req_alu_and  = alu_i_info [`QPU_DECINFO_ALU_AND ];


  assign alu_o_valid = alu_i_valid;
  assign alu_i_ready = alu_o_ready;
  assign alu_o_wbck_cdata = alu_req_alu_res;

  

endmodule
