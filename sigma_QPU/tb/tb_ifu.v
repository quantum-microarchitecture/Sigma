`include "../QPU/QPU_defines.v"
`include "../tb/tb_define.v"

`timescale 10ns/10ps

module tb_ifu();
  
  parameter clk_period = 2;

  wire  [`QPU_PC_SIZE-1:0] pc_rtvec = `QPU_PC_SIZE'b0;
  wire  [`QPU_PC_SIZE-1:0] inspect_pc;

  wire  tcm_cgstop = 1'b0;
  wire ifu_active;
  wire itcm_active;

  wire  itcm_nohold = 1'b0;


  // The IR stage to EXU interface
  wire [`QPU_INSTR_SIZE-1:0] ifu_o_ir;// The instruction register
  wire [`QPU_PC_SIZE-1:0] ifu_o_pc;   // The PC register along with
  wire ifu_o_pc_vld;
  wire [`QPU_RFIDX_WIDTH-1:0] ifu_o_rs1idx;
  wire [`QPU_RFIDX_WIDTH-1:0] ifu_o_rs2idx;
  wire ifu_o_prdt_taken;               // The Bxx is predicted as taken

  wire ifu_o_valid; // Handshake signals with EXU stage
  reg  ifu_o_ready;

  wire  pipe_flush_ack;
  wire   pipe_flush_req = 1'b0;
  wire   [`QPU_PC_SIZE-1:0] pipe_flush_add_op1 = `QPU_PC_SIZE'b0;  
  wire   [`QPU_PC_SIZE-1:0] pipe_flush_add_op2 = `QPU_PC_SIZE'b0;

  wire  ifu_halt_req = 1'b0;
  wire ifu_halt_ack;

  wire  test_mode = 1'b0;
  wire clk_itcm_ram;

  reg  clk;
  reg  rst_n;  


  initial
  begin
    
    ifu_o_ready = 1'b0;
    clk = 1'b1;
    rst_n = 1'b0;
    #1 rst_n = 1'b1;
    #1 ifu_o_ready = 1'b1;

  end

  always #(clk_period/2) clk = ~clk;

  QPU_ifu_top test_QPU_ifu_top(
    .pc_rtvec               (pc_rtvec),
    .inspect_pc             (inspect_pc),

    .tcm_cgstop             (tcm_cgstop),
    .ifu_active             (ifu_active),
    .itcm_active            (itcm_active),

    .itcm_nohold            (itcm_nohold),

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

    .test_mode              (test_mode),
    .clk_itcm_ram           (clk_itcm_ram),

    .clk                    (clk),
    .rst_n                  (rst_n)
  );

endmodule
















