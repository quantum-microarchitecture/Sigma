                                                               
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  The Dispatch module to dispatch instructions to different functional units
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_disp(
  

  // The operands and decode info from dispatch
  input  disp_i_valid, // Handshake valid with IFU
  output disp_i_ready, // Handshake ready with IFU

  // The operand 1/2 read-enable signals and indexes
  input  disp_i_rs1x0,
  input  disp_i_rs2x0,
  input  disp_i_rs1en,
  input  disp_i_rs2en,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rs1idx,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rs2idx,
  input  [`QPU_XLEN-1:0] disp_i_rs1,
  input  [`QPU_XLEN-1:0] disp_i_rs2,
  input  disp_i_rdwen,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rdidx,
  input  [`QPU_DECINFO_WIDTH-1:0]  disp_i_info,  
  input  [`QPU_XLEN-1:0] disp_i_imm,
  input  [`QPU_PC_SIZE-1:0] disp_i_pc,                
  input  disp_i_ntp,//
  input  disp_i_measure,//
  input  disp_i_nqf,//
  input  disp_i_fmr,

  input [`QPU_TIME_WIDTH - 1 : 0] disp_i_clk,
  input [`QPU_QUBIT_NUM - 1 : 0] disp_i_qmr,
  input [`QPU_EVENT_WIRE_WIDTH - 1 : 0] disp_i_edata,
  input [`QPU_EVENT_NUM - 1 : 0] disp_i_oprand,
  //////////////////////////////////////////////////////////////
  // Dispatch to ALU

  output disp_o_alu_valid, 
  input  disp_o_alu_ready,

  input  disp_o_alu_longpipe,

  output [`QPU_XLEN-1:0] disp_o_alu_rs1,
  output [`QPU_XLEN-1:0] disp_o_alu_rs2,
  output disp_o_alu_rdwen,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] disp_o_alu_rdidx,
  output [`QPU_DECINFO_WIDTH-1:0]  disp_o_alu_info,  
  output [`QPU_XLEN-1:0] disp_o_alu_imm,
  output [`QPU_PC_SIZE-1:0] disp_o_alu_pc,            

  output [`QPU_TIME_WIDTH - 1 : 0] disp_o_alu_clk,
  output [`QPU_QUBIT_NUM - 1 : 0] disp_o_alu_qmr,
  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] disp_o_alu_edata,
  output [`QPU_EVENT_NUM - 1 : 0] disp_o_alu_oprand,
        //Quantum instruction
  output disp_o_alu_ntp,//
  output disp_o_alu_fmr,
  output disp_o_alu_measure,

  //////////////////////////////////////////////////////////////
  // Dispatch to OITF
  input  oitfrd_match_disprs1,
  input  oitfrd_match_disprs2,
  input  oitfrd_match_disprd,

  //qf:qubitflag 
  input  oitfqf_match_dispql,//qubit list of measure or FMR is same as qubit flag


  output disp_oitf_ena,
  output disp_moitf_ena,//measure instruction
  input  disp_oitf_ready,
  input  disp_moitf_ready,// fifo of the measured qubit number is ready
  
  output disp_oitf_rs1en ,
  output disp_oitf_rs2en ,
  output disp_oitf_rdwen ,

  output disp_oitf_qfren ,//

  output [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs1idx,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rs2idx,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] disp_oitf_rdidx ,

  output [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_qubitlist,//
  

  );


  wire [`QPU_DECINFO_GRP_WIDTH-1:0] disp_i_info_grp  = disp_i_info [`QPU_DECINFO_GRP];

  wire disp_alu_longp_prdt = (disp_i_info_grp == `QPU_DECINFO_GRP_LSU)  
                             ;
  wire disp_alu_longp_real = disp_o_alu_longpipe;

  
  wire disp_i_valid_pos; 
  wire   disp_i_ready_pos = disp_o_alu_ready;
  assign disp_o_alu_valid = disp_i_valid_pos; 
  
  
  wire raw_dep =  (oitfrd_match_disprs1) |
                   (oitfrd_match_disprs2) ; 

  wire waw_dep = (oitfrd_match_disprd) ; 

  wire dep = raw_dep | waw_dep | oitfqf_match_dispql;                       //for fmr,it is raw dep; for measure,it is WAW dep

  wire disp_condition = (~dep)  
                      &  (disp_alu_longp_prdt ? disp_oitf_ready : 1'b1)
                      & (disp_i_measure ? disp_moitf_ready: 1'b1)
                      ;

  assign disp_i_valid_pos = disp_condition & disp_i_valid; 
  assign disp_i_ready     = disp_condition & disp_i_ready_pos; 


  wire [`QPU_XLEN-1:0] disp_i_rs1_msked = disp_i_rs1 & {`QPU_XLEN{~disp_i_rs1x0}};
  wire [`QPU_XLEN-1:0] disp_i_rs2_msked = disp_i_rs2 & {`QPU_XLEN{~disp_i_rs2x0}};

  assign disp_o_alu_rs1   = disp_i_rs1_msked;
  assign disp_o_alu_rs2   = disp_i_rs2_msked;
  assign disp_o_alu_rdwen = disp_i_rdwen;
  assign disp_o_alu_rdidx = disp_i_rdidx;
  assign disp_o_alu_info  = disp_i_info;  
  
  //only write in oitf when instruction is dispatched successfully  
  assign disp_oitf_ena   = disp_o_alu_valid    & disp_o_alu_ready & disp_alu_longp_real;
  assign disp_moitf_ena  = disp_o_alu_valid    & disp_o_alu_ready & disp_i_measure;

  assign disp_o_alu_imm  = disp_i_imm;
  assign disp_o_alu_pc   = disp_i_pc; //
  assign disp_o_alu_ntp = disp_i_ntp;


  assign disp_oitf_rs1en  =  disp_i_rs1en;
  assign disp_oitf_rs2en  =  disp_i_rs2en;
  assign disp_oitf_rdwen  =  disp_i_rdwen;
  assign disp_oitf_qfren  =  disp_i_nqf;

  assign disp_oitf_rs1idx    = disp_i_rs1idx;
  assign disp_oitf_rs2idx    = disp_i_rs2idx;
  assign disp_oitf_rdidx     = disp_i_rdidx;
  assign disp_oitf_qubitlist = disp_i_rs1[`QPU_QUBIT_NUM - 1 : 0];
  
  assign disp_o_alu_qmr  = disp_i_qmr & {`QPU_QUBIT_NUM {disp_i_fmr}};
  assign disp_o_alu_clk  = disp_i_clk & {`QPU_TIME_WIDTH{disp_i_ntp}};
  assign disp_o_alu_edata = disp_i_edata;
  assign disp_o_alu_oprand = disp_i_oprand;
  assign disp_o_alu_fmr  = disp_i_fmr;
  assign disp_o_alu_measure = disp_i_measure;
endmodule                                      
                                               
                                               
                                               
