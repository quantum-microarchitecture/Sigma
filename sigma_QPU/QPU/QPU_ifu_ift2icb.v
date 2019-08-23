//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The ift2icb module convert the fetch request to ICB (Internal Chip bus) 
//  and dispatch to ITCM.
//
// ====================================================================

`include "QPU_defines.v"

module QPU_ifu_ift2icb(

  input  itcm_nohold,
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Fetch Interface to memory system, internal protocol
  //    * IFetch REQ channel
  input  ifu_req_valid, // Handshake valid
  output ifu_req_ready, // Handshake ready
            // Note: the req-addr can be unaligned with the length indicated
            //       by req_len signal.
            //       The targetd (ITCM, ICache or Sys-MEM) ctrl modules 
            //       will handle the unalign cases and split-and-merge works
  input  [`QPU_PC_SIZE-1:0] ifu_req_pc, // Fetch PC
  input  ifu_req_seq, // This request is a sequential instruction fetch
                             
  //    * IFetch RSP channel
  output ifu_rsp_valid, // Response valid 
  input  ifu_rsp_ready, // Response ready

            // Note: the RSP channel always return a valid instruction
            //   fetched from the fetching start PC address.
            //   The targetd (ITCM, ICache or Sys-MEM) ctrl modules 
            //   will handle the unalign cases and split-and-merge works
  //output ifu_rsp_replay,   // Response error
  output [32-1:0] ifu_rsp_instr, // Response instruction

  `ifdef QPU_HAS_ITCM //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  //    * Bus cmd channel
  output ifu_icb_cmd_valid, // Handshake valid
  input  ifu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [`QPU_ITCM_ADDR_WIDTH-1:0]   ifu_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  input  ifu_icb_rsp_valid, // Response valid 
  output ifu_icb_rsp_ready, // Response ready
            // Note: the RSP rdata is inline with AXI definition
  input  [`QPU_ITCM_DATA_WIDTH-1:0] ifu_icb_rsp_rdata, 

  `endif//}


  // The holdup indicating the target is not accessed by other agents 
  // since last accessed by IFU, and the output of it is holding up
  // last value. 
  `ifdef QPU_HAS_ITCM //{
  input  ifu_holdup,
  //input  ifu_replay,
  `endif//}

  input  clk,
  input  rst_n
  );

  wire i_ifu_rsp_valid;
  wire i_ifu_rsp_ready;

  wire [`QPU_INSTR_SIZE-1:0] ifu_rsp_bypbuf_i_data;
  wire [`QPU_INSTR_SIZE-1:0] ifu_rsp_bypbuf_o_data;

  assign ifu_rsp_bypbuf_i_data = i_ifu_rsp_instr;

  assign ifu_rsp_instr = ifu_rsp_bypbuf_o_data;

  sirv_gnrl_bypbuf # (
    .DP(1),
    .DW(`QPU_INSTR_SIZE) 
  ) u_QPU_ifetch_rsp_bypbuf(
      .i_vld   (i_ifu_rsp_valid),
      .i_rdy   (i_ifu_rsp_ready),

      .o_vld   (ifu_rsp_valid),
      .o_rdy   (ifu_rsp_ready),

      .i_dat   (ifu_rsp_bypbuf_i_data),
      .o_dat   (ifu_rsp_bypbuf_o_data),
  
      .clk     (clk  ),
      .rst_n   (rst_n)
  );
 
 //***************************************ifetch************************************

  //   * If the new ifetch address is in the same lane portion as last fetch
  //     address (current PC):
  //     ** If it is not crossing the lane boundry, and the current lane rdout is 
  //        holding up, then
  //        ---- Not issue ICB cmd request, just directly use current holding rdata
  //            ---- Put aligned rdata into IR (upper 16bits 
  //                    only loaded when instr is 32bits-long)




  wire ifu_req_lane_begin = 1'b0 | (ifu_req_pc[2:1] == 2'b00);
  wire ifu_req_lane_same = ifu_req_seq & (ifu_req_lane_begin ? 1'b0 : 1'b1 );  
  wire ifu_req_lane_holdup = 1'b0 | ifu_holdup & (~itcm_nohold);


  wire ifu_req_hsked = ifu_req_valid & ifu_req_ready;
  wire i_ifu_rsp_hsked = i_ifu_rsp_valid & i_ifu_rsp_ready;
  wire ifu_icb_cmd_hsked = ifu_icb_cmd_valid & ifu_icb_cmd_ready;
  wire ifu_icb_rsp_hsked = ifu_icb_rsp_valid & ifu_icb_rsp_ready;


  wire icb_cmd_addr_2_1_ena = ifu_icb_cmd_hsked | ifu_req_hsked;
  wire [1:0] icb_cmd_addr_2_1_r;
  sirv_gnrl_dffl #(2)icb_addr_2_1_dffl(icb_cmd_addr_2_1_ena, ifu_icb_cmd_addr[2:1], icb_cmd_addr_2_1_r, clk);

  assign ifu_icb_cmd_addr = ifu_req_pc;
  
  wire[31:0] i_ifu_rsp_instr = 
                    ({32{icb_cmd_addr_2_1_r == 2'b00}} & ifu_icb_rsp_rdata[31:0]) 
                  | ({32{icb_cmd_addr_2_1_r == 2'b10}} & ifu_icb_rsp_rdata[63:32])
                     ;




  wire ifu_req_ready_condi = icb_sta_is_idle | (icb_sta_is_1st & i_ifu_rsp_hsked) ;

  wire ifu_req_valid_pos = ifu_req_valid     & ifu_req_ready_condi;

  assign ifu_icb_cmd_valid = ifu_req_valid_pos & (~req_need_0uop);

  assign ifu_req_ready     = ifu_icb_cmd_ready & ifu_req_ready_condi;




  //Did not issue ICB CMD request, and just use last holdup values, then
  //               we generate a fake response valid
  wire holdup_gen_fake_rsp_valid = icb_sta_is_1st & req_need_0uop_r;  

  assign i_ifu_rsp_valid = holdup_gen_fake_rsp_valid | ifu_icb_rsp_valid;

  assign ifu_icb_rsp_ready = i_ifu_rsp_ready ;

  


 /////////////////////////////////////////////////////////////////////////
  // Implement the state machine for the ifetch req interface
  wire req_need_0uop_r;  

  localparam ICB_STATE_WIDTH  = 1;
  // State 0: The idle state, means there is no any oustanding ifetch request
  localparam ICB_STATE_IDLE = 1'd0;
  // State 1: Issued request and wait response
  localparam ICB_STATE_1ST  = 1'd1;

  wire [ICB_STATE_WIDTH-1:0] icb_state_nxt;
  wire [ICB_STATE_WIDTH-1:0] icb_state_r;
  wire icb_state_ena;
  wire [ICB_STATE_WIDTH-1:0] state_idle_nxt   ;
  wire [ICB_STATE_WIDTH-1:0] state_1st_nxt    ;
  wire state_idle_exit_ena     ;
  wire state_1st_exit_ena      ;
  wire icb_sta_is_idle    = (icb_state_r == ICB_STATE_IDLE   );
  wire icb_sta_is_1st     = (icb_state_r == ICB_STATE_1ST    );

  // **** If the current state is idle,
  // If a new request come, next state is ICB_STATE_1ST
  assign state_idle_exit_ena = icb_sta_is_idle & ifu_req_hsked;
  assign state_idle_nxt      = ICB_STATE_1ST;

  // **** If the current state is 1st,
  // If a response come, exit this state
  assign state_1st_exit_ena  = icb_sta_is_1st & i_ifu_rsp_hsked;
  assign state_1st_nxt     = ifu_req_hsked  ?  ICB_STATE_1ST : ICB_STATE_IDLE;

  assign icb_state_ena = state_idle_exit_ena | state_1st_exit_ena;

  assign icb_state_nxt = 
              ({ICB_STATE_WIDTH{state_idle_exit_ena   }} & state_idle_nxt   )
            | ({ICB_STATE_WIDTH{state_1st_exit_ena    }} & state_1st_nxt    );

  sirv_gnrl_dfflr #(ICB_STATE_WIDTH) icb_state_dfflr (icb_state_ena, icb_state_nxt, icb_state_r, clk, rst_n);

  wire req_need_0uop         = ifu_req_lane_same & ifu_req_lane_holdup;
  sirv_gnrl_dfflr #(1) req_need_0uop_dfflr         (ifu_req_hsked, req_need_0uop,         req_need_0uop_r,         clk, rst_n);

 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////



endmodule




























































































