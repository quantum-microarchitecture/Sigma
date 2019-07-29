disp模块测试文档
===

模块功能
---
作为一个连接部件，连接decode、oitf、alu、regfile，由oitf开关控制发送到alu的数据是否有效
这个模块的代码量很少，就几十行，几乎都是直接的连线，这个模块重点进行代码逻辑分析

```
module QPU_exu_disp(
  

  input  disp_i_valid, // Handshake valid with IFU
  output disp_i_ready, // Handshake ready with IFU

  // The operand 1/2 read-enable signals and indexes
  input  disp_i_rs1x0,                                   //操作数1为零
  input  disp_i_rs2x0,
  input  disp_i_rs1en,                                   //需要操作数1
  input  disp_i_rs2en,
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rs1idx,      //操作数1索引
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rs2idx,
  input  [`QPU_XLEN-1:0] disp_i_rs1,                     //regfile输入的操作数
  input  [`QPU_XLEN-1:0] disp_i_rs2,
  input  disp_i_rdwen,                                   //需要目的操作数
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] disp_i_rdidx,       
  input  [`QPU_DECINFO_WIDTH-1:0]  disp_i_info,          //信息总线
  input  [`QPU_XLEN-1:0] disp_i_imm,                     //立即数
  input  [`QPU_PC_SIZE-1:0] disp_i_pc,                
  input  disp_i_ntp,//                                   //新时间点标记
  input  disp_i_measure,//                               //测量标记
  input  disp_i_nqf,//                                   //新比特标记
  input  disp_i_fmr,                                     //取测量结果

  input [`QPU_TIME_WIDTH - 1 : 0] disp_i_clk,            //当前时间记录
  input  disp_i_qmr,                                 //测量的结果，只有一个测量结果！
  input [`QPU_EVENT_WIRE_WIDTH - 1 : 0] disp_i_edata,    //事件队列数据
  input [`QPU_EVENT_NUM - 1 : 0] disp_i_oprand,          //比特操作对象

  //////////////////////////////////////////////////////////////
  // Dispatch to ALU

  output disp_o_alu_valid,                               //发送到alu的请求信号
  input  disp_o_alu_ready,                               //alu发送过来的ready信号

  input  disp_o_alu_longpipe,                            //alu发送的长流水线信号

  output [`QPU_XLEN-1:0] disp_o_alu_rs1,                 //操作数1
  output [`QPU_XLEN-1:0] disp_o_alu_rs2,
  output disp_o_alu_rdwen,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] disp_o_alu_rdidx,   //额外增加一位的寄存器索引
  output [`QPU_DECINFO_WIDTH-1:0]  disp_o_alu_info,  
  output [`QPU_XLEN-1:0] disp_o_alu_imm,                 
  output [`QPU_PC_SIZE-1:0] disp_o_alu_pc,            

  output [`QPU_TIME_WIDTH - 1 : 0] disp_o_alu_clk,      //时间信号
  output disp_o_alu_qmr,                                //测量结果
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

  output [`QPU_QUBIT_NUM - 1 : 0] disp_oitf_qubitlist//
  

  );
```

测试日志
---
----------------
7/23
可运行

----------------
7/25
没有红蓝线，符合要求结果
----------------
