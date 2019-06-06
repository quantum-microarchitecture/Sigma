//=====================================================================
//
// Designer   : HL
//
// Description:
//  This module to implement the AGU (address generation unit for load/store ),
//  which is mostly share the datapath with ALU module
//  to save gatecount to mininum
//
//
// ====================================================================

`include "QPU_defines.v"

module qpu_exu_alu_lsuagu(

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Issue Handshake Interface to AGU 
  //
  input  agu_i_valid, // Handshake valid
  output agu_i_ready, // Handshake ready

  input  [`QPU_XLEN-1:0] agu_i_rs1,
  input  [`QPU_XLEN-1:0] agu_i_rs2,
  input  [`QPU_DECINFO_LSU_WIDTH-1:0] agu_i_info,
  input  [`QPU_ITAG_WIDTH-1:0] agu_i_itag,

  output agu_i_longpipe,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  output                       agu_icb_cmd_valid, // Handshake valid
  input                        agu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [`QPU_ADDR_SIZE-1:0] agu_icb_cmd_addr, // Bus transaction start addr 
  output                       agu_icb_cmd_read,   // Read or write
  output [`QPU_XLEN-1:0]      agu_icb_cmd_wdata, 
  output [`QPU_XLEN/8-1:0]    agu_icb_cmd_wmask, 
  output [`QPU_ITAG_WIDTH-1:0] agu_icb_cmd_itag
  );

  wire       agu_i_load    = agu_i_info [`QPU_DECINFO_LSU_LOAD   ];
  wire       agu_i_store   = agu_i_info [`QPU_DECINFO_LSU_STORE  ];

  assign agu_i_ready = agu_icb_cmd_ready;

  // The aligned load/store instruction will be dispatched to LSU as long pipeline
  //   instructions
  assign agu_i_algnldst = agu_i_load | agu_i_store ;

  assign agu_i_longpipe = agu_i_algnldst;

  assign agu_icb_cmd_valid = agu_i_algnldst & agu_i_valid;

  assign agu_icb_cmd_addr =  agu_i_rs1[`QPU_ADDR_SIZE-1:0];
  assign agu_icb_cmd_read = agu_i_load ;
  assign agu_icb_cmd_wdata = agu_i_rs2[31:0];
  assign agu_icb_cmd_wmask = 4'b1111;
  assign agu_icb_cmd_itag     = agu_i_itag;


endmodule
















































