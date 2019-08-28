

module QPU_ifu_top(
  input  [`QPU_PC_SIZE-1:0] pc_rtvec,
  output[`QPU_PC_SIZE-1:0] inspect_pc,

  input  tcm_cgstop,
  output ifu_active,
  output itcm_active,

  input  itcm_nohold,


  // The IR stage to EXU interface
  output [`QPU_INSTR_SIZE-1:0] ifu_o_ir,// The instruction register
  output [`QPU_PC_SIZE-1:0] ifu_o_pc,   // The PC register along with
  output ifu_o_pc_vld,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] ifu_o_rs1idx,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] ifu_o_rs2idx,
  output ifu_o_prdt_taken,               // The Bxx is predicted as taken

  output ifu_o_valid, // Handshake signals with EXU stage
  input  ifu_o_ready,

  output  pipe_flush_ack,
  input   pipe_flush_req,
  input   [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  input   [`QPU_PC_SIZE-1:0] pipe_flush_add_op2,

  input  ifu_halt_req,
  output ifu_halt_ack,

  input  test_mode,
  output clk_itcm_ram,

  input  clk,
  input  rst_n
);
  



  wire  ifu_icb_cmd_valid;
  wire  ifu_icb_cmd_ready;
  wire  [`QPU_ITCM_ADDR_WIDTH-1:0]   ifu_icb_cmd_addr;  

  wire  ifu_icb_cmd_read = 1'b1;
  wire  [`QPU_ITCM_DATA_WIDTH-1:0] ifu_icb_cmd_wdata = `QPU_ITCM_DATA_WIDTH'b0;
  wire  [`QPU_ITCM_WMSK_WIDTH-1:0] ifu_icb_cmd_wmask = `QPU_ITCM_WMSK_WIDTH'b11111111;

  wire  ifu_icb_rsp_valid; 
  wire  ifu_icb_rsp_ready;
  wire  [`QPU_ITCM_DATA_WIDTH-1:0] ifu_icb_rsp_rdata; 

  wire  ifu_holdup;

  wire  itcm_ram_sd = 1'b0;
  wire  itcm_ram_ds = 1'b0;
  wire  itcm_ram_ls = 1'b0;

  wire                         itcm_ram_cs;  
  wire                         itcm_ram_we;  
  wire  [`QPU_ITCM_RAM_AW-1:0] itcm_ram_addr; 
  wire  [`QPU_ITCM_RAM_MW-1:0] itcm_ram_wem;
  wire  [`QPU_ITCM_RAM_DW-1:0] itcm_ram_din;          
  wire  [`QPU_ITCM_RAM_DW-1:0] itcm_ram_dout;




  QPU_ifu test_QPU_ifu(
    .inspect_pc             (inspect_pc),
    .ifu_active             (ifu_active),
    .itcm_nohold            (itcm_nohold),

    .pc_rtvec               (pc_rtvec),
    .ifu_holdup             (ifu_holdup),
 
    .ifu_icb_cmd_valid      (ifu_icb_cmd_valid),
    .ifu_icb_cmd_ready      (ifu_icb_cmd_ready),
    .ifu_icb_cmd_addr       (ifu_icb_cmd_addr),
    .ifu_icb_rsp_valid      (ifu_icb_rsp_valid),
    .ifu_icb_rsp_ready      (ifu_icb_rsp_ready),   
    .ifu_icb_rsp_rdata      (ifu_icb_rsp_rdata),

    .ifu_o_ir               (ifu_o_ir),
    .ifu_o_pc               (ifu_o_pc),
    .ifu_o_pc_vld           (ifu_o_pc_vld),
    .ifu_o_rs1idx           (ifu_o_rs1idx),
    .ifu_o_rs2idx           (ifu_o_rs2idx),
    .ifu_o_prdt_taken       (ifu_o_prdt_taken),

    .ifu_o_valid            (ifu_o_valid),
    .ifu_o_ready            (ifu_o_ready),

    .pipe_flush_ack         (pipe_flush_ack),
    .pipe_flush_req         (pipe_flush_req),
    .pipe_flush_add_op1     (pipe_flush_add_op1),
    .pipe_flush_add_op2     (pipe_flush_add_op2),

    .ifu_halt_req           (ifu_halt_req),
    .ifu_halt_ack           (ifu_halt_ack),

    .clk                    (clk),
    .rst_n                  (rst_n)
  );


  QPU_itcm_ctrl test_QPU_itcm_ctrl(
    .itcm_active            (itcm_active),
    .tcm_cgstop             (tcm_cgstop),

    .ifu_icb_cmd_valid      (ifu_icb_cmd_valid),
    .ifu_icb_cmd_ready      (ifu_icb_cmd_ready),
    .ifu_icb_cmd_addr       (ifu_icb_cmd_addr),
    .ifu_icb_cmd_read       (ifu_icb_cmd_read),
    .ifu_icb_cmd_wdata      (ifu_icb_cmd_wdata),
    .ifu_icb_cmd_wmask      (ifu_icb_cmd_wmask),

    .ifu_icb_rsp_valid      (ifu_icb_rsp_valid),
    .ifu_icb_rsp_ready      (ifu_icb_rsp_ready),
    .ifu_icb_rsp_rdata      (ifu_icb_rsp_rdata),

    .ifu_holdup             (ifu_holdup),

    .itcm_ram_cs            (itcm_ram_cs),
    .itcm_ram_we            (itcm_ram_we),
    .itcm_ram_addr          (itcm_ram_addr),
    .itcm_ram_wem           (itcm_ram_wem),
    .itcm_ram_din           (itcm_ram_din),
    .itcm_ram_dout          (itcm_ram_dout),
    .clk_itcm_ram           (clk_itcm_ram),

    .test_mode              (test_mode),
    .clk                    (clk),
    .rst_n                  (rst_n)

  );

  QPU_itcm_ram test_QPU_itcm_ram(
    .sd                     (itcm_ram_sd),
    .ds                     (itcm_ram_ds),
    .ls                     (itcm_ram_ls),

    .cs                     (itcm_ram_cs),
    .we                     (itcm_ram_we),
    .addr                   (itcm_ram_addr),
    .wem                    (itcm_ram_wem),
    .din                    (itcm_ram_din),
    .dout                   (itcm_ram_dout),

    .rst_n                  (rst_n),
    .clk                    (clk)

  );




endmodule






