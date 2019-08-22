`include "QPU_defines.v"

module tb_top(


//  input  i_trigger,
  //////////////////////////////////////////////////////////////
  input oitfrd_match_disprs1,
  input oitfrd_match_disprs2,
  input oitfrd_match_disprd,
  input oitfqf_match_dispql,
//  output oitfrd_match_disprs1,
//  output oitfrd_match_disprs2,
//  output oitfrd_match_disprd,
//  output oitfqf_match_dispql,
  output disp_oitf_qfren,
  output [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_qubitlist,
  
  output  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs1idx,
  output  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs2idx,
  output  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rdidx,
  output  disp_oitf_rs1en,
  output  disp_oitf_rs2en,
  output  disp_oitf_rdwen,
  input [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_ret_measurelist,
  output tiq_wbck_ena,
  input tiq_wbck_ready,
  output [`QPU_TIME_WIDTH - 1 : 0] tiq_wbck_data,
  
  output evq_wbck_ena,
  input evq_wbck_ready,
  
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_zero,
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_one,
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_equ,
  
  output [`QPU_EVENT_NUM - 1 : 0] erf_oprand,
  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] erf_data,
  input [`QPU_RFIDX_REAL_WIDTH - 1 : 0] oitf_ret_rdidx,
  input oitf_ret_rdwen,
  input disp_oitf_ready,
  input disp_moitf_ready,
  output disp_oitf_ena,
  output disp_moitf_ena,
  //////////////////////////////////////////////////////////////
  // The IFU IR stage to EXU interface
  input  i_valid, // Handshake signals with EXU stage
  output i_ready,
  input  [`QPU_INSTR_SIZE-1:0] i_ir,// The instruction register
  input  [`QPU_PC_SIZE-1:0] i_pc,   // The PC register along with

  input  i_prdt_taken,               
                 
//  input  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx,   // The RS1 index
//  input  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx,   // The RS2 index

  

  //////////////////////////////////////////////////////////////
  // The Flush interface to IFU
  //
  //   To save the gatecount, when we need to flush pipeline with new PC, 
  //     we want to reuse the adder in IFU, so we will not pass flush-PC
  //     to IFU, instead, we pass the flush-pc-adder-op1/op2 to IFU
  //     and IFU will just use its adder to caculate the flush-pc-adder-result
  //
  input   pipe_flush_ack,
  output  pipe_flush_req,
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2,  


  //////////////////////////////////////////////////////////////////
    // The LSU Write-Back Interface
  input  lsu_o_valid, // Handshake valid
  output lsu_o_ready, // Handshake ready
  input  [`QPU_XLEN-1:0] lsu_o_wbck_data,


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The AGU ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  output                         lsu_icb_cmd_valid, // Handshake valid
  input                          lsu_icb_cmd_ready, // Handshake ready
  output [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr, // Bus transaction start addr 
  output                         lsu_icb_cmd_read,   // Read or write
  output [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata, 
  output [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask, 

  //    * Bus RSP channel
  //input                          lsu_icb_rsp_valid, // Response valid 
  //output                         lsu_icb_rsp_ready, // Response ready
  //input  [`QPU_XLEN-1:0]         lsu_icb_rsp_rdata,
  //////////////////////////////////////////////////////////////////
  ///data from MCU
  input [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement,
  input mcu_i_wen,
  ///////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////
  ///data to trigger
//  output trigger_o_clk_ena,
//  input  [`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk,
//  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] trigger_o_data,
//  output [`QPU_EVENT_NUM - 1: 0] trigger_o_valid,

  input  clk,
  input  rst_n
  );
  
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx; 
  wire  [`QPU_INSTR_SIZE-1:0] qout;

  QPU_exu test_QPU_exu(
    
    
  .oitfrd_match_disprs1   (oitfrd_match_disprs1),
  .oitfrd_match_disprs2   (oitfrd_match_disprs2),
  .oitfrd_match_disprd   (oitfrd_match_disprd),
  .oitfqf_match_dispql   (oitfqf_match_dispql),
//  .oitfrd_match_disprs1   (),
//  .oitfrd_match_disprs2   (),
//  .oitfrd_match_disprd   (),
//  .oitfqf_match_dispql   (),
  .disp_oitf_qfren   (disp_oitf_qfren),
  .disp_oitf_qubitlist   (disp_oitf_qubitlist),
  
  .disp_oitf_rs1idx   (disp_oitf_rs1idx),
  .disp_oitf_rs2idx   (disp_oitf_rs2idx),
  .disp_oitf_rdidx   (disp_oitf_rdidx),
  .disp_oitf_rs1en   (disp_oitf_rs1en),
  .disp_oitf_rs2en   (disp_oitf_rs2en),
  .disp_oitf_rdwen   (disp_oitf_rdwen),
  .disp_oitf_ret_measurelist   (disp_oitf_ret_measurelist),
  .tiq_wbck_ena   (tiq_wbck_ena),
  .tiq_wbck_ready   (tiq_wbck_ready),
  .tiq_wbck_data   (tiq_wbck_data),
  
  .evq_wbck_ena   (evq_wbck_ena),
  .evq_wbck_ready   (evq_wbck_ready),
  
  .qubit_measure_zero   (qubit_measure_zero),
  .qubit_measure_one   (qubit_measure_one),
  .qubit_measure_equ   (qubit_measure_equ),
  
  .erf_oprand   (erf_oprand),
  .erf_data   (erf_data),
  .oitf_ret_rdidx   (oitf_ret_rdidx),
  .oitf_ret_rdwen   (oitf_ret_rdwen),
  .disp_oitf_ready   (disp_oitf_ready),
  .disp_moitf_ready   (disp_moitf_ready),
  .disp_oitf_ena   (disp_oitf_ena),
  .disp_moitf_ena   (disp_moitf_ena),
  //////////////////////////////////////////////////////////////
  // The IFU IR stage to EXU interface
  .i_valid   (i_valid), // Handshake signals with EXU stage
  .i_ready   (i_ready),
  .i_ir   (qout),// The instruction register
  .i_pc   (i_pc),   // The PC register along with

  .i_prdt_taken   (i_prdt_taken),               
                 
  .i_rs1idx   (i_rs1idx),   // The RS1 index
  .i_rs2idx   (i_rs2idx),   // The RS2 index

  

  //////////////////////////////////////////////////////////////
  // The Flush interface to IFU
  //
  //   To save the gatecount   (), when we need to flush pipeline with new PC   (), 
  //     we want to reuse the adder in IFU   (), so we will not pass flush-PC
  //     to IFU   (), instead   (), we pass the flush-pc-adder-op1/op2 to IFU
  //     and IFU will just use its adder to caculate the flush-pc-adder-result
  //
  .pipe_flush_ack   (pipe_flush_ack),
  .pipe_flush_req   (pipe_flush_req),
  .pipe_flush_add_op1   (pipe_flush_add_op1),  
  .pipe_flush_add_op2   (pipe_flush_add_op2),  


  //////////////////////////////////////////////////////////////////
    // The LSU Write-Back Interface
  .lsu_o_valid   (lsu_o_valid), // Handshake valid
  .lsu_o_ready   (lsu_o_ready), // Handshake ready
  .lsu_o_wbck_data   (lsu_o_wbck_data),


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The AGU ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  .lsu_icb_cmd_valid   (lsu_icb_cmd_valid), // Handshake valid
  .lsu_icb_cmd_ready   (lsu_icb_cmd_ready), // Handshake ready
  .lsu_icb_cmd_addr   (lsu_icb_cmd_addr), // Bus transaction start addr 
  .lsu_icb_cmd_read   (lsu_icb_cmd_read),   // Read or write
  .lsu_icb_cmd_wdata   (lsu_icb_cmd_wdata), 
  .lsu_icb_cmd_wmask   (lsu_icb_cmd_wmask), 

  //    * Bus RSP channel
  //.lsu_icb_rsp_valid   (lsu_icb_rsp_valid), // Response valid 
  //.lsu_icb_rsp_ready   (lsu_icb_rsp_ready), // Response ready
  //.lsu_icb_rsp_rdata   (lsu_icb_rsp_rdata),
  //////////////////////////////////////////////////////////////////
  ///data from MCU
  .mcu_i_measurement   (mcu_i_measurement),
  .mcu_i_wen   (mcu_i_wen),
  ///////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////
  ///data to trigger
//  .trigger_o_clk_ena   (),
//  .[`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk   (),
//  .[`QPU_EVENT_WIRE_WIDTH - 1 : 0] trigger_o_data   (),
//  .[`QPU_EVENT_NUM - 1: 0] trigger_o_valid   (),

  .clk   (clk),
  .rst_n (rst_n) 

  );

  QPU_ifu_minidec test_QPU_ifu_minidec(
    .instr                  (qout),

    .dec_rs1en              (),
    .dec_rs2en              (),
    .dec_rs1idx             (i_rs1idx),
    .dec_rs2idx             (i_rs2idx),

    .dec_bxx                (),
    .dec_bjp_imm            ()
  );


sirv_gnrl_dffl reg1(
    .dnxt		    (i_ir),
    .lden  	       	    (1'b1),
    .clk                    (clk),
//    .rst_n                  (1'b1),
    .qout		    (qout)

  );

endmodule

