//=====================================================================
// Designer   : HL
//
// Description:
//  The lsu_ctrl module control the LSU access requests 
//
// ====================================================================

`include "QPU_defines.v"

module qpu_lsu_ctrl(
  output lsu_ctrl_active,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The LSU Write-Back Interface
  output lsu_o_valid, // Handshake valid
  input  lsu_o_ready, // Handshake ready
  output [`QPU_XLEN-1:0] lsu_o_wbck_wdat,
  output [`QPU_ITAG_WIDTH -1:0] lsu_o_wbck_itag,
  output [`QPU_ADDR_SIZE -1:0] lsu_o_cmt_badaddr,
  output lsu_o_cmt_ld,
  output lsu_o_cmt_st,
  

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The AGU ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  input                          agu_icb_cmd_valid, // Handshake valid
  output                         agu_icb_cmd_ready, // Handshake ready
  input  [`QPU_ADDR_SIZE-1:0]   agu_icb_cmd_addr, // Bus transaction start addr 
  input                          agu_icb_cmd_read,   // Read or write
  input  [`QPU_XLEN-1:0]        agu_icb_cmd_wdata, 
  input  [`QPU_XLEN/8-1:0]      agu_icb_cmd_wmask, 
           //   RD Regfile index
  input  [`QPU_ITAG_WIDTH -1:0] agu_icb_cmd_itag,


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to DTCM
  //
  //    * Bus cmd channel
  output                         dtcm_icb_cmd_valid,
  input                          dtcm_icb_cmd_ready,
  output [`QPU_DTCM_ADDR_WIDTH-1:0]   dtcm_icb_cmd_addr, 
  output                         dtcm_icb_cmd_read, 
  output [`QPU_XLEN-1:0]        dtcm_icb_cmd_wdata,
  output [`QPU_XLEN/8-1:0]      dtcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          dtcm_icb_rsp_valid,
  output                         dtcm_icb_rsp_ready,
  input  [`QPU_XLEN-1:0]        dtcm_icb_rsp_rdata,


  input  clk,
  input  rst_n
  );

  assign dtcm_icb_cmd_valid = ~splt_fifo_full & agu_icb_cmd_valid;
  assign agu_icb_cmd_ready     = ~splt_fifo_full & dtcm_icb_cmd_ready;

  assign dtcm_icb_cmd_addr  = agu_icb_cmd_addr [`QPU_DTCM_ADDR_WIDTH-1:0]; 
  assign dtcm_icb_cmd_read  = agu_icb_cmd_read ; 
  assign dtcm_icb_cmd_wdata = agu_icb_cmd_wdata;
  assign dtcm_icb_cmd_wmask = agu_icb_cmd_wmask;


  assign lsu_o_valid       = dtcm_icb_rsp_valid;
  assign dtcm_icb_rsp_ready = lsu_o_ready;
  assign lsu_o_wbck_wdat = dtcm_icb_cmd_wdata;
  assign lsu_o_wbck_itag   = agu_icb_rsp_itag;
  assign lsu_o_cmt_badaddr = agu_icb_rsp_addr;
  assign lsu_o_cmt_ld=  agu_icb_rsp_read;
  assign lsu_o_cmt_st= ~agu_icb_rsp_read;



  localparam USR_W = (`QPU_ITAG_WIDTH+2+`QPU_ADDR_SIZE);
  localparam SPLT_FIFO_W = USR_W;
  wire [SPLT_FIFO_W-1:0] splt_fifo_wdat;
  wire [SPLT_FIFO_W-1:0] splt_fifo_rdat;

  wire splt_fifo_wen = agu_icb_cmd_valid & agu_icb_cmd_ready;
  wire splt_fifo_ren = lsu_o_valid & lsu_o_ready;
  wire splt_fifo_i_ready;
  wire splt_fifo_i_valid = splt_fifo_wen;
  wire splt_fifo_full    = (~splt_fifo_i_ready);
  wire splt_fifo_o_valid;
  wire splt_fifo_o_ready = splt_fifo_ren;
  wire splt_fifo_empty   = (~splt_fifo_o_valid);

  wire [USR_W-1:0] agu_icb_cmd_usr =
      { 
         agu_icb_cmd_read
        ,agu_icb_cmd_itag 
        ,agu_icb_cmd_addr 
      };

  assign splt_fifo_wdat = agu_icb_cmd_usr ; 

  assign agu_icb_rsp_usr = splt_fifo_rdat & {SPLT_FIFO_W{splt_fifo_o_valid}};

  assign { agu_icb_rsp_read
          ,agu_icb_rsp_itag 
          ,agu_icb_rsp_addr} = agu_icb_rsp_usr;



  `ifdef QPU_LSU_OUTS_NUM_IS_1 //{
  sirv_gnrl_pipe_stage # (
    .CUT_READY(0),
    .DP(1),
    .DW(SPLT_FIFO_W)
  ) u_QPU_lsu_splt_stage (
    .i_vld  (splt_fifo_i_valid),
    .i_rdy  (splt_fifo_i_ready),
    .i_dat  (splt_fifo_wdat ),
    .o_vld  (splt_fifo_o_valid),
    .o_rdy  (splt_fifo_o_ready),  
    .o_dat  (splt_fifo_rdat ),  
  
    .clk  (clk),
    .rst_n(rst_n)
  );
  `else//}{
  sirv_gnrl_fifo # (
    .CUT_READY (0),// When entry is clearing, it can also accept new one
    .MSKO      (0),
    // The depth of OITF determined how many oustanding can be dispatched to long pipeline
    .DP  (`QPU_LSU_OUTS_NUM),
    .DW  (SPLT_FIFO_W)//
  ) u_QPU_lsu_splt_fifo (
    .i_vld  (splt_fifo_i_valid),
    .i_rdy  (splt_fifo_i_ready),
    .i_dat  (splt_fifo_wdat ),
    .o_vld  (splt_fifo_o_valid),
    .o_rdy  (splt_fifo_o_ready),  
    .o_dat  (splt_fifo_rdat ),  
    .clk  (clk),
    .rst_n(rst_n)
  );
  `endif//}

  assign lsu_ctrl_active = agu_icb_cmd_valid | splt_fifo_o_valid;


endmodule



































