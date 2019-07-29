`include "../QPU/QPU_defines.v"
`include "tb_define.v"

`timescale 10ns/10ps

module tb_exu_wbck();

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
  wire dec_tqg;
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
  reg  [`QPU_XLEN-1:0] crf_rs1;
  reg  [`QPU_XLEN-1:0] crf_rs2;


  reg [`QPU_TIME_WIDTH - 1 : 0] trf_data;
  reg [`QPU_QUBIT_NUM - 1 : 0] mrf_data;
  reg [`QPU_EVENT_WIRE_WIDTH - 1 : 0] erf_data;
  reg [`QPU_EVENT_NUM - 1 : 0] erf_oprand;
  reg [`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1 : 0] tqgl_cur;
  reg [`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1 : 0] tqgl_pre;
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
  wire [`QPU_QUBIT_NUM - 1 : 0] disp_alu_qmr;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] disp_alu_edata;
  wire [`QPU_EVENT_NUM - 1 : 0] disp_alu_oprand;
  wire [(`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1) : 0] disp_alu_tqgl_pre;
  wire [(`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1) : 0] disp_alu_tqgl_cur;
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
  reg  alu_cmt_ready; // Handshake ready

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
  wire [(`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1) : 0] alu_ewbck_o_tqgl;



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
  reg  oitf_ret_ena;
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
  wire [(`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1) : 0] erf_wbck_tqgl;

  wire tiq_wbck_ena;
  reg  tiq_wbck_ready;
  wire [`QPU_TIME_WIDTH - 1 : 0] tiq_wbck_data;

  wire evq_wbck_ena;
  reg  evq_wbck_ready;
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

////////////////////////decode//////////////////////////////////////
  initial
  begin
    #0 i_instr = `SMIS_S6_010100;
    #2 i_instr = `SMIS_S7_101000;
    #2 i_instr = `SMIS_S8_100100;
    #2 i_instr = `SMIS_S9_001100;
    #2 i_instr = `T0_H_S6_X90_S7;
    #2 i_instr = `T1_CNOTS_S2_CNOTT_S3;
    #2 i_instr = `T2_Y90_S8;
    #2 i_instr = `T1_MEASURE_S9;
    #2 i_instr = `QWAIT_30;
    #2 i_instr = `ADDI_R1_R0_001100;
    #2 i_instr = `FMR_R2_S9;
    #2 i_instr = `BEQ_R1_R2_CASE2;
    #2 i_instr = `T0_X90_S2;
    #2 i_instr = `QWAIT_1;
    #2 i_instr = `BEQ_R0_R0_NEXT;
    #2 i_instr = `T0_H_S2;
    #2 i_instr = `QWAIT_1;
    #2 i_instr = `T0_MEASURE_S2;
    #2 i_instr = `QWAIT_30;
  end
////////////////////////////////////////////////////////////////////


/////////////////disp////////////////////////////
  initial
  begin
    i_valid = 1'b1;

    crf_rs1 = `QPU_XLEN'b0;
    crf_rs2 = `QPU_XLEN'b0;
    trf_data = `QPU_TIME_WIDTH'b110;
    mrf_data = `QPU_QUBIT_NUM'b10;
    erf_data = 66'b0;
    erf_oprand = 8'b0;
    tqgl_cur = 48'b0;
    tqgl_pre = 48'b0;


  end
////////////////////////////////////////////////


///////////////////////////alu/////////////////////
initial
begin
    alu_cmt_ready = 1'b1;

end
///////////////////////////////////////////////////

/////////////////////oitf/////////////////////////
initial
begin
    oitf_ret_ena = 1'b1;
    moitf_ret_ena = 1'b1;
    clk = 1'b1;
    rst_n = 1'b0;
    #1 rst_n = 1'b1;
end

always #(clk_period/2) clk = ~clk;
/////////////////////////////////////////////////

///////////////////////wbck//////////////////////////
initial
begin
    tiq_wbck_ready = 1'b1;
    evq_wbck_ready = 1'b1;


end
////////////////////////////////////////////////

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
    .dec_tqg                      (dec_tqg    ),

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
    .disp_i_tqgl_pre       (tqgl_pre       ),
    .disp_i_tqgl_cur       (tqgl_cur       ),

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
    .disp_o_alu_tqgl_pre (disp_alu_tqgl_pre),
    .disp_o_alu_tqgl_cur (disp_alu_tqgl_cur),

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
    .i_tqgl_pre          (disp_alu_tqgl_pre),
    .i_tqgl_cur          (disp_alu_tqgl_cur),

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
    .ewbck_o_tqgl         (alu_ewbck_o_tqgl  )


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
    .alu_ewbck_i_tqgl    (alu_ewbck_o_tqgl  ),


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
    .erf_wbck_o_tqgl     (erf_wbck_tqgl   ),

    .tiq_wbck_o_ena      (tiq_wbck_ena    ),
    .tiq_wbck_o_ready    (tiq_wbck_ready  ),
    .tiq_wbck_o_data     (tiq_wbck_data   ),

    .evq_wbck_o_ena      (evq_wbck_ena    ),
    .evq_wbck_o_ready    (evq_wbck_ready  )

  );


endmodule












































