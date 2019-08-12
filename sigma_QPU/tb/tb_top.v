`include "../QPU/QPU_defines.v"
`include "tb_define.v"

module tb_top(

  output exu_active,
  input  i_trigger,
  //////////////////////////////////////////////////////////////
  // The IFU IR stage to EXU interface
  input  i_valid, 
  output i_ready,
  input  [`QPU_INSTR_SIZE-1:0] i_ir,
  input  [`QPU_PC_SIZE-1:0] i_pc,  

  input  i_prdt_taken,               
                  
  //////////////////////////////////////////////////////////////
  input   pipe_flush_ack,
  output  pipe_flush_req,
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2, 
  //////////////////////////////////////////////////////////////
  // The LSU Write-Back Interface
  input  lsu_o_valid, 
  output lsu_o_ready, 
  input  [`QPU_XLEN-1:0] lsu_o_wbck_rdata,
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The lsu ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  output                         lsu_icb_cmd_valid, 
  input                         lsu_icb_cmd_ready, 
  output [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr,
  output                         lsu_icb_cmd_read,   
  output [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata, 
  output [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask, 

  //////////////////////////////////////////////////////////////////
  ///data from MCU
  input [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement,
  input mcu_i_wen,
  /////////////////////////////////////////////////////////////////
  ///data to trigger
  output trigger_o_clk_ena,
  input  [`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk,
  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] trigger_o_data,
  output [`QPU_EVENT_NUM - 1: 0] trigger_o_valid,

  input  clk,
  input  rst_n
);
  
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx; 

  QPU_exu test_QPU_exu(
    .exu_active            (exu_active),
    .i_trigger              (i_trigger),
    
    .i_valid                (i_valid),
    .i_ready                (i_ready),
    .i_ir                   (i_ir),
    .i_pc                   (i_pc),

    .i_prdt_taken           (i_prdt_taken),

    .i_rs1idx               (i_rs1idx),
    .i_rs2idx               (i_rs2idx),

    .pipe_flush_ack         (pipe_flush_ack),
    .pipe_flush_req         (pipe_flush_req),
    .pipe_flush_add_op1     (pipe_flush_add_op1),
    .pipe_flush_add_op2     (pipe_flush_add_op2),

    .lsu_o_valid            (lsu_o_valid),
    .lsu_o_ready            (lsu_o_ready),
    .lsu_o_wbck_data        (lsu_o_wbck_rdata),

    .lsu_icb_cmd_valid      (lsu_icb_cmd_valid),
    .lsu_icb_cmd_ready      (lsu_icb_cmd_ready),
    .lsu_icb_cmd_addr       (lsu_icb_cmd_addr),
    .lsu_icb_cmd_read       (lsu_icb_cmd_read),
    .lsu_icb_cmd_wdata      (lsu_icb_cmd_wdata),
    .lsu_icb_cmd_wmask      (lsu_icb_cmd_wmask),

    .lsu_icb_rsp_valid      (),
    .lsu_icb_rsp_ready      (),
    .lsu_icb_rsp_rdata      (),

    .mcu_i_measurement      (mcu_i_measurement),
    .mcu_i_wen              (mcu_i_wen),

    .trigger_o_clk_ena      (trigger_o_clk_ena),
    .trigger_i_clk          (trigger_i_clk),
    .trigger_o_data         (trigger_o_data),
    .trigger_o_valid        (trigger_o_valid ),

    .clk                    (clk),
    .rst_n                  (rst_n )

  );

  QPU_ifu_minidec test_QPU_ifu_minidec(
    .instr                  (i_ir),

    .dec_rs1en              (),
    .dec_rs2en              (),
    .dec_rs1idx             (i_rs1idx),
    .dec_rs2idx             (i_rs2idx),

    .dec_bxx                (),
    .dec_bjp_imm            ()
  );




endmodule

