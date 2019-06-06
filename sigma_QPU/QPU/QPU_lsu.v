//=====================================================================
// Designer   : HL
//
// Description:
//  The lsu_ctrl module control the LSU access requests 
//
// ====================================================================

`include "QPU_defines.v"

module qpu_lsu(
  input  excp_active,
  output  lsu_active,

  //////////////////////////////////////////////////////////////
  // The LSU Write-Back Interface
  output lsu_o_valid, // Handshake valid
  input  lsu_o_ready, // Handshake ready
  output [`QPU_XLEN-1:0] lsu_o_wbck_wdat,
  output [`QPU_ITAG_WIDTH -1:0] lsu_o_wbck_itag,
  output lsu_o_cmt_ld,
  output lsu_o_cmt_st,
  output [`QPU_ADDR_SIZE -1:0] lsu_o_cmt_badaddr,
  
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

  //    * Bus RSP channel
  input                          dtcm_icb_rsp_valid,
  output                         dtcm_icb_rsp_ready,
  input  [`QPU_XLEN-1:0]        dtcm_icb_rsp_rdata,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////

  input  clk,
  input  rst_n
  );



  wire lsu_ctrl_active;


  QPU_lsu_ctrl u_QPU_lsu_ctrl(
    .lsu_ctrl_active       (lsu_ctrl_active),

    .lsu_o_valid           (lsu_o_valid ),
    .lsu_o_ready           (lsu_o_ready ),
    .lsu_o_wbck_wdat       (lsu_o_wbck_wdat),
    .lsu_o_wbck_itag       (lsu_o_wbck_itag),
    .lsu_o_cmt_badaddr     (lsu_o_cmt_badaddr ),
    .lsu_o_cmt_ld          (lsu_o_cmt_ld ),
    .lsu_o_cmt_st          (lsu_o_cmt_st ),
    
    .agu_icb_cmd_valid     (agu_icb_cmd_valid ),
    .agu_icb_cmd_ready     (agu_icb_cmd_ready ),
    .agu_icb_cmd_addr      (agu_icb_cmd_addr ),
    .agu_icb_cmd_read      (agu_icb_cmd_read   ),
    .agu_icb_cmd_wdata     (agu_icb_cmd_wdata ),
    .agu_icb_cmd_wmask     (agu_icb_cmd_wmask ),
   
    .agu_icb_cmd_itag      (agu_icb_cmd_itag),


    .dtcm_icb_cmd_valid    (dtcm_icb_cmd_valid),
    .dtcm_icb_cmd_ready    (dtcm_icb_cmd_ready),
    .dtcm_icb_cmd_addr     (dtcm_icb_cmd_addr ),
    .dtcm_icb_cmd_read     (dtcm_icb_cmd_read ),
    .dtcm_icb_cmd_wdata    (dtcm_icb_cmd_wdata),
    .dtcm_icb_cmd_wmask    (dtcm_icb_cmd_wmask),
    
    .dtcm_icb_rsp_valid    (dtcm_icb_rsp_valid),
    .dtcm_icb_rsp_ready    (dtcm_icb_rsp_ready),
    .dtcm_icb_rsp_rdata    (dtcm_icb_rsp_rdata),
           

    .clk                   (clk),
    .rst_n                 (rst_n)
  );

  assign lsu_active = lsu_ctrl_active 
                    // When interrupts comes, need to update the exclusive monitor
                    // so also need to turn on the clock
                    | excp_active;
                    
endmodule
































