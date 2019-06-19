                                                           
                                                                         
                                                                         
//=====================================================================
// Designer   : QI ZHOU
//
// Description:
//  The Regfile module to implement the core's general purpose registers file
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_regfile(

//classical regfile

  input  [`QPU_RFIDX_REAL_WIDTH-1:0] read_src1_idx,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] read_src2_idx,
  output [`QPU_XLEN-1:0] read_src1_data,                  //对于两比特GATE，输出的是执行GATE的掩码信息，同单比特门
  output [`QPU_XLEN-1:0] read_src2_data,
  input dec_tqg,                                         //two-qubit gate
  //output [`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1 : 0] read_tqgl1_data,
  //output [`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1 : 0] read_tqgl2_data,

  input  cwbck_dest_wen,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] cwbck_dest_idx,
  input  [`QPU_XLEN-1:0] cwbck_dest_data,


  input qcwbck_dest_wen,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] qcwbck_dest_idx,
  input  [`QPU_XLEN-1:0] qcwbck_dest_data,

//time regfile
  input twbck_dest_wen,                      //ntp & event and time queue is not full ,from wbck
  input [`QPU_TIME_WIDTH - 1 : 0] twbck_dest_data,          
  output [`QPU_TIME_WIDTH - 1 : 0] read_time_data,         //to alu

//event regfile
 
  input ewbck_dest_wen,                      //QI or QWAIT & ~full, from wbck
  input [(`QPU_EVENT_NUM - 1) : 0] ewbck_dest_oprand,
  input [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] ewbck_dest_data,
  //input [(`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1) : 0] ewbck_dest_tqgl;

  output [(`QPU_EVENT_NUM - 1) : 0] read_event_oprand,      // to queue and alu
  output [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] read_event_data,
  //output [(`QPU_TWO_QUBIT_GATE_LIST_WIDTH - 1) : 0] read_event_tqgl;


//measurement result reg
  input [`QPU_QUBIT_NUM - 1 : 0] mcu_measure_i_data,
  input mcu_measure_i_wen,

  input [`QPU_QUBIT_NUM - 1 : 0] oitf_ret_i_measurelist,    //控制写入结果

  input read_qubit_ena,                                    //FMR指令为1，其余时刻均为0
  //input [`QPU_QUBIT_NUM - 1 : 0] read_qubit_list,          //控制读出列表,读出列表在rs1中，内部直连
  output [`QPU_QUBIT_NUM - 1 : 0] read_qubit_data,         //返回测量结果，这里不存在正在写回的问题，因为如果正在写回，oitf中的qubitlist依旧为1，不可以派遣fmr指令,read_qubit_ena控制输出结果，会一直输出测量结果（加了mask）！

  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_zero,   ///发送给event_queue，做快反馈控制
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_one , 
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_equ,

  input  clk,
  input  rst_n
  );


/////////////////////////////////////////////////////////////////////////////////////////////////////
  ///time_register
  wire [`QPU_TIME_WIDTH - 1 : 0] time_r; 
  wire time_ena;
  wire [`QPU_TIME_WIDTH - 1 : 0] time_nxt;

  assign time_ena = twbck_dest_wen;
  assign time_nxt = twbck_dest_data;
  assign read_time_data = time_r;

  sirv_gnrl_dfflr  #(`QPU_TIME_WIDTH) time_r_dfflr   (time_ena, time_nxt, time_r, clk, rst_n);
  



  
////////////////////////////////////////////////////////////////////////////////////////////////
//event reg                                                      [最高2位：测量] [剩余：QI]         


  wire [(`QPU_EVENT_NUM - 1) : 0] ewbck_oprand_r;
  wire [(`QPU_EVENT_NUM - 1) : 0] ewbck_oprand_nxt;

  wire [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] ewbck_event_r;
  wire [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] ewbck_event_nxt;

  assign read_event_oprand = ewbck_oprand_r;
  assign read_event_data = ewbck_event_r;

  assign ewbck_oprand_nxt = ewbck_dest_oprand;
  assign ewbck_event_nxt  = ewbck_dest_data;

  sirv_gnrl_dffl    #(`QPU_EVENT_WIRE_WIDTH) q_event_dffl         (ewbck_dest_wen, ewbck_event_nxt,  ewbck_event_r,      clk);
  sirv_gnrl_dfflr   #(`QPU_EVENT_NUM)        q_oprand_dfflr       (ewbck_dest_wen, ewbck_oprand_nxt, ewbck_oprand_r,     clk, rst_n);


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//qubit measure result
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_wen;
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_ren;
  assign qubit_measure_wen = oitf_ret_i_measurelist & {(`QPU_QUBIT_NUM){mcu_measure_i_wen}};
  assign qubit_measure_ren = read_src1_data[`QPU_QUBIT_NUM - 1 : 0] & {(`QPU_QUBIT_NUM){read_qubit_ena}};        //读取列表直接在reg 内部相连

  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_wen0;
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_wen1;
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_nxt;
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_r0;
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_r1;

  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_flag_ena;
  wire [1 : 0] qubit_measure_flag_nxt [`QPU_QUBIT_NUM - 1 : 0];
  wire [1 : 0] qubit_measure_flag_r [`QPU_QUBIT_NUM - 1 : 0];
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_result;
  wire [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_realtime_result;

  

  genvar k;
  generate
    for(k = 0; k < `QPU_QUBIT_NUM; k = k + 1) begin
      ///write data 
      assign qubit_measure_flag_nxt[k] = (qubit_measure_flag_r[k][1] == 1'b1) ? 2'b01 : 2'b10; ///是否可以这样写？
      assign qubit_measure_flag_ena[k] = qubit_measure_wen[k];
      sirv_gnrl_dfflrs #(1)    qubit_measure_flag_0_dfflrs   (qubit_measure_flag_ena[k], qubit_measure_flag_nxt[k][0]     , qubit_measure_flag_r[k][0]     , clk, rst_n);
      sirv_gnrl_dfflr #(1)     qubit_measure_flag_1_dfflr    (qubit_measure_flag_ena[k], qubit_measure_flag_nxt[k][1]     , qubit_measure_flag_r[k][1]     , clk, rst_n);

      assign qubit_measure_wen0[k] = qubit_measure_wen[k] & qubit_measure_flag_r[k][0] ;
      assign qubit_measure_wen1[k] = qubit_measure_wen[k] & qubit_measure_flag_r[k][1] ;
      assign qubit_measure_nxt [k] = mcu_measure_i_data[k] ;
      sirv_gnrl_dfflrs #(1)    qubit_measure0_dfflrs   (qubit_measure_wen0[k], qubit_measure_nxt[k], qubit_measure_r0[k], clk, rst_n);
      sirv_gnrl_dfflrs #(1)    qubit_measure1_dfflrs   (qubit_measure_wen1[k], qubit_measure_nxt[k], qubit_measure_r1[k], clk, rst_n);

      ///conditional fast control and read data
      assign qubit_measure_result[k] = ( (~qubit_measure_flag_r[k][0]) & qubit_measure_r0[k] ) | ( (~qubit_measure_flag_r[k][1]) & qubit_measure_r1[k] ) ;
      assign qubit_measure_realtime_result [k] =  ((~mcu_measure_i_wen) & qubit_measure_result[k])
                                                | (( mcu_measure_i_wen) & ((qubit_measure_wen[k] & mcu_measure_i_data[k]) | ((~qubit_measure_wen[k]) & qubit_measure_result[k])));

      assign qubit_measure_zero  [k] = ~qubit_measure_realtime_result[k];
      assign qubit_measure_one   [k] =  qubit_measure_realtime_result[k];
      assign qubit_measure_equ   [k] =    ((~mcu_measure_i_wen) & (qubit_measure_r0[k] == qubit_measure_r1[k]))
                                        | (( mcu_measure_i_wen) & ( (qubit_measure_wen[k] &  ( ((~qubit_measure_flag_r[k][0])&(qubit_measure_r0[k]== mcu_measure_i_data[k]))  | ((~qubit_measure_flag_r[k][1])&(qubit_measure_r1[k]== mcu_measure_i_data[k]))   ) ) | ((~qubit_measure_wen[k]) & (qubit_measure_r0[k] == qubit_measure_r1[k]))  ) );

    end
  endgenerate
  
  assign read_qubit_data = qubit_measure_result & qubit_measure_ren;

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////classical reg
  wire [`QPU_XLEN-1:0] read_src1_qdata;
  wire [`QPU_XLEN-1:0] read_src2_qdata;
  wire [`QPU_XLEN-1:0] read_src1_cqdata;
  wire [`QPU_XLEN-1:0] read_src2_cqdata;
  wire [`QPU_XLEN-1:0] read_src1_oqdata;        //one qubit
  wire [`QPU_XLEN-1:0] read_src2_oqdata;
  wire [`QPU_XLEN-1:0] read_src1_mqdata;        //mutiple qubits
  wire [`QPU_XLEN-1:0] read_src2_mqdata;
  
  wire [`QPU_XLEN-1:0] crf_r [`QPU_RFREG_NUM-1:0];
  wire [`QPU_RFREG_NUM-1:0] crf_wen;
  wire [`QPU_XLEN-1:0] qcrf_r [`QPU_RFREG_NUM-1:0];
  wire [`QPU_RFREG_NUM-1:0] qcrf_wen;
  wire 

  genvar m;
  generate //{
  
      for (m=0; m<`QPU_RFREG_NUM; m=m+1) begin: classical regfile//{
        

        if(m==0) begin: rf0
            // x0 cannot be wrote since it is constant-zeros
            assign crf_wen[m] = 1'b0;
            assign crf_r[m] = `QPU_XLEN'b0;
        end
        else begin
            assign crf_wen[m] = cwbck_dest_wen & (cwbck_dest_idx[`QPU_RFIDX_WIDTH-1:0] == m);     //不需要首位标记位
            sirv_gnrl_dffl #(`QPU_XLEN) crf_dffl (crf_wen[m], cwbck_dest_data, crf_r[m], clk);
        end

      end//}
  endgenerate//}

  genvar n;
  generate //{
  
      for (n=0; n<`QPU_RFREG_NUM; n=n+1) begin:quantum regfile//{

        if(n < `QPU_QUBIT_NUM) begin
            assign qcrf_wen[n] = 1'b0;
            assign qcrf_r[n] = ((`QPU_XLEN'b1) << n);
        end

        else begin
            assign qcrf_wen[n] = qcwbck_dest_wen & (qcwbck_dest_idx[`QPU_RFIDX_WIDTH-1:0] == n);       //不需要首位标记位
            sirv_gnrl_dffl #(`QPU_XLEN) qcrf_dffl (qcrf_wen[n], qcwbck_dest_data, qcrf_r[n], clk);
        end
      end//}
  endgenerate//}
  

  ///for two qubit gate rs
  



  
  assign read_src1_cdata = crf_r[read_src1_idx[`QPU_RFIDX_WIDTH-1:0]];
  assign read_src2_cdata = crf_r[read_src2_idx[`QPU_RFIDX_WIDTH-1:0]];
  assign read_src1_oqdata = qcrf_r[read_src1_idx[`QPU_RFIDX_WIDTH-1:0]];
  assign read_src2_oqdata = qcrf_r[read_src2_idx[`QPU_RFIDX_WIDTH-1:0]];

  assign read_src1_data = ({`QPU_XLEN{~read_src1_idx[`QPU_RFIDX_REAL_WIDTH - 1]}} & read_src1_cdata) | ({`QPU_XLEN{read_src1_idx[`QPU_RFIDX_REAL_WIDTH - 1]}} & read_src1_oqdata);
  assign read_src2_data = ({`QPU_XLEN{~read_src2_idx[`QPU_RFIDX_REAL_WIDTH - 1]}} & read_src2_cdata) | ({`QPU_XLEN{read_src2_idx[`QPU_RFIDX_REAL_WIDTH - 1]}} & read_src2_oqdata);    

  assign read_tqgl1_data = ;
  assign read_tqgl2_data = ;


endmodule

