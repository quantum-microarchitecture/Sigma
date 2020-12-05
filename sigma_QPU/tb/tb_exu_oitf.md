oitf模块测试文档
===

模块功能
---
一个记录正在运行长指令信息和正在执行测量操作比特信息的队列模块，新读取的特定指令要与里面的信息进行比较，决定是否派遣。
```verilog
module QPU_exu_oitf (
  
  //ready to accept new longpipe
  output dis_cf_ready,         //cf: classical fifo
  output dis_mf_ready,        //  mf : measurement fifo
 
  //need write in oitf
  input  dis_cl_ena,
  input  dis_qf_ena,          //qf : qubit flag which is used to distinguish which qubit is being measured
                              //ql : qubit list ,FMR and MEASURE instruction will sent the oprand to oitf module
                              //qubit flag and measurement fifo push and pop at same time
   ///longwbck
  //remove signal
  input  ret_cl_ena,          //长指令执行完成
  ///remove signal
  //mcu
  input  ret_qf_ena,

 

  //wbct info
  output [`QPU_RFIDX_REAL_WIDTH-1:0] ret_rdidx,//提供写回寄存器索引
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
  output oitfrd_match_disprs1,                //发送到disp进行判断控制
  output oitfrd_match_disprs2,
  output oitfrd_match_disprd,
  
  output oitfqf_match_dispql,

  output oitf_empty,
  output moitf_empty,
  
  input  clk,
  input  rst_n

);
```

测试日志
---
----------------
7/23
可运行

----------------
7/29
1、ret_rdidx(oitf_ret_rdidx) 红线
2、ret_rdwen(oitf_ret_rdwen) 红线
3、ret_mf(disp_oitf_ret_measurelist) 红线
4、alc_ptr_ena 使能始终为零，因为删去了lsu模块，并设alu模块中 i_longpipe =  1'b0;
5、因为输入指令没有按时钟周期执行，导致测试结果出错。

打算连着wbck、regfile模块串起来后，再按相对正确的指令时钟周期来测量
----------------