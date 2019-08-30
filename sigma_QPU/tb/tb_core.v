

`include "../QPU/QPU_defines.v"
`include "../tb/tb_define.v"

`timescale 10ns/10ps

module tb_all();

  parameter clk_period = 2;

  wire  [`QPU_PC_SIZE-1:0] pc_rtvec = `QPU_PC_SIZE'b0;
  wire  tcm_cgstop = 1'b0;
  wire  test_mode = 1'b0;

  wire [`QPU_PC_SIZE-1:0] inspect_pc;
  wire ifu_active;
  wire exu_active;
  wire lsu_active;
  wire itcm_active;
  wire dtcm_active;

  wire clk_itcm_ram;
  wire clk_dtcm_ram;

  wire  i_trigger = 1'b0;
  wire [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement = `QPU_QUBIT_NUM'b0;
  wire mcu_i_wen = 1'b1;
  wire trigger_o_clk_ena;
  wire  [`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk = `QPU_TIME_WIDTH'b0;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] trigger_o_data;
  wire [`QPU_EVENT_NUM - 1: 0] trigger_o_valid;


  reg  clk;
  reg  rst_n;


  initial
  begin
    clk = 1'b1;
    rst_n = 1'b0;
    #3 rst_n = 1'b1;
    #43 rst_n = 1'b0;
    #3 rst_n = 1'b1;
  end

  always #(clk_period/2) clk = ~clk;


  QPU_core test_QPU_core(
    .pc_rtvec                  (pc_rtvec),
    .inspect_pc                (inspect_pc),

    .tcm_cgstop                (tcm_cgstop),
    .test_mode                 (test_mode),

    .ifu_active                (ifu_active),
    .exu_active                (exu_active),
    .lsu_active                (lsu_active),
    .itcm_active               (itcm_active),
    .dtcm_active               (dtcm_active),

    .clk_itcm_ram              (clk_itcm_ram),
    .clk_dtcm_ram              (clk_dtcm_ram),

    .i_trigger                 (i_trigger),
    .mcu_i_measurement         (mcu_i_measurement),
    .mcu_i_wen                 (mcu_i_wen),
    .trigger_o_clk_ena         (trigger_o_clk_ena),
    .trigger_i_clk             (trigger_i_clk),
    .trigger_o_data            (trigger_o_data),
    .trigger_o_valid           (trigger_o_valid),

    .clk                       (clk),
    .rst_n                     (rst_n)
  );



endmodule









