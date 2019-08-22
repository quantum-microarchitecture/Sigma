//=====================================================================
//
// Designer   : HL
//
// Description:
//  The itcm_ctrl module control the ITCM access requests 
//
// ====================================================================
`include "QPU_defines.v"


module QPU_itcm_ctrl(
  output itcm_active,
  // The cgstop is coming from CSR (0xBFE mcgstop)'s filed 1
  // // This register is our self-defined CSR register to disable the 
      // ITCM SRAM clock gating for debugging purpose
  input  tcm_cgstop,
  // Note: the ITCM ICB interface only support the single-transaction
  
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // IFU ICB to ITCM
  //    * Bus cmd channel
  input  ifu_icb_cmd_valid, // Handshake valid
  output ifu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  input  [`QPU_ITCM_ADDR_WIDTH-1:0] ifu_icb_cmd_addr, // Bus transaction start addr 
  input  ifu_icb_cmd_read,   // Read or write
  input  [`QPU_ITCM_DATA_WIDTH-1:0] ifu_icb_cmd_wdata, 
  input  [`QPU_ITCM_WMSK_WIDTH-1:0] ifu_icb_cmd_wmask, 

  //    * Bus RSP channel
  output ifu_icb_rsp_valid, // Response valid 
  input  ifu_icb_rsp_ready, // Response ready
            // Note: the RSP rdata is inline with AXI definition
  output [`QPU_ITCM_DATA_WIDTH-1:0] ifu_icb_rsp_rdata, 
  
  output ifu_holdup,

  output                         itcm_ram_cs,  
  output                         itcm_ram_we,  
  output [`QPU_ITCM_RAM_AW-1:0] itcm_ram_addr, 
  output [`QPU_ITCM_RAM_MW-1:0] itcm_ram_wem,
  output [`QPU_ITCM_RAM_DW-1:0] itcm_ram_din,          
  input  [`QPU_ITCM_RAM_DW-1:0] itcm_ram_dout,
  output                         clk_itcm_ram,

  input  test_mode,
  input  clk,
  input  rst_n
  );

  wire itcm_sram_ctrl_active;

  assign ifu_holdup = 1'b1;

  assign itcm_active = ifu_icb_cmd_valid | itcm_sram_ctrl_active;


  `ifndef QPU_HAS_ECC //{
  sirv_sram_icb_ctrl #(
      .DW     (`QPU_ITCM_DATA_WIDTH),
      .AW     (`QPU_ITCM_ADDR_WIDTH),
      .MW     (`QPU_ITCM_WMSK_WIDTH),
      .AW_LSB (3),// ITCM is 64bits wide, so the LSB is 3
      .USR_W  (2) 
  ) u_sram_icb_ctrl(
     .sram_ctrl_active (itcm_sram_ctrl_active),
     .tcm_cgstop       (tcm_cgstop),
     
     .i_icb_cmd_valid (ifu_icb_cmd_valid),
     .i_icb_cmd_ready (ifu_icb_cmd_ready),
     .i_icb_cmd_read  (ifu_icb_cmd_read ),
     .i_icb_cmd_addr  (ifu_icb_cmd_addr), 
     .i_icb_cmd_wdata (ifu_icb_cmd_wdata), 
     .i_icb_cmd_wmask (ifu_icb_cmd_wmask), 
     .i_icb_cmd_usr   (),
  
     .i_icb_rsp_valid (ifu_icb_rsp_valid),
     .i_icb_rsp_ready (ifu_icb_rsp_ready),
     .i_icb_rsp_rdata (ifu_icb_rsp_rdata),
     .i_icb_rsp_usr   (),
  
     .ram_cs   (itcm_ram_cs  ),  
     .ram_we   (itcm_ram_we  ),  
     .ram_addr (itcm_ram_addr), 
     .ram_wem  (itcm_ram_wem ),
     .ram_din  (itcm_ram_din ),          
     .ram_dout (itcm_ram_dout),
     .clk_ram  (clk_itcm_ram ),
  
     .test_mode(test_mode  ),
     .clk  (clk  ),
     .rst_n(rst_n)  
    );

  `endif//}



endmodule 














































