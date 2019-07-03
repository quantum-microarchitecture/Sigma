                                                                        
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  The decode module to decode the instruction details
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_decode(

  //////////////////////////////////////////////////////////////
  // The IR stage to Decoder
  input  [`QPU_INSTR_SIZE-1:0] i_instr,
  input  [`QPU_PC_SIZE-1:0] i_pc,
  input  i_prdt_taken, 
  
  //////////////////////////////////////////////////////////////
  // The Decoded Info-Bus

  output dec_rs1x0,
  output dec_rs2x0,
  output dec_rs1en,
  output dec_rs2en,
  output dec_rdwen,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rs1idx,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rs2idx,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] dec_rdidx,
  output [`QPU_DECINFO_WIDTH-1:0] dec_info,  
  output [`QPU_XLEN-1:0] dec_imm,
  output [`QPU_PC_SIZE-1:0] dec_pc,  
  
  //Quantum instruction decode
  output dec_new_timepoint,
  output dec_need_qubitflag,
  output dec_measure,
  output dec_fmr,
  output dec_tqg,                 //two_qubit_gate
  //Branch instruction decode
  output dec_bxx,
  output [`QPU_XLEN-1:0] dec_bjp_imm
  );



  wire [32-1:0] qpu_instr = i_instr;
  wire quantum_instr = qpu_instr[0];
  wire classical_instr = ~ qpu_instr[0];

  wire [4:0]  classical_opcode = qpu_instr[4:0];

  wire opcode_2_0_000  = (classical_opcode[2:0] == 3'b000);
  wire opcode_2_0_010  = (classical_opcode[2:0] == 3'b010);
  wire opcode_2_0_100  = (classical_opcode[2:0] == 3'b100);
  wire opcode_2_0_110  = (classical_opcode[2:0] == 3'b110);

  wire [4:0]  classical_rd     = qpu_instr[9:5];
  wire [2:0]  classical_func3  = qpu_instr[31:29];
  wire [4:0]  classical_rs1    = qpu_instr[14:10];
  wire [4:0]  classical_rs2    = qpu_instr[28:24];

  wire [8:0] quantum_opcode1 = qpu_instr[9:1];
  wire [8:0] quantum_opcode2 = qpu_instr[23:15];
  wire [4:0] quantum_rs1 = qpu_instr[14:10];
  wire [4:0] quantum_rs2 = qpu_instr[28:24];
  wire [2:0] quantum_PI = qpu_instr[31:29];
 
  wire opcode_4_3_00 = (classical_opcode[4:3] == 2'b00);
  wire opcode_4_3_01 = (classical_opcode[4:3] == 2'b01);
  wire opcode_4_3_10 = (classical_opcode[4:3] == 2'b10);
  wire opcode_4_3_11 = (classical_opcode[4:3] == 2'b11);
  


  wire classical_func3_000 = (classical_func3 == 3'b000);
  wire classical_func3_001 = (classical_func3 == 3'b001);
  wire classical_func3_010 = (classical_func3 == 3'b010);
  wire classical_func3_011 = (classical_func3 == 3'b011);
  wire classical_func3_100 = (classical_func3 == 3'b100);

  wire classical_rs1_x0 = (classical_rs1 == 5'b00000);
  wire classical_rs2_x0 = (classical_rs2 == 5'b00000);
  wire classical_rd_x0  = (classical_rd  == 5'b00000);
  wire quantum_rs2_x0 =   (quantum_rs2   == 5'b00000);

  wire classical_load   = opcode_4_3_00 & opcode_2_0_000; 
  wire classical_store  = opcode_4_3_01 & opcode_2_0_000; 
  wire classical_branch = opcode_4_3_11 & opcode_2_0_000; 


  wire classical_op_imm   = opcode_4_3_00 & opcode_2_0_010; 
  wire classical_op       = opcode_4_3_01 & opcode_2_0_010; 
  wire classical_qwait    = opcode_4_3_10 & opcode_2_0_010;
  wire classical_fmr      = opcode_4_3_11 & opcode_2_0_010;



  wire classical_smis = opcode_4_3_00 & opcode_2_0_110;


  wire quantum_single_opcode = quantum_instr & (quantum_opcode2 == 9'b000000000);
  wire quantum_measure       = quantum_instr & (quantum_opcode1 == 9'b111111111);
  // ===========================================================================
  // Branch Instructions
  wire classical_beq      = classical_branch & classical_func3_000;
  wire classical_bne      = classical_branch & classical_func3_001;
  wire classical_blt      = classical_branch & classical_func3_010;
  wire classical_bgt      = classical_branch & classical_func3_011;

  // ===========================================================================
  // The Branch instructions will be handled by BJP
  wire dec_bjp     = classical_branch;
  wire bjp_op = dec_bjp;

  wire [`QPU_DECINFO_BJP_WIDTH-1:0] bjp_info_bus;

  assign bjp_info_bus[`QPU_DECINFO_GRP    ]    = `QPU_DECINFO_GRP_BJP;
  assign bjp_info_bus[`QPU_DECINFO_BJP_BPRDT]  = i_prdt_taken;
  assign bjp_info_bus[`QPU_DECINFO_BJP_BEQ  ]  = classical_beq;
  assign bjp_info_bus[`QPU_DECINFO_BJP_BNE  ]  = classical_bne;
  assign bjp_info_bus[`QPU_DECINFO_BJP_BLT  ]  = classical_blt; 
  assign bjp_info_bus[`QPU_DECINFO_BJP_BGT  ]  = classical_bgt;

  // ===========================================================================
  // ALU Instructions
  wire classical_addi     = classical_op_imm & classical_func3_000;
  wire classical_xori     = classical_op_imm & classical_func3_001;
  wire classical_ori      = classical_op_imm & classical_func3_010;
  wire classical_andi     = classical_op_imm & classical_func3_011;

  wire classical_add      = classical_op     & classical_func3_000;
  wire classical_sub      = classical_op     & classical_func3_100;
  wire classical_xor      = classical_op     & classical_func3_001;
  wire classical_or       = classical_op     & classical_func3_010;
  wire classical_and      = classical_op     & classical_func3_011;


  wire alu_op = classical_op_imm 
              | classical_op 
              | classical_fmr
              | classical_qwait
              | classical_smis
              ;

  wire need_imm;
  wire [`QPU_DECINFO_ALU_WIDTH-1:0] alu_info_bus;
  assign alu_info_bus[`QPU_DECINFO_GRP    ]    = `QPU_DECINFO_GRP_ALU;
  assign alu_info_bus[`QPU_DECINFO_ALU_ADD]    = classical_add  | classical_addi; 
  assign alu_info_bus[`QPU_DECINFO_ALU_SUB]    = classical_sub;
  assign alu_info_bus[`QPU_DECINFO_ALU_XOR]    = classical_xor  | classical_xori;       
  assign alu_info_bus[`QPU_DECINFO_ALU_OR ]    = classical_or   | classical_ori;     
  assign alu_info_bus[`QPU_DECINFO_ALU_AND]    = classical_and  | classical_andi;
  assign alu_info_bus[`QPU_DECINFO_ALU_SMIS]  = classical_smis; 
  assign alu_info_bus[`QPU_DECINFO_ALU_FMR]    = classical_fmr; 
  assign alu_info_bus[`QPU_DECINFO_ALU_QWAIT]  = classical_qwait;
  
  assign alu_info_bus[`QPU_DECINFO_ALU_OP2IMM] = need_imm; 
  

  
  // ===========================================================================
  // Load/Store Instructions
  wire lsu_op = classical_load | classical_store;
  wire [`QPU_DECINFO_LSU_WIDTH-1:0] lsu_info_bus;
  assign lsu_info_bus[`QPU_DECINFO_GRP    ] = `QPU_DECINFO_GRP_LSU;
  assign lsu_info_bus[`QPU_DECINFO_LSU_LOAD   ] = classical_load;
  assign lsu_info_bus[`QPU_DECINFO_LSU_STORE  ] = classical_store;


  // ===========================================================================
  // quantum Instructions
  wire qiu_op = quantum_instr;
  wire [`QPU_DECINFO_QIU_WIDTH-1:0] qiu_info_bus;
  assign qiu_info_bus[`QPU_DECINFO_GRP    ] = `QPU_DECINFO_GRP_QIU;
  assign qiu_info_bus[`QPU_DECINFO_QIU_OPCODE1  ] = quantum_opcode1;
  assign qiu_info_bus[`QPU_DECINFO_QIU_OPCODE2  ] = quantum_opcode2;


  // All the instruction need RD register except the
  //   classical instruction: 
  //   * Branch, Store,qwait
  //   and all quantum instruction  
  wire qpu_need_rd = (~classical_rd_x0) &
                   (
                     (~classical_branch) 
                   & (~classical_store)
                   & (~classical_qwait)
                   & (~quantum_instr)
                   ) ;

  // All the instruction need RS1 register except the
  //   * qwait
  //   * smist
  // when rs1/rs2_x0=1,disp module will not access the register,just use mask to output rs1/rs2
  wire qpu_need_rs1 = (~classical_rs1_x0) &
                    (
                      (~classical_qwait)
                    & (~classical_smis)
                    );
                    
  // Following instructions need RS2 register
  //   * branch
  //   * store
  //   * op
  //   * fmr
  //   * quantum instruction & exist the second quantum operate
  wire qpu_need_rs2 = (~classical_rs2_x0) & (
                    (
                      (classical_branch)
                    | (classical_store)
                    | (classical_op)
                    | (classical_fmr)
                    )  
                |  
                      (quantum_instr) & (~quantum_single_opcode)
                    );


  wire [31:0]  qpu_i_imm = { 
                               {18{qpu_instr[28]}} 
                              , qpu_instr[28:15]
                             };

  wire [31:0]  qpu_l_imm = { 
                               {15{qpu_instr[31]}}
                              , qpu_instr[31:29] 
                              , qpu_instr[28:15]
                             };                                

  wire [31:0]  qpu_s_imm = {
                               {15{qpu_instr[31]}}
                              , qpu_instr[31:29] 
                              , qpu_instr[9:5] 
                              , qpu_instr[23:15]
                             };

//the last two bits of address is is always 00，so the last two bits of the imm of branch instruction is end up with the second bit  
  wire [31:0]  qpu_b_imm = {
                               {17{qpu_instr[9]}} 
                              , qpu_instr[9:5] 
                              , qpu_instr[23:15]
                              };
//QWAIT instruction
  wire [31:0]  qpu_w_imm = {
                               {5{qpu_instr[31]}} 
                              , qpu_instr[31:29]
                              , qpu_instr[9:5] 
                              , qpu_instr[28:24]
                              , qpu_instr[14:10]
                              , qpu_instr[23:15]
                              };
//SMTST instruction
  wire [31:0]  qpu_m_imm = {
                               {10{qpu_instr[31]}} 
                              , qpu_instr[31:24]
                              , qpu_instr[14:10] 
                              , qpu_instr[23:15]
                              };
//Quantum instruction
  wire [31:0]  qpu_q_imm = {
                               {29'b0} 
                              , quantum_PI
                              };

                   // It will select i-type immediate when
                   //    * classical_op_imm
                

  wire qpu_imm_sel_i = classical_op_imm;


                   // It will select w-type immediate when
                   //    * classical_qwait 
  wire qpu_imm_sel_w = classical_qwait;

                   // It will select m-type immediate when
                   //    * classical_smist
  wire qpu_imm_sel_m = classical_smis;

                   // It will select b-type immediate when
                   //    * classical_branch
  wire qpu_imm_sel_b = classical_branch;


                   // It will select s-type immediate when
                   //    * classical_store
  wire qpu_imm_sel_s = classical_store;
  
                   // It will select l-type immediate when
                   //    * qpu_load
  wire qpu_imm_sel_l = classical_load;
                   
                   // It will select q-type immediate when
                   //    * quantum_instr

  wire qpu_imm_sel_q = quantum_instr;


  wire [31:0]  qpu_imm = 
                     ({32{qpu_imm_sel_i}} & qpu_i_imm)
                   | ({32{qpu_imm_sel_s}} & qpu_s_imm)
                   | ({32{qpu_imm_sel_b}} & qpu_b_imm)
                   | ({32{qpu_imm_sel_m}} & qpu_m_imm)
                   | ({32{qpu_imm_sel_w}} & qpu_w_imm)
                   | ({32{qpu_imm_sel_q}} & qpu_q_imm)
                   ;
                   
  wire  qpu_need_imm = 
                     qpu_imm_sel_i
                   | qpu_imm_sel_s
                   | qpu_imm_sel_b
                   | qpu_imm_sel_m
                   | qpu_imm_sel_w
                   | qpu_imm_sel_q
                   ;


  assign need_imm = qpu_need_imm; 
  assign dec_imm = qpu_imm;

  assign dec_pc  = i_pc;

  

  assign dec_info = 
              ({`QPU_DECINFO_WIDTH{alu_op}}     & {{`QPU_DECINFO_WIDTH-`QPU_DECINFO_ALU_WIDTH{1'b0}},alu_info_bus})
            | ({`QPU_DECINFO_WIDTH{lsu_op}}     & {{`QPU_DECINFO_WIDTH-`QPU_DECINFO_LSU_WIDTH{1'b0}},lsu_info_bus})
            | ({`QPU_DECINFO_WIDTH{bjp_op}}     & {{`QPU_DECINFO_WIDTH-`QPU_DECINFO_BJP_WIDTH{1'b0}},bjp_info_bus})
            | ({`QPU_DECINFO_WIDTH{qiu_op}}     & {{`QPU_DECINFO_WIDTH-`QPU_DECINFO_QIU_WIDTH{1'b0}},qiu_info_bus})
              ;





assign dec_rs1idx = {{(classical_fmr | quantum_instr)}, classical_rs1[`QPU_RFIDX_WIDTH-1:0]};
assign dec_rs2idx = {{quantum_instr }, classical_rs2[`QPU_RFIDX_WIDTH-1:0]}; 
assign dec_rdidx = {{classical_smis}, classical_rd [`QPU_RFIDX_WIDTH-1:0]}; 

  assign dec_rs1en = qpu_need_rs1; 
  assign dec_rs2en = qpu_need_rs2;
  assign dec_rdwen = qpu_need_rd;

  //only assert when it is classical instruction
  assign dec_rs1x0 = classical_rs1_x0 & classical_instr;             
  assign dec_rs2x0 = (classical_rs2_x0 & classical_instr) | (quantum_rs2_x0 & quantum_instr);
                     
  assign dec_bxx = bjp_op;
  assign dec_bjp_imm = qpu_b_imm;

  wire PI_IS_0 = (quantum_PI == 3'b0);
  assign dec_new_timepoint = classical_qwait | (quantum_instr & ~(PI_IS_0));
  assign dec_need_qubitflag = quantum_measure | classical_fmr;
  assign dec_measure = quantum_measure;
  assign dec_fmr = dec_need_qubitflag & (~dec_measure);
  assign dec_tqg = qiu_op & ((quantum_opcode1 & `QPU_QUANTUM_TWO_QUBIT_GATE_BOUNDARY) ==`QPU_QUANTUM_TWO_QUBIT_GATE_BOUNDARY) & (~dec_measure);

endmodule                                      
                                               
                                               
                                               
