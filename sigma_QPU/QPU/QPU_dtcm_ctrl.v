//=====================================================================
//
// Designer   : HL
//
// Description:
//  The dtcm_ctrl module control the DTCM access requests 
//
// ====================================================================


`include "QPU_defines.v"

module qpu_dtcm_ctrl(
  output dtcm_active,
  // The cgstop is coming from CSR (0xBFE mcgstop)'s filed 1
  // // This register is our self-defined CSR register to disable the 
      // DTCM SRAM clock gating for debugging purpose
  input  tcm_cgstop,
  // Note: the DTCM ICB interface only support the single-transaction
  
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // LSU ICB to DTCM
  //    * Bus cmd channel
  input  lsu_icb_cmd_valid, // Handshake valid
  output lsu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  input  [`QPU_DTCM_ADDR_WIDTH-1:0]   lsu_icb_cmd_addr, // Bus transaction start addr 
  input  lsu_icb_cmd_read,   // Read or write
  input  [32-1:0] lsu_icb_cmd_wdata, 
  input  [4-1:0] lsu_icb_cmd_wmask,

  //    * Bus RSP channel
  output lsu_icb_rsp_valid, // Response valid 
  input  lsu_icb_rsp_ready, // Response ready
            // Note: the RSP rdata is inline with AXI definition
  output [32-1:0] lsu_icb_rsp_rdata, 


  output                         dtcm_ram_cs,  
  output                         dtcm_ram_we,  
  output [`QPU_DTCM_RAM_AW-1:0] dtcm_ram_addr, 
  output [`QPU_DTCM_RAM_MW-1:0] dtcm_ram_wem,
  output [`QPU_DTCM_RAM_DW-1:0] dtcm_ram_din,          
  input  [`QPU_DTCM_RAM_DW-1:0] dtcm_ram_dout,
  output                         clk_dtcm_ram,

  input  test_mode,
  input  clk,
  input  rst_n
  );


  wire dtcm_sram_ctrl_active;

  assign dtcm_active = lsu_icb_cmd_valid | dtcm_sram_ctrl_active;


    sirv_sram_icb_ctrl #(
      .DW     (`QPU_DTCM_DATA_WIDTH),
      .AW     (`QPU_DTCM_ADDR_WIDTH),
      .MW     (`QPU_DTCM_WMSK_WIDTH),
      .AW_LSB (2),// DTCM is 32bits wide, so the LSB is 2
      .USR_W  (1) 
  ) u_sram_icb_ctrl (
     .sram_ctrl_active (dtcm_sram_ctrl_active),
     .tcm_cgstop       (tcm_cgstop),
     
     .i_icb_cmd_valid (lsu_icb_cmd_valid),
     .i_icb_cmd_ready (lsu_icb_cmd_ready),
     .i_icb_cmd_read  (lsu_icb_cmd_read ),
     .i_icb_cmd_addr  (lsu_icb_cmd_addr ), 
     .i_icb_cmd_wdata (lsu_icb_cmd_wdata), 
     .i_icb_cmd_wmask (lsu_icb_cmd_wmask), 
     .i_icb_cmd_usr   (),
  
     .i_icb_rsp_valid (lsu_icb_rsp_valid),
     .i_icb_rsp_ready (lsu_icb_rsp_ready),
     .i_icb_rsp_rdata (lsu_icb_rsp_rdata),
     .i_icb_rsp_usr   (),
  
     .ram_cs   (dtcm_ram_cs  ),  
     .ram_we   (dtcm_ram_we  ),  
     .ram_addr (dtcm_ram_addr), 
     .ram_wem  (dtcm_ram_wem ),
     .ram_din  (dtcm_ram_din ),          
     .ram_dout (dtcm_ram_dout),
     .clk_ram  (clk_dtcm_ram ),
  
     .test_mode(test_mode  ),
     .clk  (clk  ),
     .rst_n(rst_n)  
    );


endmodule