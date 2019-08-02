`include "../QPU/QPU_defines.v"
`include "tb_define.v"

`timescale 10ns/10ps

module tb_exu();

  parameter clk_period = 2;


/////////////////////////////exu/////////////////////////////////
  wire exu_active;
  reg  i_trigger;
  //////////////////////////////////////////////////////////////
  // The IFU IR stage to EXU interface
  reg  i_valid; 
  wire i_ready;
  reg  [`QPU_INSTR_SIZE-1:0] i_ir;
  reg  [`QPU_PC_SIZE-1:0] i_pc;  

  reg  i_prdt_taken;               
                 
  reg  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx;   
  reg  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx;   
  //////////////////////////////////////////////////////////////
  reg   pipe_flush_ack;
  wire  pipe_flush_req;
  wire  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1;  
  wire  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2; 
  //////////////////////////////////////////////////////////////
  // The LSU Write-Back Interface
  wire  lsu_o_valid; 
  wire lsu_o_ready; 
  wire  [`QPU_XLEN-1:0] lsu_o_wbck_rdata;
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The lsu ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  wire                         lsu_icb_cmd_valid; 
  wire                         lsu_icb_cmd_ready; 
  wire [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr;
  wire                         lsu_icb_cmd_read;   
  wire [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata; 
  wire [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask; 

  //////////////////////////////////////////////////////////////////
  ///data from MCU
  reg [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement;
  reg mcu_i_wen;
  /////////////////////////////////////////////////////////////////
  ///data to trigger
  wire trigger_o_clk_ena;
  reg  [`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] trigger_o_data;
  wire [`QPU_EVENT_NUM - 1: 0] trigger_o_valid;

  reg  clk;
  reg  rst_n;

/////////////////////////////////////////////////////////////


///////////////////////////lsu/////////////////////////////
  wire  lsu_active;

  wire lsu_o_cmt_ld;
  wire lsu_o_cmt_st;
  wire [`QPU_ADDR_SIZE -1:0] lsu_o_cmt_badaddr;

  wire                         dtcm_icb_cmd_valid;
  wire                          dtcm_icb_cmd_ready;
  wire [`QPU_DTCM_ADDR_WIDTH-1:0]   dtcm_icb_cmd_addr; 
  wire                         dtcm_icb_cmd_read; 
  wire [`QPU_XLEN-1:0]        dtcm_icb_cmd_wdata;
  wire [`QPU_XLEN/8-1:0]      dtcm_icb_cmd_wmask;

  //    * Bus RSP channel
  wire                          dtcm_icb_rsp_valid;
  wire                         dtcm_icb_rsp_ready;
  wire  [`QPU_XLEN-1:0]        dtcm_icb_rsp_rdata;

  //////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

///////////////////////////dtcm////////////////////////////////
  wire dtcm_active;
  reg  tcm_cgstop;
  reg  test_mode;

  wire clk_dtcm_ram;

  wire dtcm_ram_sd = 1'b0;
  wire dtcm_ram_ds = 1'b0;
  wire dtcm_ram_ls = 1'b0;

  wire dtcm_ram_cs;
  wire dtcm_ram_we;
  wire [`QPU_DTCM_RAM_AW-1:0] dtcm_ram_addr;
  wire [`QPU_DTCM_RAM_MW-1:0] dtcm_ram_wem;
  wire [`QPU_DTCM_RAM_DW-1:0] dtcm_ram_din;
  wire [`QPU_DTCM_RAM_DW-1:0] dtcm_ram_dout;

/////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////

  initial
  begin
    i_trigger = 1'b0;
    
    i_valid = 1'b1;

    pipe_flush_ack = 1'b1;

    mcu_i_measurement = `QPU_QUBIT_NUM'b0;
    mcu_i_wen = 1'b1;
    trigger_i_clk = `QPU_TIME_WIDTH'b0;

    tcm_cgstop = 1'b0;
    test_mode = 1'b0;

    clk = 1'b1;
    rst_n = 1'b0;
    #3 rst_n = 1'b1;
  end

  always #(clk_period/2) clk = ~clk;
  
///////////////////////////////////////////////////////////



////////////////////////////instr//////////////////////////////////
  initial
  begin
    #0 i_ir = 32'b0;
    #0 i_pc = `QPU_PC_SIZE'b0;
    #0 i_prdt_taken = 1'b0;

    #2 i_ir = `SMIS_S14_010100;                         //1
    #2 i_ir = `SMIS_S15_101000;                         //2
    #2 i_ir = `SMIS_S16_100100;                         //3  
    #2 i_ir = `SMIS_S17_001100;                         //4
    #2 i_ir = `T0_H_S14_X90_S15;                        //5
    #2 i_ir = `T1_Y90_S2_X90_S3;                        //6
    #2 i_ir = `T2_Y90_S16_GATE0_S0;                     //7
    #2 i_ir = `T3_ZGATE0_XYGATE1;                       //8
    #2 i_ir = `T4_ZGATE1_X90_S3;                        //9
    #2 i_ir = `T5_ZGATE2_GATE0_S0;                      //10


    #2 i_ir = `T1_MEASURE_S17;                         //11
    #2 i_ir = `QWAIT_30;                               //12    
    #2 i_ir = `ADDI_R1_R0_001100;                      //13
    #2 i_ir = `FMR_R2_S17;                             //14
    #2 i_ir = `BEQ_R1_R2_CASE2;                        //15  
    #2 i_ir = `T0_X90_S2;                              //16
    #2 i_ir = `QWAIT_1;                                //17
    #2 i_ir = `BEQ_R0_R0_NEXT;                         //18  
    #2 i_ir = `T0_H_S2;                                //19    
    #2 i_ir = `QWAIT_1;                                //20
    #2 i_ir = `T0_MEASURE_S2;                          //21  
    #2 i_ir = `QWAIT_30;                               //22

    #2 i_ir = `instr_STORE;
    #2 i_ir = `instr_LOAD;
  end
////////////////////////////////////////////////////////////////////


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


  QPU_lsu test_QPU_lsu(
    .lsu_active             (lsu_active),

    .lsu_o_valid            (lsu_o_valid),
    .lsu_o_ready            (lsu_o_ready),
    .lsu_o_wbck_wdat        (lsu_o_wbck_rdata),
    .lsu_o_cmt_ld           (lsu_o_cmt_ld),
    .lsu_o_cmt_st           (lsu_o_cmt_st),
    .lsu_o_cmt_badaddr      (lsu_o_cmt_badaddr),

    .lsu_icb_cmd_valid      (lsu_icb_cmd_valid),
    .lsu_icb_cmd_ready      (lsu_icb_cmd_ready),
    .lsu_icb_cmd_addr       (lsu_icb_cmd_addr),
    .lsu_icb_cmd_read       (lsu_icb_cmd_read),
    .lsu_icb_cmd_wdata      (lsu_icb_cmd_wdata),
    .lsu_icb_cmd_wmask      (lsu_icb_cmd_wmask),

    .dtcm_icb_cmd_valid     (dtcm_icb_cmd_valid),
    .dtcm_icb_cmd_ready     (dtcm_icb_cmd_ready),
    .dtcm_icb_cmd_addr      (dtcm_icb_cmd_addr),
    .dtcm_icb_cmd_read      (dtcm_icb_cmd_read),
    .dtcm_icb_cmd_wdata     (dtcm_icb_cmd_wdata),
    .dtcm_icb_cmd_wmask     (dtcm_icb_cmd_wmask),

    .dtcm_icb_rsp_valid     (dtcm_icb_rsp_valid),
    .dtcm_icb_rsp_ready     (dtcm_icb_rsp_ready),
    .dtcm_icb_rsp_rdata     (dtcm_icb_rsp_rdata),

    .clk                    (clk),
    .rst_n                  (rst_n)

  );

  QPU_dtcm_ctrl test_QPU_dtcm_ctrl(
    .dtcm_active            (dtcm_active),
    .tcm_cgstop             (tcm_cgstop),

    .lsu_icb_cmd_valid      (dtcm_icb_cmd_valid),
    .lsu_icb_cmd_ready      (dtcm_icb_cmd_ready),
    .lsu_icb_cmd_addr       (dtcm_icb_cmd_addr),
    .lsu_icb_cmd_read       (dtcm_icb_cmd_read),
    .lsu_icb_cmd_wdata      (dtcm_icb_cmd_wdata),
    .lsu_icb_cmd_wmask      (dtcm_icb_cmd_wmask),

    .lsu_icb_rsp_valid      (dtcm_icb_rsp_valid),
    .lsu_icb_rsp_ready      (dtcm_icb_rsp_ready),
    .lsu_icb_rsp_rdata      (dtcm_icb_rsp_rdata),

    .dtcm_ram_cs            (dtcm_ram_cs),
    .dtcm_ram_we            (dtcm_ram_we),
    .dtcm_ram_addr          (dtcm_ram_addr),
    .dtcm_ram_wem           (dtcm_ram_wem),
    .dtcm_ram_din           (dtcm_ram_din),
    .dtcm_ram_dout          (dtcm_ram_dout),
    .clk_dtcm_ram           (clk_dtcm_ram),

    .test_mode              (test_mode),
    .clk                    (clk),
    .rst_n                  (rst_n)
  );

  QPU_dtcm_ram test_QPU_dtcm_ram (
    .sd   (dtcm_ram_sd),
    .ds   (dtcm_ram_ds),
    .ls   (dtcm_ram_ls),
  
    .cs   (dtcm_ram_cs   ),
    .we   (dtcm_ram_we   ),
    .addr (dtcm_ram_addr ),
    .wem  (dtcm_ram_wem  ),
    .din  (dtcm_ram_din  ),
    .dout (dtcm_ram_dout ),
    .rst_n(rst_n      ),
    .clk  (clk  )
    );


endmodule