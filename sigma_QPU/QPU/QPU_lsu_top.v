

module QPU_lsu_top(
  output  dtcm_active,
  output  lsu_active,

  input   tcm_cgstop,
  input   test_mode,
  
  // The LSU Write-Back Interface
  output  lsu_o_valid, 
  input   lsu_o_ready, 
  output  [`QPU_XLEN-1:0] lsu_o_wbck_rdata,

  output lsu_o_cmt_ld,
  output lsu_o_cmt_st,
  output [`QPU_ADDR_SIZE -1:0] lsu_o_cmt_badaddr,

  // The lsu ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  input                         lsu_icb_cmd_valid, 
  output                        lsu_icb_cmd_ready,
  input [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr,
  input                         lsu_icb_cmd_read,   
  input [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata, 
  input [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask,

  output clk_dtcm_ram,

  input clk,
  input rst_n

);

///////////////////////////lsu/////////////////////////////

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

