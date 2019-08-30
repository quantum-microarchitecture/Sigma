                                                                         
//=====================================================================
//
// Designer   : HL
//
// Description:
//  The ifetch module to generate next PC and bus request
//
// ====================================================================



`include "QPU_defines.v"

module QPU_ifu_ifetch(
  output[`QPU_PC_SIZE-1:0] inspect_pc,

  input  [`QPU_PC_SIZE-1:0] pc_rtvec,  



  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Fetch Interface to memory system, internal protocol
  //    * IFetch REQ channel
  output ifu_req_valid, // Handshake valid
  input  ifu_req_ready, // Handshake ready
            // Note: the req-addr can be unaligned with the length indicated
            //       by req_len signal.
            //       The targetd (ITCM, ICache or Sys-MEM) ctrl modules 
            //       will handle the unalign cases and split-and-merge works
  output [`QPU_PC_SIZE-1:0] ifu_req_pc, // Fetch PC
  output ifu_req_seq, // This request is a sequential instruction fetch
                                           // PC address (i.e., pc_r)
  //    * IFetch RSP channel
  input  ifu_rsp_valid, // Response valid 
  output ifu_rsp_ready, // Response ready

            // Note: the RSP channel always return a valid instruction
            //   fetched from the fetching start PC address.
            //   The targetd (ITCM, ICache or Sys-MEM) ctrl modules 
            //   will handle the unalign cases and split-and-merge works
  //input  ifu_rsp_replay,
  input  [`QPU_INSTR_SIZE-1:0] ifu_rsp_instr, // Response instruction

  //////////////////////////////////////////////////////////////


  //////////////////////////////////////////////////////////////
  // The IR stage to EXU interface
  output [`QPU_INSTR_SIZE-1:0] ifu_o_ir,// The instruction register
  output [`QPU_PC_SIZE-1:0] ifu_o_pc,   // The PC register along with
  output ifu_o_pc_vld,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] ifu_o_rs1idx,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] ifu_o_rs2idx,
  output ifu_o_prdt_taken,               // The Bxx is predicted as taken 
  output ifu_o_valid, // Handshake signals with EXU stage
  input  ifu_o_ready,

  output  pipe_flush_ack,
  input   pipe_flush_req,
  input   [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  input   [`QPU_PC_SIZE-1:0] pipe_flush_add_op2,
  `ifdef QPU_TIMING_BOOST//}
  input   [`QPU_PC_SIZE-1:0] pipe_flush_pc,  
  `endif//}



  // The halt request come from other commit stage
  //   If the ifu_halt_req is asserting, then IFU will stop fetching new 
  //     instructions and after the oustanding transactions are completed,
  //     asserting the ifu_halt_ack as the response.
  //   The IFU will resume fetching only after the ifu_halt_req is deasserted
  input  ifu_halt_req,
  output ifu_halt_ack,


  input  clk,
  input  rst_n
  );

  wire ifu_req_hsked  = (ifu_req_valid & ifu_req_ready) ;
  wire ifu_rsp_hsked  = (ifu_rsp_valid & ifu_rsp_ready) ;
  wire ifu_ir_o_hsked = (ifu_o_valid & ifu_o_ready) ;
  wire pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;


 // The rst_flag is the synced version of rst_n
 //    * rst_n is asserted 
 // The rst_flag will be clear when
 //    * rst_n is de-asserted 
  wire reset_flag_r;
  sirv_gnrl_dffrs #(1) reset_flag_dffrs (1'b0, reset_flag_r, clk, rst_n);
 //
 // The reset_req valid is set when 
 //    * Currently reset_flag is asserting
 // The reset_req valid is clear when 
 //    * Currently reset_req is asserting
 //    * Currently the flush can be accepted by IFU
  wire reset_req_r;
  wire reset_req_set = (~reset_req_r) & reset_flag_r;
  wire reset_req_clr = reset_req_r & ifu_req_hsked;
  wire reset_req_ena = reset_req_set | reset_req_clr;
  wire reset_req_nxt = reset_req_set | (~reset_req_clr);

  sirv_gnrl_dfflr #(1) reset_req_dfflr (reset_req_ena, reset_req_nxt, reset_req_r, clk, rst_n);

  wire ifu_reset_req = reset_req_r;




  ///******************************************EXU**********************************************
  ////////////////////////////////////////


   //////////////////////////////////////////////////////////////
   // The halt ack generation
   wire halt_ack_set;
   wire halt_ack_ena;
   wire halt_ack_r;
   wire halt_ack_nxt;

     // The halt_ack will be set when
     //    * Currently halt_req is asserting
     //    * Currently halt_ack is not asserting
     //    * Currently the ifetch REQ channel is ready, means
     //        there is no oustanding transactions
   wire ifu_no_outs;
   assign halt_ack_set = ifu_halt_req & (~halt_ack_r) & ifu_no_outs;
     // The halt_ack_r valid is cleared when 
     //    * Currently halt_ack is asserting
     //    * Currently halt_req is de-asserting

   assign halt_ack_ena = halt_ack_set ;
   assign halt_ack_nxt = halt_ack_set ;

   sirv_gnrl_dfflr #(1) halt_ack_dfflr (halt_ack_ena, halt_ack_nxt, halt_ack_r, clk, rst_n);

   assign ifu_halt_ack = halt_ack_r;


   //////////////////////////////////////////////////////////////



   //////////////////////////////////////////////////////////////
   // The flush ack signal generation
   //
   //   Ideally the flush is acked when the ifetch interface is ready
   //     or there is rsponse valid 
   //   But to cut the comb loop between EXU and IFU, we always accept
   //     the flush, when it is not really acknowledged, we use a 
   //     delayed flush indication to remember this flush
   //   Note: Even if there is a delayed flush pending there, we
   //     still can accept new flush request
   assign pipe_flush_ack = 1'b1;

   wire dly_flush_set;
   wire dly_flush_clr;
   wire dly_flush_ena;
   wire dly_flush_nxt;

      // The dly_flush will be set when
      //    * There is a flush requst is coming, but the ifu
      //        is not ready to accept new fetch request
   wire dly_flush_r;
   assign dly_flush_set = pipe_flush_req & (~ifu_req_hsked);
      // The dly_flush_r valid is cleared when 
      //    * The delayed flush is issued
   assign dly_flush_clr = dly_flush_r & ifu_req_hsked;
   assign dly_flush_ena = dly_flush_set | dly_flush_clr;
   assign dly_flush_nxt = dly_flush_set | (~dly_flush_clr);

   sirv_gnrl_dfflr #(1) dly_flush_dfflr (dly_flush_ena, dly_flush_nxt, dly_flush_r, clk, rst_n);

   wire dly_pipe_flush_req = dly_flush_r;
   wire pipe_flush_req_real = pipe_flush_req | dly_pipe_flush_req;

   //////////////////////////////////////////////////////////////



   //////////////////////////////////////////////////////////////
   // The IR register to be used in EXU for decoding
   wire ir_valid_set;
   wire ir_valid_clr;
   wire ir_valid_ena;
   wire ir_valid_r;
   wire ir_valid_nxt;

   wire ifu_ir_i_ready;
     // The ir valid is set when there is new instruction fetched *and* 
     //   no flush happening 
   assign ir_valid_set  = ifu_rsp_hsked & (~pipe_flush_req_real);
   assign ir_valid_clr  = ifu_ir_o_hsked | (pipe_flush_hsked & ir_valid_r);
   assign ir_valid_ena  = ir_valid_set  | ir_valid_clr;
   assign ir_valid_nxt  = ir_valid_set  | (~ir_valid_clr);
   sirv_gnrl_dfflr #(1) ir_valid_dfflr (ir_valid_ena, ir_valid_nxt, ir_valid_r, clk, rst_n);
   assign ifu_o_valid  = (~halt_ack_r) & ir_valid_r;

   // The IFU-IR stage will be ready when it is empty or under-clearing
   assign ifu_ir_i_ready   = (~ir_valid_r) | ir_valid_clr;

     // IFU-IR loaded with the returned instruction from the IFetch RSP channel
   wire [`QPU_INSTR_SIZE-1:0] ifu_ir_nxt = ifu_rsp_instr;
   wire [`QPU_INSTR_SIZE-1:0] ifu_ir_r;// The instruction register

   wire ir_ena = ir_valid_set;

   sirv_gnrl_dfflr #(`QPU_INSTR_SIZE) ifu_lo_ir_dfflr (ir_ena, ifu_ir_nxt, ifu_ir_r, clk, rst_n); 
   assign ifu_o_ir  = ifu_ir_r;


   wire [`QPU_RFIDX_REAL_WIDTH-1:0] ir_rs1idx_r;
   wire [`QPU_RFIDX_REAL_WIDTH-1:0] ir_rs2idx_r;

   wire ir_rs1idx_ena = ir_valid_set & minidec_rs1en;
   wire ir_rs2idx_ena = ir_valid_set & minidec_rs2en;

   wire [`QPU_RFIDX_REAL_WIDTH-1:0] ir_rs1idx_nxt = minidec_rs1idx;
   wire [`QPU_RFIDX_REAL_WIDTH-1:0] ir_rs2idx_nxt = minidec_rs2idx;  

   sirv_gnrl_dfflr #(`QPU_RFIDX_REAL_WIDTH) ir_rs1idx_dfflr (ir_rs1idx_ena, ir_rs1idx_nxt, ir_rs1idx_r, clk, rst_n);
   sirv_gnrl_dfflr #(`QPU_RFIDX_REAL_WIDTH) ir_rs2idx_dfflr (ir_rs2idx_ena, ir_rs2idx_nxt, ir_rs2idx_r, clk, rst_n);
   assign ifu_o_rs1idx = ir_rs1idx_r;
   assign ifu_o_rs2idx = ir_rs2idx_r;


   //////////////////////////////////////////////////////////////////



   ///////////////////////////////////////////////////////////////////
   //The PC register
   wire ir_pc_vld_set;
   wire ir_pc_vld_clr;
   wire ir_pc_vld_ena;
   wire ir_pc_vld_r;
   wire ir_pc_vld_nxt;

   assign ir_pc_vld_set = pc_newpend_r & ifu_ir_i_ready & (~pipe_flush_req_real);
   assign ir_pc_vld_clr = ir_valid_clr;
   assign ir_pc_vld_ena = ir_pc_vld_set | ir_pc_vld_clr;
   assign ir_pc_vld_nxt = ir_pc_vld_set | (~ir_pc_vld_clr);
   sirv_gnrl_dfflr #(1) ir_pc_vld_dfflr (ir_pc_vld_ena, ir_pc_vld_nxt, ir_pc_vld_r, clk, rst_n);
   assign ifu_o_pc_vld = ir_pc_vld_r;


   wire [`QPU_PC_SIZE-1:0] pc_r;
   wire [`QPU_PC_SIZE-1:0] ifu_pc_nxt = pc_r;
   wire [`QPU_PC_SIZE-1:0] ifu_pc_r;
   sirv_gnrl_dfflr #(`QPU_PC_SIZE) ifu_pc_dfflr (ir_pc_vld_set, ifu_pc_nxt,  ifu_pc_r, clk, rst_n);
   assign ifu_o_pc  = ifu_pc_r;


   wire pc_newpend_r;
         // The pc_newpend will be set if there is a new PC loaded
   wire pc_newpend_set = pc_ena;
     // The pc_newpend will be cleared if have already loaded into the IR-PC stage
   wire pc_newpend_clr = ir_pc_vld_set;
   wire pc_newpend_ena = pc_newpend_set | pc_newpend_clr;
     // If meanwhile set and clear, then set preempt
   wire pc_newpend_nxt = pc_newpend_set | (~pc_newpend_clr);

   sirv_gnrl_dfflr #(1) pc_newpend_dfflr (pc_newpend_ena, pc_newpend_nxt, pc_newpend_r, clk, rst_n);






   wire [2:0] pc_incr_ofst = 3'd4;

   wire [`QPU_PC_SIZE-1:0] pc_nxt_pre;
   wire [`QPU_PC_SIZE-1:0] pc_nxt;  

   wire bjp_req =  (~reset_req_r) & minidec_bxx & prdt_taken ;            //自己添加的


   wire [`QPU_PC_SIZE-1:0] pc_add_op1 = 
                            `ifndef QPU_TIMING_BOOST//}
                               pipe_flush_req  ? pipe_flush_add_op1 :
                               dly_pipe_flush_req  ? pc_r :
                            `endif//}
                               bjp_req ? prdt_pc_add_op1    :
                               ifu_reset_req   ? pc_rtvec :
                                                 pc_r;

   wire [`QPU_PC_SIZE-1:0] pc_add_op2 =  
                            `ifndef QPU_TIMING_BOOST//}
                               pipe_flush_req  ? pipe_flush_add_op2 :
                               dly_pipe_flush_req  ? `QPU_PC_SIZE'b0 :
                            `endif//}
                               bjp_req ? prdt_pc_add_op2    :
                               ifu_reset_req   ? `QPU_PC_SIZE'b0 :
                                                 pc_incr_ofst ;  

   assign pc_nxt_pre = pc_add_op1 + pc_add_op2;
   `ifndef QPU_TIMING_BOOST//}
   assign pc_nxt = {pc_nxt_pre[`QPU_PC_SIZE-1:1],1'b0};
   `else//}{
   assign pc_nxt = 
               pipe_flush_req ? {pipe_flush_pc[`QPU_PC_SIZE-1:1],1'b0} :
               dly_pipe_flush_req ? {pc_r[`QPU_PC_SIZE-1:1],1'b0} :
               {pc_nxt_pre[`QPU_PC_SIZE-1:1],1'b0};
   `endif//}

    // The PC will need to be updated when ifu req channel handshaked or a flush is incoming
   wire pc_ena = ifu_req_hsked | pipe_flush_hsked;
   sirv_gnrl_dfflr #(`QPU_PC_SIZE) pc_dfflr (pc_ena, pc_nxt, pc_r, clk, rst_n);
   assign inspect_pc = pc_r;


   assign ifu_req_pc    = pc_nxt;






  ///////////////////////////////////////////////////////////////////
  //********************************************************************************************




  //****************************************litebpu*********************************************

   wire prdt_taken;  
   wire ifu_prdt_taken_r;
   sirv_gnrl_dfflr #(1) ifu_prdt_taken_dfflr (ir_valid_set, prdt_taken, ifu_prdt_taken_r, clk, rst_n);
   assign ifu_o_prdt_taken = ifu_prdt_taken_r;

   wire minidec_bxx;
   wire [`QPU_XLEN-1:0] minidec_bjp_imm;


   wire [`QPU_PC_SIZE-1:0] prdt_pc_add_op1;  
   wire [`QPU_PC_SIZE-1:0] prdt_pc_add_op2;

   QPU_ifu_litebpu u_QPU_ifu_litebpu(

    .pc                       (pc_r),
                              
    .dec_bxx                  (minidec_bxx  ),
    .dec_bjp_imm              (minidec_bjp_imm  ),

    .prdt_taken               (prdt_taken     ),  
    .prdt_pc_add_op1          (prdt_pc_add_op1),  
    .prdt_pc_add_op2          (prdt_pc_add_op2)
            
   );  



  //********************************************************************************************




  //*****************************************minidec*********************************************

   wire minidec_rs1en;
   wire minidec_rs2en;
   wire [`QPU_RFIDX_REAL_WIDTH-1:0] minidec_rs1idx;
   wire [`QPU_RFIDX_REAL_WIDTH-1:0] minidec_rs2idx;

   QPU_ifu_minidec u_QPU_ifu_minidec (
      .instr       (ifu_ir_nxt         ),

      .dec_rs1en   (minidec_rs1en      ),
      .dec_rs2en   (minidec_rs2en      ),
      .dec_rs1idx  (minidec_rs1idx     ),
      .dec_rs2idx  (minidec_rs2idx     ),

      .dec_bxx     (minidec_bxx        ),

      .dec_bjp_imm (minidec_bjp_imm    )

   );  

  //*********************************************************************************************




  //*****************************************ift2icb*********************************************

   assign ifu_req_seq = (~pipe_flush_req_real) & (~ifu_reset_req) & (~bjp_req);


   wire ifu_new_req = (~halt_ack_r) & (~reset_flag_r);           //改了
   // The fetch request valid is triggering when
   //      * New ifetch request
   //      * or The flush-request is pending
   wire ifu_req_valid_pre = ifu_new_req | ifu_reset_req | pipe_flush_req_real;
   // The new request ready condition is:
   //   * No outstanding reqeusts
   //   * Or if there is outstanding, but it is reponse valid back


   wire out_flag_clr;
   wire out_flag_r;
     // The out_flag will be set if there is a new request handshaked
   wire out_flag_set = ifu_req_hsked;
     // The out_flag will be cleared if there is a request response handshaked
   assign out_flag_clr = ifu_rsp_hsked;
   wire out_flag_ena = out_flag_set | out_flag_clr;
     // If meanwhile set and clear, then set preempt
   wire out_flag_nxt = out_flag_set | (~out_flag_clr);
   sirv_gnrl_dfflr #(1) out_flag_dfflr (out_flag_ena, out_flag_nxt, out_flag_r, clk, rst_n);


   wire new_req_condi = (~out_flag_r) | out_flag_clr;
   assign ifu_no_outs   = (~out_flag_r) | ifu_rsp_valid;
        // Here we use the rsp_valid rather than the out_flag_clr (ifu_rsp_hsked) because
        //   as long as the rsp_valid is asserting then means last request have returned the
        //   response back, in WFI case, we cannot expect it to be handshaked (otherwise deadlock)
   assign ifu_req_valid = ifu_req_valid_pre & new_req_condi;
   wire ifu_rsp2ir_ready = (pipe_flush_req_real) ? 1'b1 : (ifu_ir_i_ready & ifu_req_ready);

   // Response channel only ready when:
   //   * IR is ready to accept new instructions
   assign ifu_rsp_ready = ifu_rsp2ir_ready;


endmodule