//=====================================================================
// Designer   : QI ZHOU
//
// Description:
//  The EXU module to implement entire Execution Stage
//
// ====================================================================

`include "QPU_defines.v"

module QPU_test_top(

  input  [`QPU_INSTR_SIZE-1:0] i_irin,// The instruction register
  input  [`QPU_PC_SIZE-1:0] i_pc,   // The PC register along with
  input  i_prdt_taken,                               
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs1idx,   // The RS1 index
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rs2idx,   // The RS2 index

  output dec_ntp,
  output dec_nqf,
  output dec_measure,
  output dec_fmr,
  output [`QPU_DECINFO_WIDTH-1:0]  dec_info,
/*    input   pipe_flush_ack,
  output  pipe_flush_req,
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  output  [`QPU_PC_SIZE-1:0] pipe_flush_add_op2,

  ///data from MCU
  input [`QPU_QUBIT_NUM - 1 : 0] mcu_i_measurement,
  input mcu_i_wen, */
  ///////////////////////////////////////////////////////////////
  input  clk,
  input  rst_n
  );
  
  wire  [`QPU_INSTR_SIZE-1:0] i_ir;
  sirv_gnrl_dffrs #(`QPU_INSTR_SIZE) ir_dffrs (i_irin,i_ir,clk,rst_n); 

  
  wire [`QPU_XLEN-1:0] dec_imm;
  wire [`QPU_PC_SIZE-1:0] dec_pc;
  wire dec_rs1x0;
  wire dec_rs2x0;
  wire dec_rdwen;
  wire dec_rs1en;
  wire dec_rs2en;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rdidx;


  //////////////////////////////////////////////////////////////
  // The Decoded Info-Bus
  QPU_exu_decode u_QPU_exu_decode (

    .i_instr                      (i_ir        ),
    .i_pc                         (i_pc        ),
    .i_prdt_taken                 (i_prdt_taken), 
  

    .dec_rs1x0                    (dec_rs1x0  ),
    .dec_rs2x0                    (dec_rs2x0  ),
    .dec_rs1en                    (dec_rs1en  ),
    .dec_rs2en                    (dec_rs2en  ),
    .dec_rdwen                    (dec_rdwen  ),
    .dec_rs1idx                   (),
    .dec_rs2idx                   (),
    .dec_rdidx                    (dec_rdidx  ),
    .dec_info                     (dec_info   ),
    .dec_imm                      (dec_imm    ),
    .dec_pc                       (dec_pc     ),

    .dec_new_timepoint            (dec_ntp    ),
    .dec_need_qubitflag           (dec_nqf    ),
    .dec_measure                  (dec_measure),
    .dec_fmr                      (dec_fmr    ),

    .dec_bxx                      (),
    .dec_bjp_imm                  ()
  );


//////////////////////////////////////////////////////////////
  // Instantiate the Regfile
  wire [`QPU_XLEN-1:0] crf_rs1;
  wire [`QPU_XLEN-1:0] crf_rs2;


  wire crf_wbck_ena;
  wire [`QPU_XLEN-1:0] crf_wbck_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] crf_wbck_rdidx;

  wire qcrf_wbck_ena;
  wire [`QPU_XLEN-1:0] qcrf_wbck_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] qcrf_wbck_rdidx;

  wire trf_wbck_ena;
  wire [`QPU_TIME_WIDTH - 1 : 0] trf_wbck_data;

  wire erf_wbck_ena;
  wire [`QPU_EVENT_WIRE_WIDTH-1:0] erf_wbck_data;
  wire [(`QPU_EVENT_NUM - 1) : 0] erf_wbck_oprand;

  wire [`QPU_TIME_WIDTH - 1 : 0] trf_data;
  wire [`QPU_EVENT_NUM - 1 : 0] erf_oprand;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] erf_data;

  wire [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_ret_measurelist;
  wire read_mrf_ena;
  wire mrf_data;

  wire qubit_measure_zero;
  wire qubit_measure_one;
  wire qubit_measure_equ;

  QPU_exu_regfile u_QPU_exu_regfile(
  
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

    .read_qubit_ena         (read_mrf_ena             ),
    .read_qubit_data        (mrf_data                 ),
    
    .qubit_measure_zero     (qubit_measure_zero       ),
    .qubit_measure_one      (qubit_measure_one        ),
    .qubit_measure_equ      (qubit_measure_equ        ),

    .clk                    (clk          ),
    .rst_n                  (rst_n        ) 
  );

  //////////////////////////////////////////////////////////////
  // Instantiate the Decode


  //////////////////////////////////////////////////////////////
  // Instantiate the Dispatch
  wire disp_alu_valid; 
  wire disp_alu_ready; 
  wire disp_alu_longpipe;

  wire [`QPU_XLEN-1:0] disp_alu_rs1;
  wire [`QPU_XLEN-1:0] disp_alu_rs2;
  wire [`QPU_XLEN-1:0] disp_alu_imm;
  wire [`QPU_DECINFO_WIDTH-1:0]  disp_alu_info;  
  wire [`QPU_PC_SIZE-1:0] disp_alu_pc;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_alu_rdidx;
  wire disp_alu_rdwen;
  wire [`QPU_TIME_WIDTH - 1 : 0] disp_alu_clk;
  wire disp_alu_qmr;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] disp_alu_edata;
  wire [`QPU_EVENT_NUM - 1 : 0] disp_alu_oprand;

  wire disp_alu_ntp;
  wire disp_alu_fmr;
  wire disp_alu_measure;

  wire disp_oitf_ready;
  wire disp_moitf_ready;

  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs1idx;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs2idx;
  wire  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rdidx;
  wire [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_qubitlist;

  wire  disp_oitf_rs1en;
  wire  disp_oitf_rs2en;
  wire  disp_oitf_rdwen;
  wire  disp_oitf_qfwen;

  wire oitfrd_match_disprs1;
  wire oitfrd_match_disprs2;
  wire oitfrd_match_disprd;
  wire oitfqf_match_dispql;

  wire disp_oitf_ena;
  wire disp_moitf_ena;

  QPU_exu_disp u_QPU_exu_disp(

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

  //////////////////////////////////////////////////////////////
  // Instantiate the OITF
  wire oitf_ret_ena = 1'b0;
  wire moitf_ret_ena = mcu_i_wen;

  wire [`QPU_RFIDX_REAL_WIDTH - 1 : 0] oitf_ret_rdidx;
  wire oitf_ret_rdwen;
  wire oitf_empty;
  wire moitf_empty;
  
  QPU_exu_oitf u_QPU_exu_oitf(
  
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

  //////////////////////////////////////////////////////////////
  // Instantiate the ALU
  ///to wbck
  wire alu_cwbck_o_valid;
  wire alu_cwbck_o_ready;
  wire [`QPU_XLEN-1:0] alu_cwbck_o_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] alu_cwbck_o_rdidx;

  wire alu_qcwbck_o_valid;
  wire alu_qcwbck_o_ready;
  wire [`QPU_XLEN-1:0] alu_qcwbck_o_data;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] alu_qcwbck_o_rdidx;

  wire alu_twbck_o_valid;
  wire alu_twbck_o_ready;
  wire [`QPU_TIME_WIDTH - 1 : 0] alu_twbck_o_data;

  wire alu_ewbck_o_valid;
  wire alu_ewbck_o_ready;
  wire [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] alu_ewbck_o_data;
  wire [(`QPU_EVENT_NUM - 1) : 0]       alu_ewbck_o_oprand; 

  ///to cmt
  wire alu_cmt_valid;
  wire alu_cmt_ready; 
  wire [`QPU_PC_SIZE-1:0] alu_cmt_pc;
  wire [`QPU_XLEN-1:0]    alu_cmt_imm;
  wire alu_cmt_bjp;
  wire alu_cmt_bjp_prdt;
  wire alu_cmt_bjp_rslv;
  
  QPU_exu_alu u_QPU_exu_alu(
  
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
    .ewbck_o_oprand       (alu_ewbck_o_oprand)
  );

  //////////////////////////////////////////////////////////////
  // Instantiate the Final Write-Back

  QPU_exu_wbck u_QPU_exu_wbck(

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

  //////////////////////////////////////////////////////////////
  // Instantiate the Commit


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
    .pipe_flush_add_op2      (pipe_flush_add_op2)
  );

endmodule                                      