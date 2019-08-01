                                                           
                                                                         
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  This module to implement the LSU 
//
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_alu_lsu(

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Issue Handshake Interface to LSU 
  //
  input  lsu_i_valid, // Handshake valid
  output lsu_i_ready, // Handshake ready

  input  [`QPU_XLEN-1:0] lsu_i_rs1,
  input  [`QPU_XLEN-1:0] lsu_i_rs2,
  input  [`QPU_XLEN-1:0] lsu_i_imm,
  input  [`QPU_DECINFO_LSU_WIDTH-1:0] lsu_i_info,


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The LSU Write-Back/Commit Interface
  output lsu_o_valid, // Handshake valid
  input  lsu_o_ready, // Handshake ready
 

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  output                       lsu_icb_cmd_valid, // Handshake valid
  input                        lsu_icb_cmd_ready, // Handshake ready

  output [`QPU_ADDR_SIZE-1:0]  lsu_icb_cmd_addr,  // Bus transaction start addr 
  output                       lsu_icb_cmd_read,   // Read or write
  output [`QPU_XLEN-1:0]       lsu_icb_cmd_wdata, 
  output [`QPU_XLEN/8-1:0]     lsu_icb_cmd_wmask, 
  
  //    * Bus RSP channel
  input                        lsu_icb_rsp_valid, // Response valid 
  output                       lsu_icb_rsp_ready, // Response ready


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // To share the ALU datapath, generate interface to ALU
  //   for single-issue machine, seems the LSU must be shared with ALU, otherwise
  //   it wasted the area for no points 
  // 
     // The operands and info to ALU
  output [`QPU_XLEN-1:0] lsu_req_alu_op1,
  output [`QPU_XLEN-1:0] lsu_req_alu_op2,
  input  [`QPU_XLEN-1:0] lsu_req_alu_res


  );

  wire lsu_i_load    = lsu_i_info [`QPU_DECINFO_LSU_LOAD   ];
  wire lsu_i_store   = lsu_i_info [`QPU_DECINFO_LSU_STORE  ];


  wire lsu_icb_cmd_hsked = lsu_icb_cmd_valid & lsu_icb_cmd_ready;          //load store icb不会把数据送回到lsu中！
  wire lsu_icb_rsp_hsked = 1'b0;



  wire lsu_i_ldst = (lsu_i_load | lsu_i_store);

  assign lsu_req_alu_op1 = lsu_i_rs1;
  assign lsu_req_alu_op2 = lsu_i_imm;
  
/////////////////////////////////////////////////////////////////////////////////
// Implement the LSU op handshake ready signal
//

  assign lsu_i_ready = (lsu_icb_cmd_ready & lsu_o_ready) ;
  
  // The aligned load/store instruction will be dispatched to LSU as long pipeline
  //   instructions
  

  //
  /////////////////////////////////////////////////////////////////////////////////
  // Implement the Write-back interfaces (unaligned and AMO instructions) 

  // The LSU write-back will be valid when:
  //   * For the aligned load/store
  //       Directly passed to ICB interface, but also need to pass 
  //       to write-back interface asking for commit
  assign lsu_o_valid = lsu_i_valid & lsu_i_ldst & lsu_icb_cmd_ready;


  assign lsu_icb_rsp_ready = 1'b1;
  assign lsu_icb_cmd_valid = ((lsu_i_ldst & lsu_i_valid) & (lsu_o_ready));


  assign lsu_icb_cmd_addr = lsu_req_alu_res[`QPU_ADDR_SIZE-1:0];

  assign lsu_icb_cmd_read = (lsu_i_ldst & lsu_i_load);
     // The LSU ICB CMD Wdata sources:
     //   * For the aligned store instructions
     //       Directly passed to LSU ICB, wdata is op2 repetitive form, 
     //       wmask is generated according to the LSB and size


  wire [`QPU_XLEN-1:0] algnst_wdata = lsu_i_rs2[`QPU_XLEN - 1 : 0];
  wire [`QPU_XLEN/8-1:0] algnst_wmask = 4'b1111;

          
  assign lsu_icb_cmd_wdata = algnst_wdata;
  assign lsu_icb_cmd_wmask = algnst_wmask; 

endmodule                                      
                                               
                                               
                                               
