//=====================================================================
//
// Designer   : HL
//
// Description:
//  The DTCM-SRAM module to implement DTCM SRAM
//
// ====================================================================
`include "QPU_defines.v"


module QPU_dtcm_ram(

  input                              sd,
  input                              ds,
  input                              ls,

  input                              cs,  
  input                              we,  
  input  [`QPU_DTCM_RAM_AW-1:0] addr, 
  input  [`QPU_DTCM_RAM_MW-1:0] wem,
  input  [`QPU_DTCM_RAM_DW-1:0] din,          
  output [`QPU_DTCM_RAM_DW-1:0] dout,
  input                              rst_n,
  input                              clk

);

  sirv_gnrl_ram #(
    .FORCE_X2ZERO(1),//Always force X to zeros
    .DP(`QPU_DTCM_RAM_DP),
    .DW(`QPU_DTCM_RAM_DW),
    .MW(`QPU_DTCM_RAM_MW),
    .AW(`QPU_DTCM_RAM_AW) 
  ) u_QPU_dtcm_gnrl_ram(
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

