 

`include "../QPU/QPU_defines.v"
`include "tb_define.v"

`timescale 10ns/10ps

module tb_exu_disp();

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
  reg  mrf_data;
  reg [`QPU_EVENT_WIRE_WIDTH - 1 : 0] erf_data;
  reg [`QPU_EVENT_NUM - 1 : 0] erf_oprand;


  // Dispatch to ALU

  wire disp_alu_valid; 
  reg  disp_alu_ready;

  reg  disp_alu_longpipe;

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

  // Dispatch to OITF
  reg  oitfrd_match_disprs1;
  reg  oitfrd_match_disprs2;
  reg  oitfrd_match_disprd;

  //qf:qubitflag 
  reg  oitfqf_match_dispql;//qubit list of measure or FMR is same as qubit flag


  wire disp_oitf_ena;
  wire disp_moitf_ena;//measure instruction
  reg  disp_oitf_ready;
  reg  disp_moitf_ready;// fifo of the measured qubit number is ready
  
  wire disp_oitf_rs1en ;
  wire disp_oitf_rs2en ;
  wire disp_oitf_rdwen ;

  wire disp_oitf_qfren ;//

  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs1idx;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs2idx;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rdidx ;

  wire [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_qubitlist;//
/////////////////////////////////////////////////////////////////////



  
  initial
  begin
    #0 i_instr = `instr_LOAD;
    #0 i_pc = `QPU_PC_SIZE'b0;
    #0 i_prdt_taken = 1'b0;
    #2 i_instr = `instr_STORE;

    #5 i_instr = `instr_BEQ;
    #2 i_instr = `instr_BNE;
    #2 i_instr = `instr_BLT;
    #2 i_instr = `instr_BGT;

    #5 i_instr = `instr_ADDI;
    #2 i_instr = `instr_XORI;
    #2 i_instr = `instr_ORI;
    #2 i_instr = `instr_ANDI;

    #5 i_instr = `instr_ADD;
    #2 i_instr = `instr_XOR;
    #2 i_instr = `instr_OR;
    #2 i_instr = `instr_AND;

    #10 i_instr = `instr_QWAIT;
    #2 i_instr = `instr_FMR;
    #2 i_instr = `instr_SMIS;
    #2 i_instr = `instr_measure;

    #5 i_instr = `instr_QI_1;
    #2 i_instr = `instr_QI_2;
    #2 i_instr = `instr_QI_3;

    #5 i_instr = `instr_WFI;


  end

  initial
  begin
    i_valid = 1'b1;
    crf_rs1 = `QPU_XLEN'b0;
    crf_rs2 = `QPU_XLEN'b0;
    trf_data = `QPU_TIME_WIDTH'b110;
    mrf_data = 1'b1;
    erf_data = 66'b0;
    erf_oprand = 8'b0;


    disp_alu_ready = 1'b1;
    disp_alu_longpipe = 1'b1;

    oitfrd_match_disprs1 = 1'b0;
    oitfrd_match_disprs2 = 1'b0;
    oitfrd_match_disprd = 1'b0;
    oitfqf_match_dispql = 1'b0;

    disp_oitf_ready = 1'b1;
    disp_moitf_ready = 1'b1;

  end


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



endmodule

























