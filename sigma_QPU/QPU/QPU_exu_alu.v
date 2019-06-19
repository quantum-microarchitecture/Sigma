                                                      
                                                                         
                                                                         
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  The ALU module to implement the compute function unit
//    and the lsu (address generate unit) for LSU is also handled by ALU
//    additionaly, the shared-impelmentation of MUL and DIV instruction 
//    is also shared by ALU in E200
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_alu(

  //////////////////////////////////i_longpipe////////////////////////////
  // The operands and decode info from dispatch
  input  i_valid, 
  output i_ready, 

  output i_longpipe, // Indicate this instruction is 
                     //   issued as a long pipe instruction
 
  input  [`QPU_XLEN-1:0] i_rs1,
  input  [`QPU_XLEN-1:0] i_rs2,
  input  [`QPU_XLEN-1:0] i_imm,
  input  [`QPU_DECINFO_WIDTH-1:0]  i_info,  

  input [`QPU_TIME_WIDTH - 1 : 0] i_clk,
  input [`QPU_QUBIT_NUM - 1 : 0] i_qmr,
  input [`QPU_EVENT_WIRE_WIDTH - 1 : 0] i_edata,               ///reg->disp->qiu
  input [`QPU_EVENT_NUM - 1 : 0] i_oprand,                     ///reg->disp->qiu

  input i_ntp,
  input i_fmr,
  input i_measure,

  input  [`QPU_PC_SIZE-1:0] i_pc,             //to cmt

  input  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rdidx,
  input  i_rdwen,


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Commit Interface
  output cmt_o_valid, // Handshake valid
  input  cmt_o_ready, // Handshake ready

  output [`QPU_PC_SIZE-1:0] cmt_o_pc,  
  output [`QPU_XLEN-1:0]    cmt_o_imm,// The resolved ture/false
    //   The Branch and Jump Commit

  output cmt_o_bjp,

  output cmt_o_bjp_prdt,// The predicted ture/false  
  output cmt_o_bjp_rslv,// The resolved ture/false



  //////////////////////////////////////////////////////////////
  // The ALU Write-Back Interface
  output cwbck_o_valid, // Handshake valid
  input  cwbck_o_ready, // Handshake ready
  output [`QPU_XLEN-1:0] cwbck_o_data,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] cwbck_o_rdidx,

  output qcwbck_o_valid, // Handshake valid
  input  qcwbck_o_ready, // Handshake ready
  output [`QPU_XLEN-1:0] qcwbck_o_data,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] qcwbck_o_rdidx,


  output twbck_o_valid,
  input  twbck_o_ready,
  output [`QPU_TIME_WIDTH - 1 : 0] twbck_o_data,

  output ewbck_o_valid,
  input  ewbck_o_ready,
  output [(`QPU_EVENT_WIRE_WIDTH - 1) : 0]  ewbck_o_data,
  output [(`QPU_EVENT_NUM - 1) : 0]        ewbck_o_oprand,


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The lsu ICB Interface to LSU-ctrl
  //    * Bus cmd channel
  output                         lsu_icb_cmd_valid, // Handshake valid
  input                          lsu_icb_cmd_ready, // Handshake ready
  output [`QPU_ADDR_SIZE-1:0]    lsu_icb_cmd_addr, // Bus transaction start addr 
  output                         lsu_icb_cmd_read,   // Read or write
  output [`QPU_XLEN-1:0]         lsu_icb_cmd_wdata, 
  output [`QPU_XLEN/8-1:0]       lsu_icb_cmd_wmask, 
  
  //    * Bus RSP channel
  input                          lsu_icb_rsp_valid, // Response valid 
  output                         lsu_icb_rsp_ready, // Response ready
  input  [`QPU_XLEN-1:0]         lsu_icb_rsp_rdata


  );



  //////////////////////////////////////////////////////////////
  // Dispatch to different sub-modules according to their types

  wire alu_op =  (i_info[`QPU_DECINFO_GRP] == `QPU_DECINFO_GRP_ALU); 
  wire lsu_op =  (i_info[`QPU_DECINFO_GRP] == `QPU_DECINFO_GRP_LSU); 
  wire bjp_op =  (i_info[`QPU_DECINFO_GRP] == `QPU_DECINFO_GRP_BJP); 
  wire qiu_op =  (i_info[`QPU_DECINFO_GRP] == `QPU_DECINFO_GRP_QIU); 



  // The ALU incoming instruction may go to several different targets:
  //   * The ALUDATAPATH if it is a regular ALU instructions
  //   * The Branch-cmp if it is a BJP instructions
  //   * The lsu if it is a load/store relevant instructions
  //   * The MULDIV if it is a MUL/DIV relevant instructions and MULDIV
  //       is reusing the ALU adder


  wire lsu_i_valid = i_valid & lsu_op;
  wire alu_i_valid = i_valid & alu_op;
  wire bjp_i_valid = i_valid & bjp_op;
  wire qiu_i_valid = i_valid & qiu_op;


  wire lsu_i_ready;
  wire alu_i_ready;
  wire bjp_i_ready;
  wire qiu_i_ready;

  assign i_ready =   (lsu_i_ready & lsu_op)
                   | (alu_i_ready & alu_op)
                   | (bjp_i_ready & bjp_op)
                   | (qiu_i_ready & qiu_op)
                     ;

  
  assign i_longpipe =  lsu_op;

  
  //////////////////////////////////////////////////////////////
  // Instantiate the BJP module
  //
  wire bjp_o_valid; 
  wire bjp_o_ready; 
  wire bjp_o_cmt_prdt;
  wire bjp_o_cmt_rslv;

  wire [`QPU_XLEN-1:0] bjp_req_alu_op1;
  wire [`QPU_XLEN-1:0] bjp_req_alu_op2;
  wire bjp_req_alu_cmp_eq ;
  wire bjp_req_alu_cmp_ne ;
  wire bjp_req_alu_cmp_lt ;
  wire bjp_req_alu_cmp_gt ;

  wire bjp_req_alu_cmp_res;

  wire  [`QPU_XLEN-1:0]           bjp_i_rs1  = {`QPU_XLEN         {bjp_op}} & i_rs1;
  wire  [`QPU_XLEN-1:0]           bjp_i_rs2  = {`QPU_XLEN         {bjp_op}} & i_rs2;
  wire  [`QPU_DECINFO_WIDTH-1:0]  bjp_i_info = {`QPU_DECINFO_WIDTH{bjp_op}} & i_info;  

  QPU_exu_alu_bjp u_QPU_exu_alu_bjp(
      .bjp_i_valid         (bjp_i_valid         ),
      .bjp_i_ready         (bjp_i_ready         ),
      .bjp_i_rs1           (bjp_i_rs1           ),
      .bjp_i_rs2           (bjp_i_rs2           ),
      .bjp_i_info          (bjp_i_info[`QPU_DECINFO_BJP_WIDTH-1:0]),

      .bjp_o_valid         (bjp_o_valid      ),
      .bjp_o_ready         (bjp_o_ready      ),

      .bjp_o_cmt_prdt      (bjp_o_cmt_prdt   ),
      .bjp_o_cmt_rslv      (bjp_o_cmt_rslv   ),

      .bjp_req_alu_op1     (bjp_req_alu_op1       ),
      .bjp_req_alu_op2     (bjp_req_alu_op2       ),
      .bjp_req_alu_cmp_eq  (bjp_req_alu_cmp_eq    ),
      .bjp_req_alu_cmp_ne  (bjp_req_alu_cmp_ne    ),
      .bjp_req_alu_cmp_lt  (bjp_req_alu_cmp_lt    ),
      .bjp_req_alu_cmp_gt  (bjp_req_alu_cmp_gt    ),
      
      .bjp_req_alu_cmp_res (bjp_req_alu_cmp_res   )

  );


  //////////////////////////////////////////////////////////////
  // Instantiate the LSU module
  //
  wire lsu_o_valid; 
  wire lsu_o_ready; 
  
  
  wire [`QPU_XLEN-1:0] lsu_req_alu_op1;
  wire [`QPU_XLEN-1:0] lsu_req_alu_op2;
  wire [`QPU_XLEN-1:0] lsu_req_alu_res;
     
  

  wire  [`QPU_XLEN-1:0]           lsu_i_rs1  = {`QPU_XLEN         {lsu_op}} & i_rs1;
  wire  [`QPU_XLEN-1:0]           lsu_i_rs2  = {`QPU_XLEN         {lsu_op}} & i_rs2;
  wire  [`QPU_XLEN-1:0]           lsu_i_imm  = {`QPU_XLEN         {lsu_op}} & i_imm;
  wire  [`QPU_DECINFO_WIDTH-1:0]  lsu_i_info = {`QPU_DECINFO_WIDTH{lsu_op}} & i_info;  
 
  QPU_exu_alu_lsu u_QPU_exu_alu_lsu(

      .lsu_i_valid         (lsu_i_valid     ),
      .lsu_i_ready         (lsu_i_ready     ),
      .lsu_i_rs1           (lsu_i_rs1       ),
      .lsu_i_rs2           (lsu_i_rs2       ),
      .lsu_i_imm           (lsu_i_imm       ),
      .lsu_i_info          (lsu_i_info[`QPU_DECINFO_LSU_WIDTH-1:0]),

      .lsu_o_valid         (lsu_o_valid         ),
      .lsu_o_ready         (lsu_o_ready         ),      
                                                
      .lsu_icb_cmd_valid   (lsu_icb_cmd_valid   ),
      .lsu_icb_cmd_ready   (lsu_icb_cmd_ready   ),
      .lsu_icb_cmd_addr    (lsu_icb_cmd_addr    ),
      .lsu_icb_cmd_read    (lsu_icb_cmd_read    ),
      .lsu_icb_cmd_wdata   (lsu_icb_cmd_wdata   ),
      .lsu_icb_cmd_wmask   (lsu_icb_cmd_wmask   ),
      
      .lsu_icb_rsp_valid   (lsu_icb_rsp_valid   ),
      .lsu_icb_rsp_ready   (lsu_icb_rsp_ready   ),
                                                     
      .lsu_req_alu_op1     (lsu_req_alu_op1     ),
      .lsu_req_alu_op2     (lsu_req_alu_op2     ),
      .lsu_req_alu_res     (lsu_req_alu_res     )
     
  );

  //////////////////////////////////////////////////////////////
  // Instantiate the regular ALU module
  //
  wire alu_o_valid; 
  wire alu_o_ready; 
  wire [`QPU_XLEN-1:0] alu_o_wbck_cdata;

  wire alu_req_alu_add ;
  wire alu_req_alu_xor ;
  wire alu_req_alu_or  ;
  wire alu_req_alu_and ;
 
  wire [`QPU_XLEN-1:0] alu_req_alu_op1;
  wire [`QPU_XLEN-1:0] alu_req_alu_op2;
  wire [`QPU_XLEN-1:0] alu_req_alu_res;

  wire  [`QPU_XLEN-1:0]           alu_i_rs1  = {`QPU_XLEN         {alu_op}} & i_rs1;
  wire  [`QPU_XLEN-1:0]           alu_i_rs2  = {`QPU_XLEN         {alu_op}} & i_rs2;
  wire  [`QPU_XLEN-1:0]           alu_i_imm  = {`QPU_XLEN         {alu_op}} & i_imm;
  wire  [`QPU_DECINFO_WIDTH-1:0]  alu_i_info = {`QPU_DECINFO_WIDTH{alu_op}} & i_info;  
  wire  [`QPU_TIME_WIDTH - 1 : 0] alu_i_clk  = {`QPU_TIME_WIDTH   {(alu_op & i_ntp)}}  & i_clk;
  wire  [`QPU_QUBIT_NUM - 1 : 0 ] alu_i_qmr  = {`QPU_QUBIT_NUM    {(alu_op & i_fmr)}}  & i_qmr;
  
  QPU_exu_alu_rglr u_QPU_exu_alu_rglr(

      .alu_i_valid         (alu_i_valid     ),
      .alu_i_ready         (alu_i_ready     ),
      .alu_i_rs1           (alu_i_rs1           ),
      .alu_i_rs2           (alu_i_rs2           ),
      .alu_i_imm           (alu_i_imm           ),

      .alu_i_clk           (alu_i_clk           ),
      .alu_i_qmr           (alu_i_qmr           ),

      .alu_i_info          (alu_i_info[`QPU_DECINFO_ALU_WIDTH-1:0]),

      .alu_o_valid         (alu_o_valid         ),
      .alu_o_ready         (alu_o_ready         ),
      .alu_o_wbck_cdata     (alu_o_wbck_cdata     ),

      .alu_req_alu_add     (alu_req_alu_add       ),
      .alu_req_alu_xor     (alu_req_alu_xor       ),
      .alu_req_alu_or      (alu_req_alu_or        ),
      .alu_req_alu_and     (alu_req_alu_and       ),

      .alu_req_alu_op1     (alu_req_alu_op1       ),
      .alu_req_alu_op2     (alu_req_alu_op2       ),
      .alu_req_alu_res     (alu_req_alu_res       )


  );



 //////////////////////////////////////////////////////////////
  // Instantiate the QIU module
  //
  wire qiu_o_valid; 
  wire qiu_o_ready; 
  wire [`QPU_TIME_WIDTH - 1 : 0] qiu_o_wbck_tdata;
  wire [`QPU_EVENT_WIRE_WIDTH - 1 : 0] qiu_o_wbck_edata;
  wire [`QPU_EVENT_NUM - 1 : 0] qiu_o_wbck_oprand;

  wire [`QPU_XLEN-1:0] qiu_req_alu_op1;
  wire [`QPU_XLEN-1:0] qiu_req_alu_op2;
  wire [`QPU_XLEN-1:0] qiu_req_alu_res;

  wire  [`QPU_QUBIT_NUM-1:0]           qiu_i_rs1  = {`QPU_QUBIT_NUM         {qiu_op}} & i_rs1[`QPU_QUBIT_NUM - 1 : 0];
  wire  [`QPU_QUBIT_NUM-1:0]           qiu_i_rs2  = {`QPU_QUBIT_NUM         {qiu_op}} & i_rs2[`QPU_QUBIT_NUM - 1 : 0];
  wire  [`QPU_XLEN-1:0]                qiu_i_imm  = {`QPU_XLEN              {qiu_op}} & i_imm;

  wire  [`QPU_DECINFO_WIDTH-1:0]  qiu_i_info =         {`QPU_DECINFO_WIDTH{qiu_op}}            & i_info;  
  wire  [`QPU_TIME_WIDTH - 1 : 0] qiu_i_clk  =         {`QPU_TIME_WIDTH   {(i_ntp & qiu_op)}}  & i_clk;
  wire  [`QPU_EVENT_WIRE_WIDTH - 1 : 0] qiu_i_edata  = {`QPU_EVENT_WIRE_WIDTH    {qiu_op}}     & i_edata;
  wire  [`QPU_EVENT_NUM - 1 : 0]  qiu_i_oprand =       {`QPU_EVENT_NUM    {qiu_op}}            & i_oprand;

  QPU_exu_alu_qiu u_QPU_exu_alu_qiu(

      .qiu_i_valid         (qiu_i_valid         ),
      .qiu_i_ready         (qiu_i_ready         ),
      .qiu_i_rs1           (qiu_i_rs1           ),
      .qiu_i_rs2           (qiu_i_rs2           ),
      .qiu_i_imm           (qiu_i_imm           ),


      .qiu_i_info          (qiu_i_info[`QPU_DECINFO_QIU_WIDTH-1:0]),
      .qiu_i_measure       (i_measure           ),
      .qiu_i_ntp           (i_ntp               ),
      .qiu_i_edata         (qiu_i_edata         ),
      .qiu_i_oprand        (qiu_i_oprand        ),
      .qiu_i_clk           (qiu_i_clk           ),


      .qiu_o_valid         (qiu_o_valid         ),
      .qiu_o_ready         (qiu_o_ready         ),

      .qiu_o_wbck_edata    (qiu_o_wbck_edata     ),
      .qiu_o_wbck_oprand   (qiu_o_wbck_oprand    ),
      .qiu_o_wbck_tdata    (qiu_o_wbck_tdata     ),

      .qiu_req_alu_op1     (qiu_req_alu_op1       ),
      .qiu_req_alu_op2     (qiu_req_alu_op2       ),
      .qiu_req_alu_res     (qiu_req_alu_res       )

  );


  //////////////////////////////////////////////////////////////
  // Instantiate the Shared Datapath module
  //
  wire alu_req_alu = alu_op;
  wire bjp_req_alu = bjp_op;
  wire lsu_req_alu = lsu_op;
  wire qiu_req_alu = qiu_op;

  QPU_exu_alu_dpath u_QPU_exu_alu_dpath(
      .alu_req_alu         (alu_req_alu           ),    
      .alu_req_alu_add     (alu_req_alu_add       ),
      .alu_req_alu_xor     (alu_req_alu_xor       ),
      .alu_req_alu_or      (alu_req_alu_or        ),
      .alu_req_alu_and     (alu_req_alu_and       ),
      .alu_req_alu_op1     (alu_req_alu_op1       ),
      .alu_req_alu_op2     (alu_req_alu_op2       ),
      .alu_req_alu_res     (alu_req_alu_res       ),
           
      .bjp_req_alu         (bjp_req_alu           ),
      .bjp_req_alu_op1     (bjp_req_alu_op1       ),
      .bjp_req_alu_op2     (bjp_req_alu_op2       ),
      .bjp_req_alu_cmp_eq  (bjp_req_alu_cmp_eq    ),
      .bjp_req_alu_cmp_ne  (bjp_req_alu_cmp_ne    ),
      .bjp_req_alu_cmp_lt  (bjp_req_alu_cmp_lt    ),
      .bjp_req_alu_cmp_gt  (bjp_req_alu_cmp_gt    ),
      .bjp_req_alu_cmp_res (bjp_req_alu_cmp_res   ),
             
      .lsu_req_alu         (lsu_req_alu           ),
      .lsu_req_alu_op1     (lsu_req_alu_op1       ),
      .lsu_req_alu_op2     (lsu_req_alu_op2       ),
      .lsu_req_alu_res     (lsu_req_alu_res       ),
             
      .qiu_req_alu         (qiu_req_alu           ),
      .qiu_req_alu_op1     (qiu_req_alu_op1       ),
      .qiu_req_alu_op2     (qiu_req_alu_op2       ),
      .qiu_req_alu_res     (qiu_req_alu_res       )

    );

  

  // Aribtrate the Result and generate output interfaces
  // 
  wire o_valid;
  wire o_ready;


  wire o_sel_alu = alu_op;
  wire o_sel_bjp = bjp_op;
  wire o_sel_lsu = lsu_op;
  wire o_sel_qiu = qiu_op;


  assign o_valid =     (o_sel_alu      & alu_o_valid     )
                     | (o_sel_bjp      & bjp_o_valid     )
                     | (o_sel_lsu      & lsu_o_valid     )
                     | (o_sel_qiu      & qiu_o_valid     )
                     ;

  assign alu_o_ready      = o_sel_alu & o_ready;
  assign lsu_o_ready      = o_sel_lsu & o_ready;
  assign bjp_o_ready      = o_sel_bjp & o_ready;
  assign qiu_o_ready      = o_sel_qiu & o_ready;

/////////////////////在这里，将alu_o_wbck_wdat根据ntp的值，分配给classical reg or time reg
  assign cwbck_o_data = ({`QPU_XLEN{(o_sel_alu & (~i_ntp) & (~i_rdidx[`QPU_RFIDX_REAL_WIDTH - 1]))}} & alu_o_wbck_cdata);
  assign twbck_o_data = ({`QPU_TIME_WIDTH{(o_sel_alu & i_ntp)}} & alu_o_wbck_cdata [`QPU_TIME_WIDTH - 1 : 0]) 
                      | ({`QPU_TIME_WIDTH{(o_sel_qiu & i_ntp)}} & qiu_o_wbck_tdata[`QPU_TIME_WIDTH - 1 : 0]);

  assign qcwbck_o_data = ({`QPU_XLEN{(o_sel_alu & (~i_ntp) & (i_rdidx[`QPU_RFIDX_REAL_WIDTH - 1]))}} & alu_o_wbck_cdata);

  assign ewbck_o_data = {`QPU_EVENT_WIRE_WIDTH{(o_sel_qiu)}} & qiu_o_wbck_edata;     
  assign ewbck_o_oprand = {`QPU_EVENT_NUM{(o_sel_qiu)}} & qiu_o_wbck_oprand;    
  assign cwbck_o_rdidx = i_rdidx; 
  assign qcwbck_o_rdidx = i_rdidx; 
  
  wire wbck_o_rdwen = i_rdwen;
                  

  //  Each Instruction need to commit or write-back
  //   * The write-back only needed when the unit need to write-back
  //     the result (need to write RD), and it is not a long-pipe uop
  //     (need to be write back by its long-pipe write-back, not here)
  //   * Each instruction need to be commited 
  wire o_need_cwbck  = wbck_o_rdwen & (~i_longpipe) & (~i_rdidx[`QPU_RFIDX_REAL_WIDTH - 1]);
  wire o_need_qcwbck = wbck_o_rdwen & (i_rdidx[`QPU_RFIDX_REAL_WIDTH - 1]);
  wire o_need_twbck = i_ntp;
  wire o_need_ewbck = o_sel_qiu;

  wire o_need_cmt  = 1'b1;

  assign o_ready = 
           (o_need_cmt  ? cmt_o_ready  : 1'b1)  
         & (  o_need_cwbck  ? cwbck_o_ready 
            : o_need_qcwbck ? qcwbck_o_ready
            : o_need_twbck  ? twbck_o_ready
            : o_need_ewbck  ? ewbck_o_ready
            : 1'b1
            ); 

  assign cwbck_o_valid = o_need_cwbck & o_valid & (o_need_cmt  ? cmt_o_ready  : 1'b1);
  assign qcwbck_o_valid = o_need_qcwbck & o_valid & (o_need_cmt  ? cmt_o_ready  : 1'b1);
  assign twbck_o_valid = o_need_twbck & o_valid & (o_need_cmt  ? cmt_o_ready  : 1'b1);
  assign ewbck_o_valid = o_need_ewbck & o_valid & (o_need_cmt  ? cmt_o_ready  : 1'b1);

  assign cmt_o_valid  = o_need_cmt  & o_valid 
                      & (  o_need_cwbck ? cwbck_o_ready 
                      :    o_need_twbck ? twbck_o_ready
                      :    o_need_ewbck ? ewbck_o_ready
                      :    1'b1
                         ); 
  // 
  //  The commint interface have some special signals
  assign cmt_o_pc   = i_pc;  
  assign cmt_o_imm  = i_imm;

 

  assign cmt_o_bjp         = o_sel_bjp;
  assign cmt_o_bjp_prdt    = o_sel_bjp & bjp_o_cmt_prdt;
  assign cmt_o_bjp_rslv    = o_sel_bjp & bjp_o_cmt_rslv;
  


endmodule                                      
                                               
                                               
                                               
