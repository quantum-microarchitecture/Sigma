//=====================================================================
// Designer   : HL
//
// Description:
//  The ITCM-SRAM module to implement ITCM SRAM
//
// ====================================================================

`include "QPU_defines.v"

module QPU_itcm_ram(

  input                              sd,
  input                              ds,
  input                              ls,

  input                              cs,  
  input                              we,  
  input  [`QPU_ITCM_RAM_AW-1:0] addr, 
  input  [`QPU_ITCM_RAM_MW-1:0] wem,
  input  [`QPU_ITCM_RAM_DW-1:0] din,          
  output [`QPU_ITCM_RAM_DW-1:0] dout,
  input                              rst_n,
  input                              clk

);

 
  sirv_gnrl_itcm_ram #(
      `ifndef QPU_HAS_ECC//{
    .FORCE_X2ZERO(0),
      `endif//}
    .DP(`QPU_ITCM_RAM_DP),
    .DW(`QPU_ITCM_RAM_DW),
    .MW(`QPU_ITCM_RAM_MW),
    .AW(`QPU_ITCM_RAM_AW) 
  ) u_QPU_itcm_gnrl_ram(
  .sd  (sd  ),
  .ds  (ds  ),
  .ls  (ls  ),

  .rst_n (rst_n ),
  .clk (clk ),
  .cs  (cs  ),
  .we  (we  ),
  .addr(addr),
  .din (din ),
  .wem (wem ),
  .dout(dout)
  );
                                                      
endmodule












































