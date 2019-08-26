


module QPU_core(

  input  [`QPU_PC_SIZE-1:0] pc_rtvec,
  output[`QPU_PC_SIZE-1:0] inspect_pc,

  input  tcm_cgstop,
  input  test_mode,

  output ifu_active,
  output exu_active,
  output lsu_active,
  output itcm_active,
  output dtcm_active,

  output clk_itcm_ram,
  output clk_dtcm_ram,


  input  i_trigger,
  input [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement,
  input mcu_i_wen,
  output trigger_o_clk_ena,
  input  [`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk,
  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] trigger_o_data,
  output [`QPU_EVENT_NUM - 1: 0] trigger_o_valid,


  input  clk,
  input  rst_n
);


//////////////ifu--exu////////////////////////
  wire i_valid;
  wire i_ready;

  wire  [`QPU_INSTR_SIZE-1:0] i_ir;
  wire  [`QPU_PC_SIZE-1:0] i_pc;
  wire  i_prdt_taken;

  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx;   
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx;

  wire   pipe_flush_ack;
  wire  pipe_flush_req;
  wire  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1;  
  wire  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2;
//////////////////////////////////////////////



/////////////////exu--lsu///////////////////

  wire  lsu_o_valid; 
  wire  lsu_o_ready; 
  wire  [`QPU_XLEN-1:0] lsu_o_wbck_rdata;

  wire                         lsu_icb_cmd_valid; 
  wire                         lsu_icb_cmd_ready; 
  wire [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr;
  wire                         lsu_icb_cmd_read;   
  wire [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata; 
  wire [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask; 

////////////////////////////////////////////



  QPU_ifu_top test_QPU_ifu_top(
    .pc_rtvec               (pc_rtvec),
    .inspect_pc             (inspect_pc),

    .tcm_cgstop             (tcm_cgstop),
    .ifu_active             (ifu_active),
    .itcm_active            (itcm_active),

    .itcm_nohold            (1'b0),

    .ifu_o_ir               (i_ir),
    .ifu_o_pc               (i_pc),
    .ifu_o_pc_vld           (),
    .ifu_o_rs1idx           (i_rs1idx),
    .ifu_o_rs2idx           (i_rs2idx),
    .ifu_o_prdt_taken       (i_prdt_taken),

    .ifu_o_valid            (i_valid),
    .ifu_o_ready            (i_ready),

    .pipe_flush_ack         (pipe_flush_ack),
    .pipe_flush_req         (pipe_flush_req),
    .pipe_flush_add_op1     (pipe_flush_add_op1),
    .pipe_flush_add_op2     (pipe_flush_add_op2),

    .ifu_halt_req           (1'b0),
    .ifu_halt_ack           (),

    .test_mode              (test_mode),
    .clk_itcm_ram           (clk_itcm_ram),

    .clk                    (clk),
    .rst_n                  (rst_n)
  );



  QPU_exu test_QPU_exu(
    .exu_active             (exu_active),
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



  QPU_lsu_top test_QPU_lsu_top(
    .dtcm_active           (dtcm_active),
    .lsu_active            (lsu_active),

    .tcm_cgstop            (tcm_cgstop),
    .test_mode             (test_mode),

    .lsu_o_valid           (lsu_o_valid),
    .lsu_o_ready           (lsu_o_ready),
    .lsu_o_wbck_rdata      (lsu_o_wbck_rdata),
    .lsu_o_cmt_ld          (),
    .lsu_o_cmt_st          (),
    .lsu_o_cmt_badaddr     (),

    .lsu_icb_cmd_valid     (lsu_icb_cmd_valid),
    .lsu_icb_cmd_ready     (lsu_icb_cmd_ready),
    .lsu_icb_cmd_addr      (lsu_icb_cmd_addr),
    .lsu_icb_cmd_read      (lsu_icb_cmd_read),
    .lsu_icb_cmd_wdata     (lsu_icb_cmd_wdata),
    .lsu_icb_cmd_wmask     (lsu_icb_cmd_wmask),

    .clk_dtcm_ram          (clk_dtcm_ram),
    .clk                   (clk),
    .rst_n                 (rst_n)
  );




endmodule
