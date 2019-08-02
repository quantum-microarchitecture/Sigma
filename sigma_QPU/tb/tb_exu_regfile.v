`include "../QPU/QPU_defines.v"
`include "tb_define.v"

`timescale 10ns/10ps

module tb_exu_regfile();

  parameter clk_period = 2;


////////////////////////////////////////////
//////////////////////////////////////////////////////////////
////////////////decode///////////////////
  // The IR stage to Decoder
  reg  [`QPU_INSTR_SIZE-1:0] i_instr;
  reg  [`QPU_PC_SIZE-1:0] i_pc;
  reg  i_prdt_taken; 
  // The Decoded Info-Bus

  wire dec_rs1x0;
  wire dec_rs2x0;
  wire dec_rs1en;
  wire dec_rs2en;
  wire dec_rdwen;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rdidx;
  wire [`QPU_DECINFO_WIDTH-1:0] dec_info;
  wire [`QPU_XLEN-1:0] dec_imm;
  wire [`QPU_PC_SIZE-1:0] dec_pc;  
  
  //Quantum instruction decode
  wire dec_ntp;
  wire dec_nqf;
  wire dec_measure;
  wire dec_fmr;
  //Branch instruction decode
  wire dec_bxx;
  wire [`QPU_XLEN-1:0] dec_bjp_imm;
//////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////  

/////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////disp////////////////////////////////////
    // The operands and decode info from dispatch
  reg  i_valid; // Handshake valid with IFU
  wire i_ready; // Handshake ready with IFU


  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx;


  // Dispatch to ALU

  wire disp_alu_valid; 


  wire [`QPU_XLEN-1:0] disp_alu_rs1;
  wire [`QPU_XLEN-1:0] disp_alu_rs2;
  wire disp_alu_rdwen;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_alu_rdidx;
  wire [`QPU_DECINFO_WIDTH-1:0]  disp_alu_info;  
  wire [`QPU_XLEN-1:0] disp_alu_imm;
  wire [`QPU_PC_SIZE-1:0] disp_alu_pc;            

  wire [`QPU_TIME_WIDTH - 1 : 0] disp_alu_clk;
  wire  disp_alu_qmr;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] disp_alu_edata;
  wire [`QPU_EVENT_NUM - 1 : 0] disp_alu_oprand;
        //Quantum instruction
  wire disp_alu_ntp;//
  wire disp_alu_fmr;
  wire disp_alu_measure;


  wire disp_oitf_ena;
  wire disp_moitf_ena;//measure instruction

  
  wire disp_oitf_rs1en ;
  wire disp_oitf_rs2en ;
  wire disp_oitf_rdwen ;

  wire disp_oitf_qfren ;//

  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs1idx;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs2idx;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rdidx ;

  wire [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_qubitlist;//
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////
///////////////////////////////////////////////
///////////////////////////alu//////////////
  wire disp_alu_ready; 

  wire disp_alu_longpipe; // Indicate this instruction is 
                     //   issued as a long pipe instruction
                     ///reg->disp->qiu

  // The Commit Interface
  wire alu_cmt_valid; // Handshake valid
  wire  alu_cmt_ready; // Handshake ready

  wire [`QPU_PC_SIZE-1:0] alu_cmt_pc;  
  wire [`QPU_XLEN-1:0]    alu_cmt_imm;// The resolved ture/false
    //   The Branch and Jump Commit

  wire alu_cmt_bjp;

  wire alu_cmt_bjp_prdt;// The predicted ture/false  
  wire alu_cmt_bjp_rslv;// The resolved ture/false


  // The ALU Write-Back Interface
  wire alu_cwbck_o_valid; // Handshake valid
  wire [`QPU_XLEN-1:0] alu_cwbck_o_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] alu_cwbck_o_rdidx;

  wire alu_qcwbck_o_valid;
  wire alu_qcwbck_o_ready;
  wire [`QPU_XLEN-1:0] alu_qcwbck_o_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] alu_qcwbck_o_rdidx;

  wire alu_twbck_o_valid;
  wire [`QPU_TIME_WIDTH - 1 : 0] alu_twbck_o_data;

  wire alu_ewbck_o_valid;
  wire [(`QPU_EVENT_WIRE_WIDTH - 1) : 0]  alu_ewbck_o_data;
  wire [(`QPU_EVENT_NUM - 1) : 0]        alu_ewbck_o_oprand;




/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
////////////////////////////oitf/////////////////////////
  //ready to accept new longpipe
  wire disp_oitf_ready;         //cf: classical fifo
  wire disp_moitf_ready;        //  mf : measurement fifo
 
   ///longwbck
  //remove signal

  ///remove signal
  //mcu
  wire  oitf_ret_ena;
  reg  moitf_ret_ena;

  //wbct info
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] oitf_ret_rdidx;
  wire oitf_ret_rdwen;

  //qbwbck info
  wire [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_ret_measurelist;      ///ret_measurement fifo
  
  //disp dep
  wire oitfrd_match_disprs1;
  wire oitfrd_match_disprs2;
  wire oitfrd_match_disprd;
  
  wire oitfqf_match_dispql;

  wire oitf_empty;
  wire moitf_empty;
  
  reg  clk;
  reg  rst_n;
/////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////



//////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///////////////////////////////wbck////////////////////
  // The ALU Write-Back Interface
  // for classical instr 
  wire alu_cwbck_o_ready; 

  //for qwait instr
  wire alu_twbck_o_ready;

  //for quantum instr
  wire alu_ewbck_o_ready;
 

  // The Longp Write-Back Interface
  // The Final arbitrated Write-Back Interface to Regfile
  wire  crf_wbck_ena;
  wire  [`QPU_XLEN-1:0] crf_wbck_data;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] crf_wbck_rdidx;

  wire  qcrf_wbck_ena;
  wire  [`QPU_XLEN-1:0] qcrf_wbck_data;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] qcrf_wbck_rdidx;

  wire trf_wbck_ena;
  wire [`QPU_TIME_WIDTH - 1 : 0] trf_wbck_data;

  wire erf_wbck_ena;
  wire [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] erf_wbck_data;
  wire [(`QPU_EVENT_NUM - 1) : 0] erf_wbck_oprand;


  wire tiq_wbck_ena;
  wire  tiq_wbck_ready;
  wire [`QPU_TIME_WIDTH - 1 : 0] tiq_wbck_data;

  wire evq_wbck_ena;
  wire evq_wbck_ready;
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
////////////////////regfile/////////////////////////////
//classical regfile

  wire [`QPU_XLEN-1:0] crf_rs1;
  wire [`QPU_XLEN-1:0] crf_rs2;


//time regfile          
  wire [`QPU_TIME_WIDTH - 1 : 0] trf_data;        //to alu

//event regfile
  wire [(`QPU_EVENT_NUM - 1) : 0] erf_oprand;      // to queue and alu
  wire [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] erf_data;


//measurement result reg
  reg [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement;
  reg  mcu_i_wen;

  reg read_mrf_ena;                                    //FMR指令�????1，其余时刻均�????0
  //input [`QPU_QUBIT_NUM - 1 : 0] read_qubit_list,          //控制读出列表,读出列表在rs1中，内部直连
  wire mrf_data;        //返回测量结果，这里不存在正在写回的问题，因为如果正在写回，oitf中的qubitlist依旧�???1，不可以派遣fmr指令,read_qubit_ena控制输出结果，会�???直输出测量结果（加了mask）！

  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_zero;   ///发�?�给event_queue，做快反馈控�????
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_one ; 
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_equ;


////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////
  // The Flush interface to IFU
  //
  //   To save the gatecount, when we need to flush pipeline with new PC, 
  //     we want to reuse the adder in IFU, so we will not pass flush-PC
  //     to IFU, instead, we pass the flush-pc-adder-op1/op2 to IFU
  //     and IFU will just use its adder to caculate the flush-pc-adder-result
  //
  reg   pipe_flush_ack;
  wire  pipe_flush_req;
  wire  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1;  
  wire  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2;  

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The LSU Write-Back Interface
  reg  lsu_o_valid; // Handshake valid
  wire lsu_o_ready; // Handshake ready
  reg  [`QPU_XLEN-1:0] lsu_o_wbck_data;

  wire [`QPU_XLEN-1:0] longp_wbck_o_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] longp_wbck_o_rdidx;
  //////////////////////////////////////////////////////////////
  //////////////////////LSU////////////////////////////////////////
  // The AGU ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  wire                         lsu_icb_cmd_valid; // Handshake valid
  reg                          lsu_icb_cmd_ready; // Handshake ready
  wire [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr; // Bus transaction start addr 
  wire                         lsu_icb_cmd_read;   // Read or write
  wire [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata; 
  wire [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask; 

  //    * Bus RSP channel
  reg                          lsu_icb_rsp_valid; // Response valid 
  wire                         lsu_icb_rsp_ready; // Response ready
  reg  [`QPU_XLEN-1:0]         lsu_icb_rsp_rdata;

  //////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
/////////////////////queue/////////////////////////////////
  reg i_trigger;
  wire trigger_o_clk_ena;
  reg [`QPU_TIME_WIDTH - 1 : 0] trigger_i_clk;
  wire  [`QPU_EVENT_NUM - 1: 0] evq_dest_o_valid;        
  wire  [`QPU_EVENT_WIRE_WIDTH - 1 : 0] evq_dest_o_data;


////////////////////////decode//////////////////////////////////////
  initial
  begin

    i_trigger = 0;
    trigger_i_clk = `QPU_TIME_WIDTH'b0;

    #3 i_instr = 32'b0;
    #1 i_pc = `QPU_PC_SIZE'b0;
    #0 i_prdt_taken = 1'b0;

    #0 i_instr = `SMIS_S13_001111;                //1
    #2 i_instr = `SMIS_S14_000101;                //2
    #2 i_instr = `T0_GATE0_S0_XYGATE_H_S13;       //3
    #2 i_instr = `T1_ZGATE_Z_XYGATE0;             //4
    #2 i_instr = `T1_ZGATE_1_S0_GATE0;            //5
    #2 i_instr = `T4_XYGATE_Y_S2_XYGATE_X_S1;     //6
    #2 i_instr = `T0_XYGATE_Y90_S4_XYGATE_X90_S3; //7
    #2 i_instr = `T1_GATE0_S0_MEASURE_S14;        //8
    #2 i_instr = `QWAIT_4;                       //9
    #2 i_instr = `FMR_R2_S3;                             //10
    #2 i_instr = 32'b0;
    #2 i_trigger = 1'b1;
    #0 trigger_i_clk = `QPU_TIME_WIDTH'b0;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b10;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b11;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b100;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b101;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b110;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b111;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1000;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1001;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1010;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1011;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1011;
    #2 i_instr = `QWAIT_4;     
    #2 i_instr = `QWAIT_4;                      //9
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1011;
    #0 i_instr=32'b0;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1100;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1101;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1110;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b1111;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b10000;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b10001;
    #2 trigger_i_clk = `QPU_TIME_WIDTH'b10010;
/*     #0 i_instr = `SMIS_S14_010100;                         //1
    #2 i_instr = `SMIS_S15_101000;                         //2
    #2 i_instr = `SMIS_S16_100100;                         //3  
    #2 i_instr = `SMIS_S17_001100;                         //4
    #2 i_instr = `T0_H_S14_X90_S15;                        //5
    #2 i_instr = `T1_Y90_S2_X90_S3;                        //6
    #2 i_instr = `T2_Y90_S16_GATE0_S0;                     //7
    #2 i_instr = `T3_ZGATE0_XYGATE1;                       //8
    #2 i_instr = `T4_ZGATE1_X90_S3;                        //9
    #2 i_instr = `T5_ZGATE2_GATE0_S0;                      //10


    #2 i_instr = `T1_MEASURE_S17;                         //11
    #2 i_instr = `QWAIT_30;                               //12    
    #2 i_instr = `ADDI_R1_R0_001100;                      //13
    #2 i_instr = `FMR_R2_S17;                             //14
    #2 i_instr = `BEQ_R1_R2_CASE2;                        //15  
    #2 i_instr = `T0_X90_S2;                              //16
    #2 i_instr = `QWAIT_1;                                //17
    #2 i_instr = `BEQ_R0_R0_NEXT;                         //18  
    #2 i_instr = `T0_H_S2;                                //19    
    #2 i_instr = `QWAIT_1;                                //20
    #2 i_instr = `T0_MEASURE_S2;                          //21  
    #2 i_instr = `QWAIT_30;                               //22

    #2 i_instr = `instr_LOAD;
    #2 i_instr = `instr_STORE;
  end
////////////////////////////////////////////////////////////////////


/////////////////disp////////////////////////////
  initial
  begin
    i_valid = 1'b1;
  end
////////////////////////////////////////////////



/////////////////////oitf/////////////////////////
initial
begin
    moitf_ret_ena = 1'b0;
    clk = 1'b1;
    rst_n = 1'b0;
    #3 rst_n = 1'b1;
end

always #(clk_period/2) clk = ~clk;
/////////////////////////////////////////////////

////////////////////FLUSH////////////////////////////

//////////////////////////////////////////////////
initial
begin
    pipe_flush_ack = 1'b1;
end

////////////////////////////////////////////////

///////////////////LSU///////////////////////////
initial
begin
    lsu_o_valid = 1'b0;
    lsu_o_wbck_data = `QPU_XLEN'b0;
    lsu_icb_cmd_ready = 1'b1;
    lsu_icb_rsp_valid = 1'b1;
    lsu_icb_rsp_rdata = `QPU_XLEN'b0;

end
///////////////////////////////////////////////

//////////////////////////////////////////////////
initial
begin
    mcu_i_measurement = `QPU_QUBIT_NUM'b0;
    mcu_i_wen = 1'b0;

    
end
//////////////////////////////////////////////////

/////////////////////////////////////////////////



  QPU_exu_decode test_QPU_exu_decode (

    .i_instr                      (i_instr        ),
    .i_pc                         (i_pc        ),
    .i_prdt_taken                 (i_prdt_taken), 
  

    .dec_rs1x0                    (dec_rs1x0  ),
    .dec_rs2x0                    (dec_rs2x0  ),
    .dec_rs1en                    (dec_rs1en  ),
    .dec_rs2en                    (dec_rs2en  ),
    .dec_rdwen                    (dec_rdwen  ),
    .dec_rs1idx                   (i_rs1idx),
    .dec_rs2idx                   (i_rs2idx),
    .dec_rdidx                    (dec_rdidx  ),
    .dec_info                     (dec_info   ),
    .dec_imm                      (dec_imm    ),
    .dec_pc                       (dec_pc     ),
    .dec_new_timepoint            (dec_ntp    ),
    .dec_need_qubitflag           (dec_nqf    ),
    .dec_measure                  (dec_measure),
    .dec_fmr                      (dec_fmr    ),

    .dec_bxx                      (dec_bxx),
    .dec_bjp_imm                  (dec_bjp_imm)
  );


  QPU_exu_disp test_QPU_exu_disp(

    .disp_i_valid          (i_valid        ),
    .disp_i_ready          (i_ready        ),
                                       
    .disp_i_rs1x0          (dec_rs1x0      ),
    .disp_i_rs2x0          (dec_rs2x0      ),
    .disp_i_rs1en          (dec_rs1en      ),
    .disp_i_rs2en          (dec_rs2en      ),
    .disp_i_rs1idx         (i_rs1idx       ),
    .disp_i_rs2idx         (i_rs2idx       ),
    .disp_i_rs1            (crf_rs1        ),
    .disp_i_rs2            (crf_rs2        ),
    .disp_i_rdwen          (dec_rdwen      ),
    .disp_i_rdidx          (dec_rdidx      ),
    .disp_i_info           (dec_info       ),
    .disp_i_imm            (dec_imm        ),
    .disp_i_pc             (dec_pc         ),
    .disp_i_ntp            (dec_ntp        ),
    .disp_i_measure        (dec_measure    ),
    .disp_i_nqf            (dec_nqf        ),
    .disp_i_fmr            (dec_fmr        ),

    .disp_i_clk            (trf_data       ),
    .disp_i_qmr            (mrf_data       ),
    .disp_i_edata          (erf_data       ),
    .disp_i_oprand         (erf_oprand     ),

    .disp_o_alu_valid    (disp_alu_valid   ),
    .disp_o_alu_ready    (disp_alu_ready   ),
    .disp_o_alu_longpipe (disp_alu_longpipe),

    .disp_o_alu_rs1      (disp_alu_rs1     ),
    .disp_o_alu_rs2      (disp_alu_rs2     ),
    .disp_o_alu_rdwen    (disp_alu_rdwen    ),
    .disp_o_alu_rdidx    (disp_alu_rdidx   ),
    .disp_o_alu_info     (disp_alu_info    ),
    .disp_o_alu_imm      (disp_alu_imm     ),
    .disp_o_alu_pc       (disp_alu_pc      ),
  
    .disp_o_alu_clk      (disp_alu_clk     ),
    .disp_o_alu_qmr      (disp_alu_qmr     ),
    .disp_o_alu_edata    (disp_alu_edata   ),
    .disp_o_alu_oprand   (disp_alu_oprand  ),

    .disp_o_alu_ntp      (disp_alu_ntp     ),
    .disp_o_alu_fmr      (disp_alu_fmr     ),
    .disp_o_alu_measure  (disp_alu_measure ),

    .oitfrd_match_disprs1(oitfrd_match_disprs1),
    .oitfrd_match_disprs2(oitfrd_match_disprs2),
    .oitfrd_match_disprd (oitfrd_match_disprd ),
    .oitfqf_match_dispql (oitfqf_match_dispql ),


    .disp_oitf_ena       (disp_oitf_ena    ),
    .disp_moitf_ena      (disp_moitf_ena   ),
    .disp_oitf_ready     (disp_oitf_ready  ),
    .disp_moitf_ready    (disp_moitf_ready ),

    .disp_oitf_rs1en     (disp_oitf_rs1en),
    .disp_oitf_rs2en     (disp_oitf_rs2en),
    .disp_oitf_rdwen     (disp_oitf_rdwen ),
    .disp_oitf_qfren     (disp_oitf_qfren ),

    .disp_oitf_rs1idx    (disp_oitf_rs1idx),
    .disp_oitf_rs2idx    (disp_oitf_rs2idx),
    .disp_oitf_rdidx     (disp_oitf_rdidx ),
    .disp_oitf_qubitlist (disp_oitf_qubitlist)
   

  );


  QPU_exu_alu test_QPU_exu_alu(


    .i_valid             (disp_alu_valid   ),
    .i_ready             (disp_alu_ready   ),
    .i_longpipe          (disp_alu_longpipe),

    .i_rs1               (disp_alu_rs1     ),
    .i_rs2               (disp_alu_rs2     ),
    .i_imm               (disp_alu_imm     ),
    .i_info              (disp_alu_info    ),

    .i_clk               (disp_alu_clk     ),
    .i_qmr               (disp_alu_qmr     ),
    .i_edata             (disp_alu_edata   ),
    .i_oprand            (disp_alu_oprand  ),

    .i_ntp               (disp_alu_ntp     ),
    .i_fmr               (disp_alu_fmr     ),
    .i_measure           (disp_alu_measure ),

    .i_pc                (i_pc    ),
    .i_rdidx             (disp_alu_rdidx   ),
    .i_rdwen             (disp_alu_rdwen   ),

    .cmt_o_valid         (alu_cmt_valid      ),
    .cmt_o_ready         (alu_cmt_ready      ),
    .cmt_o_pc            (alu_cmt_pc         ),
    .cmt_o_imm           (alu_cmt_imm        ),
    .cmt_o_bjp           (alu_cmt_bjp        ),
    .cmt_o_bjp_prdt      (alu_cmt_bjp_prdt   ),
    .cmt_o_bjp_rslv      (alu_cmt_bjp_rslv   ),

    .cwbck_o_valid        (alu_cwbck_o_valid ), 
    .cwbck_o_ready        (alu_cwbck_o_ready ),
    .cwbck_o_data         (alu_cwbck_o_data  ),
    .cwbck_o_rdidx        (alu_cwbck_o_rdidx ),
  
    .qcwbck_o_valid       (alu_qcwbck_o_valid ), 
    .qcwbck_o_ready       (alu_qcwbck_o_ready ),
    .qcwbck_o_data        (alu_qcwbck_o_data  ),
    .qcwbck_o_rdidx       (alu_qcwbck_o_rdidx ),

    .twbck_o_valid        (alu_twbck_o_valid ), 
    .twbck_o_ready        (alu_twbck_o_ready ),
    .twbck_o_data         (alu_twbck_o_data  ),

    .ewbck_o_valid        (alu_ewbck_o_valid ), 
    .ewbck_o_ready        (alu_ewbck_o_ready ),
    .ewbck_o_data         (alu_ewbck_o_data  ),
    .ewbck_o_oprand       (alu_ewbck_o_oprand),

    .lsu_icb_cmd_valid   (lsu_icb_cmd_valid ),
    .lsu_icb_cmd_ready   (lsu_icb_cmd_ready ),
    .lsu_icb_cmd_addr    (lsu_icb_cmd_addr  ),
    .lsu_icb_cmd_read    (lsu_icb_cmd_read  ),
    .lsu_icb_cmd_wdata   (lsu_icb_cmd_wdata ),
    .lsu_icb_cmd_wmask   (lsu_icb_cmd_wmask ),

    .lsu_icb_rsp_valid   (lsu_icb_rsp_valid ),
    .lsu_icb_rsp_ready   (lsu_icb_rsp_ready ),
    .lsu_icb_rsp_rdata   (lsu_icb_rsp_rdata)



  );

  QPU_exu_oitf test_QPU_exu_oitf(
    .dis_cf_ready            (disp_oitf_ready),
    .dis_mf_ready            (disp_moitf_ready),
    .dis_cl_ena              (disp_oitf_ena  ),
    .dis_qf_ena              (disp_moitf_ena),
    .ret_cl_ena              (oitf_ret_ena  ),
    .ret_qf_ena              (moitf_ret_ena ),
   

    .ret_rdidx            (oitf_ret_rdidx),
    .ret_rdwen            (oitf_ret_rdwen),

    .ret_mf               (disp_oitf_ret_measurelist),

    .disp_i_rs1en         (disp_oitf_rs1en),
    .disp_i_rs2en         (disp_oitf_rs2en),
    .disp_i_rdwen         (disp_oitf_rdwen ),
    .disp_i_rs1idx        (disp_oitf_rs1idx),
    .disp_i_rs2idx        (disp_oitf_rs2idx),
    .disp_i_rdidx         (disp_oitf_rdidx ),

    .disp_i_qfren         (disp_oitf_qfren ),
    .disp_i_ql            (disp_oitf_qubitlist),

    .oitfrd_match_disprs1 (oitfrd_match_disprs1),
    .oitfrd_match_disprs2 (oitfrd_match_disprs2),
    .oitfrd_match_disprd  (oitfrd_match_disprd ),
    .oitfqf_match_dispql  (oitfqf_match_dispql),

    .oitf_empty           (oitf_empty ),
    .moitf_empty          (moitf_empty),

    .clk                  (clk           ),
    .rst_n                (rst_n         ) 
  );


  QPU_exu_longpwbck u_QPU_exu_longpwbck(

    .lsu_wbck_i_valid   (lsu_o_valid ),
    .lsu_wbck_i_ready   (lsu_o_ready ),
    .lsu_wbck_i_data    (lsu_o_wbck_data  ),

    .longp_wbck_o_valid   (longp_wbck_o_valid ), 
    .longp_wbck_o_ready   (longp_wbck_o_ready ),
    .longp_wbck_o_data    (longp_wbck_o_data  ),
    .longp_wbck_o_rdidx   (longp_wbck_o_rdidx ),

    .oitf_ret_rdidx      (oitf_ret_rdidx),
    .oitf_ret_rdwen      (oitf_ret_rdwen),
    .oitf_ret_ena        (oitf_ret_ena  )
    

  );


  QPU_exu_wbck test_QPU_exu_wbck(

    .alu_cwbck_i_valid   (alu_cwbck_o_valid ), 
    .alu_cwbck_i_ready   (alu_cwbck_o_ready ),
    .alu_cwbck_i_data    (alu_cwbck_o_data  ),
    .alu_cwbck_i_rdidx   (alu_cwbck_o_rdidx ),

    .alu_qcwbck_i_valid  (alu_qcwbck_o_valid ),              
    .alu_qcwbck_i_ready  (alu_qcwbck_o_ready ),
    .alu_qcwbck_i_data   (alu_qcwbck_o_data  ),
    .alu_qcwbck_i_rdidx  (alu_qcwbck_o_rdidx ),


    .alu_twbck_i_valid   (alu_twbck_o_valid ), 
    .alu_twbck_i_ready   (alu_twbck_o_ready ),
    .alu_twbck_i_data    (alu_twbck_o_data  ),

    .alu_ewbck_i_valid   (alu_ewbck_o_valid ), 
    .alu_ewbck_i_ready   (alu_ewbck_o_ready ),
    .alu_ewbck_i_data    (alu_ewbck_o_data  ),
    .alu_ewbck_i_oprand  (alu_ewbck_o_oprand),                       

    .longp_wbck_i_valid (longp_wbck_o_valid ), 
    .longp_wbck_i_ready (longp_wbck_o_ready ),
    .longp_wbck_i_data  (longp_wbck_o_data  ),
    .longp_wbck_i_rdidx (longp_wbck_o_rdidx ),

    .crf_wbck_o_ena      (crf_wbck_ena    ),
    .crf_wbck_o_data     (crf_wbck_data   ),
    .crf_wbck_o_rdidx    (crf_wbck_rdidx  ),
    
    .qcrf_wbck_o_ena      (qcrf_wbck_ena    ),
    .qcrf_wbck_o_data     (qcrf_wbck_data   ),
    .qcrf_wbck_o_rdidx    (qcrf_wbck_rdidx  ),

    .trf_wbck_o_ena      (trf_wbck_ena    ),
    .trf_wbck_o_data     (trf_wbck_data   ),
    

    .erf_wbck_o_ena      (erf_wbck_ena    ),
    .erf_wbck_o_data     (erf_wbck_data   ),
    .erf_wbck_o_oprand   (erf_wbck_oprand ),

    .tiq_wbck_o_ena      (tiq_wbck_ena    ),
    .tiq_wbck_o_ready    (tiq_wbck_ready  ),
    .tiq_wbck_o_data     (tiq_wbck_data   ),

    .evq_wbck_o_ena      (evq_wbck_ena    ),
    .evq_wbck_o_ready    (evq_wbck_ready  )

  );

  QPU_exu_regfile test_QPU_exu_regfile(
    .read_src1_idx          (i_rs1idx       ),
    .read_src2_idx          (i_rs2idx       ),
    .read_src1_data         (crf_rs1        ),
    .read_src2_data         (crf_rs2        ),
 
    .cwbck_dest_wen         (crf_wbck_ena   ),
    .cwbck_dest_idx         (crf_wbck_rdidx ),
    .cwbck_dest_data        (crf_wbck_data  ),

    .qcwbck_dest_wen        (qcrf_wbck_ena   ),
    .qcwbck_dest_idx        (qcrf_wbck_rdidx ),
    .qcwbck_dest_data       (qcrf_wbck_data  ),

    .twbck_dest_wen         (trf_wbck_ena   ),
    .twbck_dest_data        (trf_wbck_data  ),

    .read_time_data         (trf_data       ),

    .ewbck_dest_wen         (erf_wbck_ena   ),
    .ewbck_dest_oprand      (erf_wbck_oprand),
    .ewbck_dest_data        (erf_wbck_data  ),

    .read_event_oprand      (erf_oprand     ),
    .read_event_data        (erf_data       ),

    .mcu_measure_i_data     (mcu_i_measurement        ),
    .mcu_measure_i_wen      (mcu_i_wen                ),
    .oitf_ret_i_measurelist (disp_oitf_ret_measurelist),

    .read_qubit_ena         (dec_fmr             ),
    .read_qubit_data        (mrf_data                 ),
    
    .qubit_measure_zero     (qubit_measure_zero       ),
    .qubit_measure_one      (qubit_measure_one        ),
    .qubit_measure_equ      (qubit_measure_equ        ),


    .clk                    (clk          ),
    .rst_n                  (rst_n        ) 
  );

    QPU_exu_commit u_QPU_exu_commit(


    .alu_cmt_i_valid         (alu_cmt_valid      ),
    .alu_cmt_i_ready         (alu_cmt_ready      ),
    .alu_cmt_i_pc            (alu_cmt_pc         ),
    .alu_cmt_i_imm           (alu_cmt_imm        ),
  
    .alu_cmt_i_bjp           (alu_cmt_bjp        ),
    .alu_cmt_i_bjp_prdt      (alu_cmt_bjp_prdt   ),
    .alu_cmt_i_bjp_rslv      (alu_cmt_bjp_rslv   ),
    

    .pipe_flush_ack          (pipe_flush_ack    ),
    .pipe_flush_req          (pipe_flush_req    ),
    .pipe_flush_add_op1      (pipe_flush_add_op1),  
    .pipe_flush_add_op2      (pipe_flush_add_op2),  
  
    .clk                     (clk          ),
    .rst_n                   (rst_n        ) 
  );


   QPU_exu_queue test_QPU_exu_queue(

    .tiq_dest_wen          (tiq_wbck_ena  ),
    .tiq_dest_i_ready      (tiq_wbck_ready),          
    .tiq_dest_i_data       (tiq_wbck_data ),   

    .i_trigger             (i_trigger),
    .trigger_o_clk_ena     (trigger_o_clk_ena),
    .trigger_i_clk         (trigger_i_clk),

    .evq_dest_wen          (evq_wbck_ena    ),              
    .evq_dest_i_ready      (evq_wbck_ready  ),          
    .evq_dest_oprand       (erf_oprand      ),             
    .evq_dest_data         (erf_data        ),           
 


    .evq_dest_o_valid      (evq_dest_o_valid),    
    .evq_dest_o_data       (evq_dest_o_data),  

    .qubit_measure_zero    (qubit_measure_zero),   
    .qubit_measure_one     (qubit_measure_one), 
    .qubit_measure_equ     (qubit_measure_equ),

    .clk                   (clk         ),
    .rst_n                 (rst_n       )
   );

  



endmodule












































