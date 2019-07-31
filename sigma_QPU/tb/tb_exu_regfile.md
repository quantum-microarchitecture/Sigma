regfile模块测试文档
===

模块功能
存储计算过程中的数据
```
`include "QPU_defines.v"

module QPU_exu_regfile(

//classical regfile

  input  [`QPU_RFIDX_REAL_WIDTH-1:0] read_src1_idx,   //操作数寄存器索引
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] read_src2_idx,
  output [`QPU_XLEN-1:0] read_src1_data,              //操作数寄存器数据    
  output [`QPU_XLEN-1:0] read_src2_data,
  

  input  cwbck_dest_wen,                             
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] cwbck_dest_idx,  //经典目的寄存器索引
  input  [`QPU_XLEN-1:0] cwbck_dest_data,             //经典目的寄存器数据


  input qcwbck_dest_wen,                          
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] qcwbck_dest_idx, //量子操作数目的寄存器索引
  input  [`QPU_XLEN-1:0] qcwbck_dest_data,            

//time regfile
  input twbck_dest_wen,                      //ntp & event and time queue is not full ,from wbck
  input [`QPU_TIME_WIDTH - 1 : 0] twbck_dest_data,         //时间写入
  output [`QPU_TIME_WIDTH - 1 : 0] read_time_data,         //to alu

//event regfile
 
  input ewbck_dest_wen,                      //QI or QWAIT & ~full, from wbck
  input [(`QPU_EVENT_NUM - 1) : 0] ewbck_dest_oprand, //(XYevent + Zevent + measure_event)
  input [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] ewbck_dest_data,
  

  output [(`QPU_EVENT_NUM - 1) : 0] read_event_oprand,      // to queue and alu
  output [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] read_event_data,
  

//measurement result reg
  input [`QPU_QUBIT_NUM - 1 : 0] mcu_measure_i_data,        //写入测量结果
  input mcu_measure_i_wen,

  input [`QPU_QUBIT_NUM - 1 : 0] oitf_ret_i_measurelist,    //控制写入结果

  input read_qubit_ena,                                    //FMR指令为1，其余时刻均为0
  //input [`QPU_QUBIT_NUM - 1 : 0] read_qubit_list,          //控制读出列表,读出列表在rs1中，内部直连
  output read_qubit_data,         //返回测量结果，这里不存在正在写回的问题，因为如果正在写回，oitf中的qubitlist依旧为1，不可以派遣fmr指令,read_qubit_ena控制输出结果，会一直输出测量结果（加了mask）！只取一个比特的测量结果

  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_zero,   ///发送给event_queue，做快反馈控制。只有当测量结果返回时，才可执行快反馈，因此无需要返回测量结果后立刻更改测量结果
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_one , 
  output [`QPU_QUBIT_NUM - 1 : 0] qubit_measure_equ,

  input  clk,
  input  rst_n
  );
```
---



测试日志
---
----------------
7/23
可运行

----------------
7/29
存在一些问题，主要是读取到的数据与预期不符
1、qcrf_wen 
2、disp_condition in disp, oitfrd_match_disprs1 in oitf.
3、i_ready
4、disp_alu_valid
5、disp_alu_rs1/disp_alu_rs2
6、disp_alu_edata
7、disp_alu_oprand
8、disp_oitf_qubitlist
9、alu_cmt_valid
10、alu_cmt_bjp_rslv
11、alu_cwbck_o_valid

检验发现寄存器可以完成大部分数据存入读出功能，部分的红线是正常现象，只要用到数据时不是红线即可
但是FMR好像无法正常读取数据
----------------