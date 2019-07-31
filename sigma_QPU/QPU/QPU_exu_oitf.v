                                                                       
                                                                       
//=====================================================================
// Designer   : QI ZHOU
//
// Description:
//  The OITF (Oustanding Instructions Track FIFO) to hold all the non-ALU long
//  pipeline instruction's status and information
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_oitf (
  
  //ready to accept new longpipe
  output dis_cf_ready,         //cf: classical fifo
  output dis_mf_ready,        //  mf : measurement fifo
 
  //need write in oitf
  input  dis_cl_ena,
  input  dis_qf_ena,          //qf : qubit flag which is used to distinguish which qubit is being measured
                              //ql : qubit list ,FMR and MEASURE instruction will sent the oprand to oitf module
                              //qubit flag and measurement fifo  push and pop at same time
   ///longwbck
  //remove signal
  input  ret_cl_ena,
  ///remove signal
  //mcu
  input  ret_qf_ena,

 

  //wbct info
  output [`QPU_RFIDX_REAL_WIDTH-1:0] ret_rdidx,
  output ret_rdwen,

  //qbwbck info
  output [`QPU_QUBIT_NUM - 1 : 0] ret_mf,      ///ret_measurement fifo
  

  //disp instr info
  input  disp_i_rs1en,
  input  disp_i_rs2en,
  input  disp_i_rdwen,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rs1idx,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rs2idx,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rdidx,
  
  input disp_i_qfren,                                 //only FMR and MEASURE will read qubit flag
  input [`QPU_QUBIT_NUM - 1 : 0] disp_i_ql,

  //disp dep
  output oitfrd_match_disprs1,
  output oitfrd_match_disprs2,
  output oitfrd_match_disprd,
  
  output oitfqf_match_dispql,

  output oitf_empty,
  output moitf_empty,
  
  input  clk,
  input  rst_n

);

  wire alc_ptr_ena = dis_cl_ena;
  wire ret_ptr_ena = ret_cl_ena;

  wire qalc_ptr_ena = dis_qf_ena;
  wire qret_ptr_ena = ret_qf_ena;

  wire oitf_full ;

  wire [`QPU_ITAG_WIDTH-1:0] ret_ptr;
  wire [`QPU_ITAG_WIDTH-1:0] dis_ptr;
  
  wire [`QPU_ITAG_WIDTH-1:0] alc_ptr_r;
  wire [`QPU_ITAG_WIDTH-1:0] ret_ptr_r;


  generate
  if(`QPU_OITF_DEPTH > 1) begin
      wire alc_ptr_flg_r;
      wire alc_ptr_flg_nxt = ~alc_ptr_flg_r;
      wire alc_ptr_flg_ena = (alc_ptr_r == ($unsigned(`QPU_OITF_DEPTH-1))) & alc_ptr_ena;
      
      sirv_gnrl_dfflr #(1) alc_ptr_flg_dfflr(alc_ptr_flg_ena, alc_ptr_flg_nxt, alc_ptr_flg_r, clk, rst_n);
      
      wire [`QPU_ITAG_WIDTH-1:0] alc_ptr_nxt; 
      
      assign alc_ptr_nxt = alc_ptr_flg_ena ? `QPU_ITAG_WIDTH'b0 : (alc_ptr_r + 1'b1);
      
      sirv_gnrl_dfflr #(`QPU_ITAG_WIDTH) alc_ptr_dfflr(alc_ptr_ena, alc_ptr_nxt, alc_ptr_r, clk, rst_n);
      
      
      wire ret_ptr_flg_r;
      wire ret_ptr_flg_nxt = ~ret_ptr_flg_r;
      wire ret_ptr_flg_ena = (ret_ptr_r == ($unsigned(`QPU_OITF_DEPTH-1))) & ret_ptr_ena;
      
      sirv_gnrl_dfflr #(1) ret_ptr_flg_dfflr(ret_ptr_flg_ena, ret_ptr_flg_nxt, ret_ptr_flg_r, clk, rst_n);
      
      wire [`QPU_ITAG_WIDTH-1:0] ret_ptr_nxt; 
      
      assign ret_ptr_nxt = ret_ptr_flg_ena ? `QPU_ITAG_WIDTH'b0 : (ret_ptr_r + 1'b1);

      sirv_gnrl_dfflr #(`QPU_ITAG_WIDTH) ret_ptr_dfflr(ret_ptr_ena, ret_ptr_nxt, ret_ptr_r, clk, rst_n);

      assign oitf_empty = (ret_ptr_r == alc_ptr_r) &   (ret_ptr_flg_r == alc_ptr_flg_r);
      assign oitf_full  = (ret_ptr_r == alc_ptr_r) & (~(ret_ptr_flg_r == alc_ptr_flg_r));
  end//}
  else begin: depth_eq1//}{
      assign alc_ptr_r =1'b0;
      assign ret_ptr_r =1'b0;
      assign oitf_full  = vld_r[0];
      assign oitf_empty = ~vld_r[0];

  end//}
  endgenerate//}

  assign ret_ptr = ret_ptr_r;
  assign dis_ptr = alc_ptr_r;

 //// 
 //// // If the OITF is not full, or it is under retiring, then it is ready to accept new dispatch
 //// assign dis_ready = (~oitf_full) | ret_ena;
 // To cut down the loop between ALU write-back valid --> oitf_ret_ena --> oitf_ready ---> dispatch_ready --- > alu_i_valid
 //   we exclude the ret_ena from the ready signal
  assign dis_cf_ready = (~oitf_full);
  
  wire [`QPU_OITF_DEPTH-1:0] rd_match_rs1idx;
  wire [`QPU_OITF_DEPTH-1:0] rd_match_rs2idx;
  wire [`QPU_OITF_DEPTH-1:0] rd_match_rdidx;

  wire [`QPU_OITF_DEPTH-1:0] vld_set;
  wire [`QPU_OITF_DEPTH-1:0] vld_clr;
  wire [`QPU_OITF_DEPTH-1:0] vld_ena;
  wire [`QPU_OITF_DEPTH-1:0] vld_nxt;
  wire [`QPU_OITF_DEPTH-1:0] vld_r;
  wire [`QPU_OITF_DEPTH-1:0] rdwen_r;
  wire [`QPU_RFIDX_REAL_WIDTH-1:0] rdidx_r[`QPU_OITF_DEPTH-1:0];

  genvar i;
  generate //{
      for (i=0; i<`QPU_OITF_DEPTH; i=i+1) begin:oitf_entries//{
  
        assign vld_set[i] = alc_ptr_ena & (alc_ptr_r == i);
        assign vld_clr[i] = ret_ptr_ena & (ret_ptr_r == i);
        assign vld_ena[i] = vld_set[i] |   vld_clr[i];
        assign vld_nxt[i] = vld_set[i] | (~vld_clr[i]);
  
        sirv_gnrl_dfflr #(1) vld_dfflr(vld_ena[i], vld_nxt[i], vld_r[i], clk, rst_n);
        //Payload only set, no need to clear
        sirv_gnrl_dffl #(`QPU_RFIDX_REAL_WIDTH) rdidx_dffl(vld_set[i], disp_i_rdidx, rdidx_r[i], clk);
        sirv_gnrl_dffl #(1)                 rdwen_dffl(vld_set[i], disp_i_rdwen, rdwen_r[i], clk);

        assign rd_match_rs1idx[i] = vld_r[i] & rdwen_r[i] & disp_i_rs1en & (rdidx_r[i] == disp_i_rs1idx);
        assign rd_match_rs2idx[i] = vld_r[i] & rdwen_r[i] & disp_i_rs2en & (rdidx_r[i] == disp_i_rs2idx);
        assign rd_match_rdidx [i] = vld_r[i] & rdwen_r[i] & disp_i_rdwen & (rdidx_r[i] == disp_i_rdidx );
  
      end//}
  endgenerate//}

  assign oitfrd_match_disprs1 = |rd_match_rs1idx;
  assign oitfrd_match_disprs2 = |rd_match_rs2idx;
  assign oitfrd_match_disprd  = |rd_match_rdidx ;

  assign ret_rdidx = rdidx_r[ret_ptr];
  assign ret_rdwen = rdwen_r[ret_ptr];

  //////////////////measure list is a standard FIFO which cut ready=1 ,for the ret signal can be asserted at any time. This may cause the timing problem/////////////////
  wire fifo_i_vld;
  wire fifo_i_rdy;
  wire [`QPU_QUBIT_NUM - 1 : 0] fifo_i_dat;
  wire fifo_o_vld;
  wire fifo_o_rdy;
  wire [`QPU_QUBIT_NUM - 1 : 0] fifo_o_dat;

  assign fifo_i_vld             = dis_qf_ena;
  assign dis_mf_ready = fifo_i_rdy;
  assign fifo_i_dat            = disp_i_ql;
  assign fifo_o_rdy             = ret_qf_ena;
  assign ret_mf       = fifo_o_dat;
  assign moitf_empty = fifo_o_vld;

  sirv_gnrl_fifo # (
        .CUT_READY(1), 
        .MSKO(0),
        .DP(`QPU_MOITF_DEPTH),
        .DW(`QPU_QUBIT_NUM)
  ) measure_qubitlist_fifo(
      .i_vld   (fifo_i_vld),
      .i_rdy   (fifo_i_rdy),
      .i_dat   (fifo_i_dat),
      .o_vld   (fifo_o_vld),
      .o_rdy   (fifo_o_rdy),
      .o_dat   (fifo_o_dat),
      .clk     (clk  ),
      .rst_n   (rst_n)
    );

   ///////////qubitflag can be modify by dis and ret instr/////////
    wire [`QPU_QUBIT_NUM - 1 : 0] qf_set;
    wire [`QPU_QUBIT_NUM - 1 : 0] qf_clr;
    wire [`QPU_QUBIT_NUM - 1 : 0] qf_ena;
    wire [`QPU_QUBIT_NUM - 1 : 0] qf_nxt;
    wire [`QPU_QUBIT_NUM - 1 : 0] qf_r;
    wire [`QPU_QUBIT_NUM - 1 : 0] qf_match_ql;    
    
    
    
    genvar j;
    generate //{
      for (j=0; j<`QPU_QUBIT_NUM; j=j+1) begin
  
        assign qf_set[j] = qalc_ptr_ena;
        assign qf_clr[j] = qret_ptr_ena;
        assign qf_ena[j] = qf_set[j]   |   qf_clr[j];
        assign qf_nxt[j] = qf_set[j] & (qf_r[j] | disp_i_ql[j] )
                         | qf_clr[j] & (qf_r[j] & (~ret_mf[j]) );
  
        sirv_gnrl_dfflr #(1) qf_dfflr(qf_ena[j], qf_nxt[j], qf_r[j], clk, rst_n);
        
        assign qf_match_ql[j] = qf_r[j] & disp_i_ql[j] & disp_i_qfren;
      end//}
  endgenerate//}
    assign oitfqf_match_dispql = | qf_match_ql ;


endmodule


