//=====================================================================
//
// Designer   : HL
//
// Description:
//  The SRAM module to implement all SRAMs
//
// ====================================================================

`include "QPU_defines.v"

module QPU_srams(

  input  itcm_ram_sd,
  input  itcm_ram_ds,
  input  itcm_ram_ls,

  input                          itcm_ram_cs,  
  input                          itcm_ram_we,  
  input  [`QPU_ITCM_RAM_AW-1:0] itcm_ram_addr, 
  input  [`QPU_ITCM_RAM_MW-1:0] itcm_ram_wem,
  input  [`QPU_ITCM_RAM_DW-1:0] itcm_ram_din,          
  output [`QPU_ITCM_RAM_DW-1:0] itcm_ram_dout,
  input                          clk_itcm_ram,
  input  rst_itcm,


  input  dtcm_ram_sd,
  input  dtcm_ram_ds,
  input  dtcm_ram_ls,

  input                          dtcm_ram_cs,  
  input                          dtcm_ram_we,  
  input  [`QPU_DTCM_RAM_AW-1:0] dtcm_ram_addr, 
  input  [`QPU_DTCM_RAM_MW-1:0] dtcm_ram_wem,
  input  [`QPU_DTCM_RAM_DW-1:0] dtcm_ram_din,          
  output [`QPU_DTCM_RAM_DW-1:0] dtcm_ram_dout,
  input                          clk_dtcm_ram,
  input  rst_dtcm,

  input  test_mode

);


                                                      
  wire [`QPU_ITCM_RAM_DW-1:0]  itcm_ram_dout_pre;

  QPU_itcm_ram u_QPU_itcm_ram (
    .sd   (itcm_ram_sd),
    .ds   (itcm_ram_ds),
    .ls   (itcm_ram_ls),
  
    .cs   (itcm_ram_cs   ),
    .we   (itcm_ram_we   ),
    .addr (itcm_ram_addr ),
    .wem  (itcm_ram_wem  ),
    .din  (itcm_ram_din  ),
    .dout (itcm_ram_dout_pre ),
    .rst_n(rst_itcm      ),
    .clk  (clk_itcm_ram  )
    );
    
  // Bob: we dont need this bypass here, actually the DFT tools will handle this SRAM black box 
  //assign itcm_ram_dout = test_mode ? itcm_ram_din : itcm_ram_dout_pre;
  assign itcm_ram_dout = itcm_ram_dout_pre;


  wire [`QPU_DTCM_RAM_DW-1:0]  dtcm_ram_dout_pre;

  QPU_dtcm_ram u_QPU_dtcm_ram (
    .sd   (dtcm_ram_sd),
    .ds   (dtcm_ram_ds),
    .ls   (dtcm_ram_ls),
  
    .cs   (dtcm_ram_cs   ),
    .we   (dtcm_ram_we   ),
    .addr (dtcm_ram_addr ),
    .wem  (dtcm_ram_wem  ),
    .din  (dtcm_ram_din  ),
    .dout (dtcm_ram_dout_pre ),
    .rst_n(rst_dtcm      ),
    .clk  (clk_dtcm_ram  )
    );
    
  // Bob: we dont need this bypass here, actually the DFT tools will handle this SRAM black box 
  //assign dtcm_ram_dout = test_mode ? dtcm_ram_din : dtcm_ram_dout_pre;
  assign dtcm_ram_dout = dtcm_ram_dout_pre;


endmodule




















