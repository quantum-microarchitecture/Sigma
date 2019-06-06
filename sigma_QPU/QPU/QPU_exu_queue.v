                                                           
                                                                         
                                                                         
//=====================================================================
// Designer   : QI ZHOU
//
// Description:
//  The Regfile module to implement the core's general purpose registers file
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_queue(


//time queue
  input  tiq_dest_wen,               ///npt & event time  not full     //from wbck
  output tiq_dest_i_ready,           ///time fifo is not full            to wbck
  input  [`QPU_TIME_WIDTH - 1 : 0] tiq_dest_i_data,   ///from wbck module

//tragger clk
  output tragger_o_clk_ena,
  input [`QPU_TIME_WIDTH - 1 : 0] tragger_o_clk,

//event queue
  input  evq_dest_wen,              ///ntp & event time not full  from wbck
  output evq_dest_i_ready,          //event fifo is not full   ,  to wbck
  input [(`QPU_EVENT_NUM - 1) : 0] evq_dest_oprand,                  ///From event reg
  input [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] evq_dest_data,             ///From event reg

  output [`QPU_EVENT_NUM - 1: 0] evq_dest_o_valid,         //输出的事件是否有效 to tragger
  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] evq_dest_o_data,  //                 to tragger

  input [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_zero,   ///做快反馈控制
  input [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_one , 
  input [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_equ ,

  input  clk,
  input  rst_n
  );


  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///there is one data (16'b0) in time_fifo when it is reset,and time fifo will never be empty! when it will be empty, the clock will stop!
  //////////////////time_queue

  wire time_queue_full;
  wire time_queue_one_left;
  
  wire time_fifo_o_data;
  wire time_fifo_i_data;

  assign time_fifo_i_data = tiq_dest_i_data;
  assign tiq_dest_i_ready = time_queue_full;


  genvar i;
  generate 

    // FIFO registers
    wire [`QPU_TIME_WIDTH - 1 : 0] time_fifo_rf_r [`QPU_TIME_QUEUE_DEPTH - 1 : 0];
    wire [`QPU_TIME_QUEUE_DEPTH - 1 : 0] time_fifo_rf_en;

    // read/write enable
    wire tiq_wen = tiq_dest_wen;
    wire tiq_o_valid = (tragger_i_clk == time_fifo_o_data) ;          ///有用信号！
    wire tiq_o_ready = ((time_queue_one_left & tiq_dest_wen) | (~time_queue_one_left));
    wire tiq_ren =  tiq_o_valid &  tiq_o_ready;

    assign tragger_o_clk_ena =  tiq_o_valid ? ((time_queue_one_left & tiq_wen) | (~time_queue_one_left))  :  1'b1;
    
    ///////// Read-Pointer and Write-Pointer
    wire [`QPU_TIME_QUEUE_DEPTH - 1 : 0] time_rptr_vec_nxt; 
    wire [`QPU_TIME_QUEUE_DEPTH - 1 : 0] time_rptr_vec_r;
    wire [`QPU_TIME_QUEUE_DEPTH - 1 : 0] time_wptr_vec_nxt; 
    wire [`QPU_TIME_QUEUE_DEPTH - 1 : 0] time_wptr_vec_r;

   
 
    assign time_rptr_vec_nxt = time_rptr_vec_r[`QPU_TIME_QUEUE_DEPTH-1] ? {{(`QPU_TIME_QUEUE_DEPTH-1){1'b0}}, 1'b1} : (time_rptr_vec_r << 1);
    assign time_wptr_vec_nxt = time_wptr_vec_r[`QPU_TIME_QUEUE_DEPTH-1] ? {{(`QPU_TIME_QUEUE_DEPTH-1){1'b0}}, 1'b1} : (time_wptr_vec_r << 1);
    
    //for time_wptr,default data is 000010,for rptr,default data is 000001

    sirv_gnrl_dfflrs #(1)    time_rptr_vec_0_dfflrs  (tiq_ren, time_rptr_vec_nxt[0]     , time_rptr_vec_r[0]     , clk, rst_n);
    sirv_gnrl_dfflrs #(1)    time_wptr_vec_0_dfflr   (tiq_wen, time_wptr_vec_nxt[0]     , time_wptr_vec_r[0]     , clk, rst_n);
    
    sirv_gnrl_dfflrs #(1)    time_rptr_vec_1_dfflr   (tiq_ren, time_rptr_vec_nxt[1]     , time_rptr_vec_r[1]     , clk, rst_n);
    sirv_gnrl_dfflrs #(1)    time_wptr_vec_1_dfflrs  (tiq_wen, time_wptr_vec_nxt[1]     , time_wptr_vec_r[1]     , clk, rst_n);  
    
    sirv_gnrl_dfflr  #(`QPU_TIME_QUEUE_DEPTH-2) time_rptr_vec_30_dfflr  (tiq_ren, time_rptr_vec_nxt[`QPU_TIME_QUEUE_DEPTH-1:2], rptr_vec_r[`QPU_TIME_QUEUE_DEPTH-1:2], clk, rst_n);
    sirv_gnrl_dfflr  #(`QPU_TIME_QUEUE_DEPTH-2) time_wptr_vec_30_dfflr  (tiq_wen, time_wptr_vec_nxt[`QPU_TIME_QUEUE_DEPTH-1:2], wptr_vec_r[`QPU_TIME_QUEUE_DEPTH-1:2], clk, rst_n);


    ////////////////
    ///////// Vec register to easy full and empty and the o_vld generation with flop-clean
    wire [`QPU_TIME_QUEUE_DEPTH:0] time_i_vec;
    wire [`QPU_TIME_QUEUE_DEPTH:0] time_o_vec;
    wire [`QPU_TIME_QUEUE_DEPTH:0] time_vec_nxt; 
    wire [`QPU_TIME_QUEUE_DEPTH:0] time_vec_r;

    wire time_vec_en = (tiq_ren ^ tiq_wen ); //if writing and reading the fifo at same time, the available fifo number remains the same!
    assign time_vec_nxt = tiq_wen ? {time_vec_r[`QPU_TIME_QUEUE_DEPTH - 1 : 0], 1'b1} : (time_vec_r >> 1);  
    
    ////////there is one data in fifo when it is reset,so the vec_en= 0000011;
    sirv_gnrl_dfflrs #(2)                         time_vec_1_0_dfflrs     (time_vec_en, time_vec_nxt[1:0]                    , time_vec_r[1:0]                    ,     clk, rst_n);
    sirv_gnrl_dfflr  #(`QPU_TIME_QUEUE_DEPTH - 1) time_vec_30_dfflr       (time_vec_en, time_vec_nxt[`QPU_TIME_QUEUE_DEPTH:2], time_vec_r[`QPU_TIME_QUEUE_DEPTH:2],     clk, rst_n);
    
    assign time_i_vec = {1'b0,time_vec_r[`QPU_TIME_QUEUE_DEPTH : 1]};
    assign time_o_vec = {1'b0,time_vec_r[`QPU_TIME_QUEUE_DEPTH : 1]};



    ///////// write fifo
    for (i=0; i<`QPU_TIME_QUEUE_DEPTH; i=i+1) begin:time_fifo_rf//{
      
      assign time_fifo_rf_en[i] = tiq_wen & time_wptr_vec_r[i];
      
      if(i ==0) begin :fifo_0
        sirv_gnrl_dfflrs  #(`QPU_TIME_QUEUE_DEPTH) fifo_rf_dfflrs (time_fifo_rf_en[i], time_fifo_i_data, time_fifo_rf_r[i], clk,rst_n);
      end
      else begin : fifo_gt0
        sirv_gnrl_dffl  #(`QPU_TIME_QUEUE_DEPTH) fifo_rf_dffl   (time_fifo_rf_en[i], time_fifo_i_data, fifo_rf_r[i], clk);
      end
        
    end//}

    /////////One-Hot Mux as the read path
    
    integer j;
    reg [`QPU_TIME_WIDTH - 1 : 0] time_mux_rdata;
    always @*
    begin : rd_port_PROC//{
      time_mux_rdata = {`QPU_TIME_WIDTH{1'b0}};
      for(j=0; j<`QPU_TIME_QUEUE_DEPTH; j=j+1) begin
        time_mux_rdata = time_mux_rdata | ({`QPU_TIME_WIDTH{time_rptr_vec_r[j]}} & time_fifo_rf_r[j]);
      end
    end//}
    
    assign time_fifo_o_data = time_mux_rdata;

    
    // o_vld as flop-clean
    assign time_queue_one_left = (time_o_vec[1:0] == 2'b01);
    assign time_queue_full = time_i_vec[`QPU_TIME_QUEUE_DEPTH-1];       ///有用信号！
       
  endgenerate//}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///ret and dis ptr register

  wire evq_dis_ptr_ena,
  wire [`QPU_EVENT_PTR_WIDTH - 1 : 0] evq_dis_ptr_r,
  wire [`QPU_EVENT_PTR_WIDTH - 1 : 0] evq_dis_ptr_nxt,

  wire evq_ret_ptr_ena,
  wire [`QPU_EVENT_PTR_WIDTH - 1 : 0] evq_ret_ptr_r,
  wire [`QPU_EVENT_PTR_WIDTH - 1 : 0] evq_ret_ptr_nxt,

  assign evq_dis_ptr_nxt = (evq_dis_ptr_r == {(`QPU_EVENT_PTR_WIDTH){1'b1}}) ? {(`QPU_EVENT_PTR_WIDTH){1'b0}} : (evq_dis_ptr_r + `QPU_EVENT_PTR_WIDTH'b1);
  assign evq_ret_ptr_nxt = (evq_ret_ptr_r == {(`QPU_EVENT_PTR_WIDTH){1'b1}}) ? {(`QPU_EVENT_PTR_WIDTH){1'b0}} : (evq_ret_ptr_r + `QPU_EVENT_PTR_WIDTH'b1);

  assign evq_dis_ptr_ena = tiq_wen;
  assign evq_ret_ptr_ena = tiq_ren;

  sirv_gnrl_dfflrs #(1)    evq_dis_ptr_0_dfflrs   (evq_dis_ptr_ena, evq_dis_ptr_nxt[0]     , evq_dis_ptr_r[0]     , clk, rst_n);
  sirv_gnrl_dfflrs #(1)    evq_ret_ptr_0_dfflrs   (evq_ret_ptr_ena, evq_ret_ptr_nxt[0]     , evq_ret_ptr_r[0]     , clk, rst_n)
  
  sirv_gnrl_dfflr  #(`QPU_EVENT_PTR_WIDTH - 1) evq_dis_ptr_31_dfflr  (evq_dis_ptr_ena, evq_dis_ptr_nxt[`QPU_EVENT_PTR_WIDTH - 1 : 1], evq_dis_ptr_r[`QPU_EVENT_PTR_WIDTH - 1 : 1], clk, rst_n);
  sirv_gnrl_dfflr  #(`QPU_EVENT_PTR_WIDTH - 1) evq_ret_ptr_31_dfflr  (evq_ret_ptr_ena, evq_ret_ptr_nxt[`QPU_EVENT_PTR_WIDTH - 1 : 1], evq_ret_ptr_r[`QPU_EVENT_PTR_WIDTH - 1 : 1], clk, rst_n);




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///event_queue


  wire event_queue_full;          
  wire event_queue_empty;



  wire [`QPU_EVENT_NUM - 1 : 0] evq_fifo_i_valid;
  wire [`QPU_EVENT_NUM - 1 : 0] evq_fifo_i_ready;         
  wire [`QPU_EVENT_NUM - 1 : 0] evq_fifo_o_valid;          
  wire [`QPU_EVENT_NUM - 1 : 0] evq_fifo_o_ready;
  wire [`QPU_QI_EVENT_QUEUE_WIDTH - 1 : 0] evq_qi_fifo_i_data [`QPU_QI_EVENT_NUM - 1 : 0];
  wire [`QPU_QI_EVENT_QUEUE_WIDTH - 1 : 0] evq_qi_fifo_o_data [`QPU_QI_EVENT_NUM - 1 : 0];
  wire [`QPU_QI_EVENT_QUEUE_WIDTH - 1 : 0] evq_qi_fifo_o_data_pre [`QPU_QI_EVENT_NUM - 1 : 0];
  wire [`QPU_MEASURE_EVENT_QUEUE_WIDTH - 1 : 0] evq_measure_fifo_i_data [`QPU_MEASURE_EVENT_NUM - 1 : 0];
  wire [`QPU_MEASURE_EVENT_QUEUE_WIDTH - 1 : 0] evq_measure_fifo_o_data [`QPU_MEASURE_EVENT_NUM - 1 : 0];
  wire [`QPU_MEASURE_EVENT_QUEUE_WIDTH - 1 : 0] evq_measure_fifo_o_data_pre [`QPU_MEASURE_EVENT_NUM - 1 : 0];
  wire [`QPU_EVENT_NUM - 1 ：0] event_queue_byp;


  wire [`QPU_QI_EVENT_QUEUE_WIDTH - 1 : 0] evq_dis_ptr_qi_o_r [`QPU_EVENT_PTR_WIDTH - 1 : 0];  
  wire [`QPU_MEASURE_EVENT_QUEUE_WIDTH - 1 : 0] evq_dis_ptr_measure_o_r [`QPU_EVENT_PTR_WIDTH - 1 : 0];  
  wire [`QPU_EVENT_NUM - 1 : 0] evq_fifo_o_condi;
  wire [`QPU_QI_EVENT_WIRE_WIDTH - 1 : 0] evq_dest_o_data_pre;

  genvar l;
  generate 
  for(l=0;l<`QPU_EVENT_NUM;l=l+1) begin

    
    assign evq_fifo_i_valid[l]   = (~event_queue_full) & (~time_queue_full) & (evq_dest_wen) & evq_dest_oprand[l] & (~event_queue_byp[l])
    assign evq_fifo_o_ready[l]   = (evq_dis_ptr_qi_o_r[l] == evq_ret_ptr_r) & tiq_o_valid;

    assign event_queue_byp[l]    = tiq_o_valid & (~event_queue_empty) & evq_dest_wen & (evq_dis_ptr_r == evq_ret_ptr_r);
    assign evq_dest_o_valid[l]   = evq_fifo_o_condi[l] & ((event_queue_byp[l] & evq_dest_oprand[l]) | (~event_queue_byp[l] & evq_fifo_o_ready[l] & evq_fifo_o_valid[l])); //////队列输出有效

    

    if(l<`QPU_QI_EVENT_NUM) begin
      

      assign evq_qi_fifo_i_data[l] = {evq_dis_ptr_r,evq_dest_data[(l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH]};
      assign {evq_dis_ptr_qi_o_r[l],evq_qi_fifo_o_data_pre[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH]} = evq_qi_fifo_o_data[l];
      assign evq_dest_o_data_pre[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH] = event_queue_byp[l] ?  evq_dest_data[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH]   : evq_qi_fifo_o_data_pre[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH];
      assign evq_fifo_o_condi[l]  =   ( evq_dest_o_data_pre[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH] <`QPU_QUANTUM_0_FEEDBACK_ADDR_BEGIN) ? 1'b1
                                  :   ( evq_dest_o_data_pre[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH] <`QPU_QUANTUM_1_FEEDBACK_ADDR_BEGIN) ? (qubit_measure_zero[l])
                                  :   ( evq_dest_o_data_pre[((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH] <`QPU_QUANTUM_EQU_FEEDBACK_ADDR_BEGIN) ? (qubit_measure_one[l])
                                  :   qubit_measure_equ[l];
      assign evq_dest_o_data [((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH] = {`QPU_QI_EVENT_WIDTH{evq_fifo_o_condi[l]}} & evq_dest_o_data_pre [((l+1)*`QPU_QI_EVENT_WIDTH) - 1,l*`QPU_QI_EVENT_WIDTH];
      

      sirv_gnrl_fifo # (
        .CUT_READY(1), 
        .MSKO(1),
        .DP(`QPU_QI_EVENT_QUEUE_DEPTH),
        .DW(`QPU_QI_EVENT_QUEUE_WIDTH)
      ) evq_qi_fifo (
        .i_vld   (evq_fifo_i_valid[l]),
        .i_rdy   (evq_fifo_i_ready[l]),
        .i_dat   (evq_qi_fifo_i_data[l]),
        .o_vld   (evq_fifo_o_valid[l]),
        .o_rdy   (evq_fifo_o_ready[l]),
        .o_dat   (evq_qi_fifo_o_data[l]),
        .clk     (clk  ),
        .rst_n   (rst_n)
      );

      
    end
    else begin

      assign evq_fifo_o_condi[l] = 1'b1; 
      assign evq_measure_fifo_i_data[l] = {evq_dis_ptr_r,evq_dest_data[(`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM + 1) * `QPU_MEASURE_EVENT_WIDTH - 1 , `QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM) * `QPU_MEASURE_EVENT_WIDTH]};
      assign {evq_dis_ptr_measure_o_r[l],evq_measure_fifo_o_data_pre[(`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM + 1) * `QPU_MEASURE_EVENT_WIDTH - 1 , `QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM) * `QPU_MEASURE_EVENT_WIDTH]} = evq_qi_fifo_o_data[l];
      assign evq_dest_o_data[(`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM + 1) * `QPU_MEASURE_EVENT_WIDTH - 1 , `QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM) * `QPU_MEASURE_EVENT_WIDTH] = event_queue_byp[l] ?  evq_dest_data[(`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM + 1) * `QPU_MEASURE_EVENT_WIDTH - 1 , `QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM) * `QPU_MEASURE_EVENT_WIDTH]   : evq_measure_fifo_o_data_pre[(`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM + 1) * `QPU_MEASURE_EVENT_WIDTH - 1 , `QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (l-`QPU_QI_EVENT_NUM) * `QPU_MEASURE_EVENT_WIDTH];
      
      sirv_gnrl_fifo # (
        .CUT_READY(1), 
        .MSKO(1),
        .DP(`QPU_MEASURE_EVENT_QUEUE_DEPTH),
        .DW(`QPU_MEASURE_EVENT_QUEUE_WIDTH)
      ) evq_measure_fifo (
        .i_vld   (evq_fifo_i_valid[l]),
        .i_rdy   (evq_fifo_i_ready[l]),
        .i_dat   (evq_measure_fifo_i_data[l]),
        .o_vld   (evq_fifo_o_valid[l]),
        .o_rdy   (evq_fifo_o_ready[l]),
        .o_dat   (evq_measure_fifo_o_data[l]),
        .clk     (clk  ),
        .rst_n   (rst_n)
      );

    end

  end
  endgenerate 

  assign evq_dest_i_ready  = ~event_queue_full;
  assign event_queue_full  = ~(& evq_fifo_i_ready);
  assign event_queue_empty = ~(| evq_fifo_o_valid);




endmodule

