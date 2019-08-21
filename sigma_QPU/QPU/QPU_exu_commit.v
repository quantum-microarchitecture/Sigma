                                                                   
                                                                                                                                               
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  The Commit module to commit instructions or flush pipeline
//
// ====================================================================


`include "QPU_defines.v"

module QPU_exu_commit(

  input                        alu_cmt_i_valid,
  output                       alu_cmt_i_ready,
  input  [`QPU_PC_SIZE-1:0]    alu_cmt_i_pc,   
  input  [`QPU_XLEN-1:0]       alu_cmt_i_imm,

    //   The Branch Commit
  input                        alu_cmt_i_bjp,
  input                        alu_cmt_i_bjp_prdt,// The predicted ture/false  
  input                        alu_cmt_i_bjp_rslv,// The resolved ture/false


  //////////////////////////////////////////////////////////////
  // The Flush interface to IFU
  //
  //   To save the gatecount, when we need to flush pipeline with new PC, 
  //     we want to reuse the adder in IFU, so we will not pass flush-PC
  //     to IFU, instead, we pass the flush-pc-adder-op1/op2 to IFU
  //     and IFU will just use its adder to caculate the flush-pc-adder-result
  
  input   pipe_flush_ack,
  output  pipe_flush_req,
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2
  );


  wire                      alu_brchmis_flush_ack;
  wire                      alu_brchmis_flush_req;
  wire  [`QPU_PC_SIZE-1:0]  alu_brchmis_flush_add_op1;  
  wire  [`QPU_PC_SIZE-1:0]  alu_brchmis_flush_add_op2;

  wire                      alu_brchmis_cmt_i_ready;


  QPU_exu_branchslv u_QPU_exu_branchslv(
    .cmt_i_ready             (alu_brchmis_cmt_i_ready    ),
    .cmt_i_valid             (alu_cmt_i_valid   ),  
    .cmt_i_bjp               (alu_cmt_i_bjp     ),  
    .cmt_i_bjp_prdt          (alu_cmt_i_bjp_prdt),
    .cmt_i_bjp_rslv          (alu_cmt_i_bjp_rslv),
    .cmt_i_pc                (alu_cmt_i_pc      ),
    .cmt_i_imm               (alu_cmt_i_imm     ),
   
    .brchmis_flush_ack       (alu_brchmis_flush_ack    ),
    .brchmis_flush_req       (alu_brchmis_flush_req    ),
    .brchmis_flush_add_op1   (alu_brchmis_flush_add_op1),  
    .brchmis_flush_add_op2   (alu_brchmis_flush_add_op2)
  );



  assign alu_brchmis_flush_ack = pipe_flush_ack;

  assign pipe_flush_req = alu_brchmis_flush_req;
            
  assign alu_cmt_i_ready = alu_brchmis_cmt_i_ready;

  assign pipe_flush_add_op1 = alu_brchmis_flush_add_op1;  
  assign pipe_flush_add_op2 = alu_brchmis_flush_add_op2;  

  
endmodule                                      
                                               
                                               
                                               
