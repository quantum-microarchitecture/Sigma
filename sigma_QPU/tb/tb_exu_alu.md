alu模块测试文档
===

模块功能
---
处理器的执行模块，将各指令发送到相应的具体执行模块bjp、qiu、rglr执行，再获取执行结果，统一交付写回。
ALU模块
```
module QPU_exu_alu(

  //////////////////////////////////i_longpipe////////////////////////////
  // The operands and decode info from dispatch
  input  i_valid,                                 //通信信号
  output i_ready, 

  output i_longpipe,            // Indicate this instruction is         
                                //   issued as a long pipe instruction
 
  input  [`QPU_XLEN-1:0] i_rs1,                   //操作数 
  input  [`QPU_XLEN-1:0] i_rs2,
  input  [`QPU_XLEN-1:0] i_imm,                   //立即数
  input  [`QPU_DECINFO_WIDTH-1:0]  i_info,        //总线

  input [`QPU_TIME_WIDTH - 1 : 0] i_clk,          //当前记录时间
  input i_qmr,                                    //测量结果
  input [`QPU_EVENT_WIRE_WIDTH - 1 : 0] i_edata,  //事件        
  input [`QPU_EVENT_NUM - 1 : 0] i_oprand,        //事件操作比特           

  input i_ntp,                                    
  input i_fmr,                                    
  input i_measure,

  input  [`QPU_PC_SIZE-1:0] i_pc,                 //to cmt

  input  [`QPU_RFIDX_REAL_WIDTH-1:0] i_rdidx,     //目的寄存器索引，含量子操作数寄存器
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
  output cwbck_o_valid, // Handshake valid               //经典写回
  input  cwbck_o_ready, // Handshake ready 
  output [`QPU_XLEN-1:0] cwbck_o_data,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] cwbck_o_rdidx,

  output qcwbck_o_valid, // Handshake valid              //量子操作数写回
  input  qcwbck_o_ready, // Handshake ready
  output [`QPU_XLEN-1:0] qcwbck_o_data,
  output [`QPU_RFIDX_REAL_WIDTH-1:0] qcwbck_o_rdidx,


  output twbck_o_valid,                                  //时间写回
  input  twbck_o_ready,
  output [`QPU_TIME_WIDTH - 1 : 0] twbck_o_data,

  output ewbck_o_valid,                                  //事件写回
  input  ewbck_o_ready,
  output [(`QPU_EVENT_WIRE_WIDTH - 1) : 0]  ewbck_o_data,

  output [(`QPU_EVENT_NUM - 1) : 0]        ewbck_o_oprand


  );
```

bjp模块，分析跳转信息和需求，发送回alu模块
```
  QPU_exu_alu_bjp u_QPU_exu_alu_bjp(
      .bjp_i_valid         (bjp_i_valid         ),          //alu-bjp
      .bjp_i_ready         (bjp_i_ready         ),
      .bjp_i_rs1           (bjp_i_rs1           ),          //跳转操作数
      .bjp_i_rs2           (bjp_i_rs2           ),          
      .bjp_i_info          (bjp_i_info[`QPU_DECINFO_BJP_WIDTH-1:0]),

      .bjp_o_valid         (bjp_o_valid      ),             //bjp-alu-cmt
      .bjp_o_ready         (bjp_o_ready      ),

      .bjp_o_cmt_prdt      (bjp_o_cmt_prdt   ),             
      .bjp_o_cmt_rslv      (bjp_o_cmt_rslv   ),

      .bjp_req_alu_op1     (bjp_req_alu_op1       ),        //bjp-alu-datapath
      .bjp_req_alu_op2     (bjp_req_alu_op2       ),
      .bjp_req_alu_cmp_eq  (bjp_req_alu_cmp_eq    ),
      .bjp_req_alu_cmp_ne  (bjp_req_alu_cmp_ne    ),
      .bjp_req_alu_cmp_lt  (bjp_req_alu_cmp_lt    ),
      .bjp_req_alu_cmp_gt  (bjp_req_alu_cmp_gt    ),
      
      .bjp_req_alu_cmp_res (bjp_req_alu_cmp_res   )

  );
```

rglr模块
解析经典计算总线，得出要进行的计算操作，发送到dpath计算
```
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

      .alu_req_alu_add     (alu_req_alu_add       ),    //计算操作标志
      .alu_req_alu_sub     (alu_req_alu_sub       ),
      .alu_req_alu_xor     (alu_req_alu_xor       ),
      .alu_req_alu_or      (alu_req_alu_or        ),
      .alu_req_alu_and     (alu_req_alu_and       ),

      .alu_req_alu_op1     (alu_req_alu_op1       ),    //操作数
      .alu_req_alu_op2     (alu_req_alu_op2       ),
      .alu_req_alu_res     (alu_req_alu_res       )


  );
```

qiu模块

```
  QPU_exu_alu_qiu u_QPU_exu_alu_qiu(

      .qiu_i_valid         (qiu_i_valid         ),
      .qiu_i_ready         (qiu_i_ready         ),
      .qiu_i_rs1           (qiu_i_rs1           ),    //比特标记
      .qiu_i_rs2           (qiu_i_rs2           ),    
      .qiu_i_imm           (qiu_i_imm           ),    


      .qiu_i_info          (qiu_i_info[`QPU_DECINFO_QIU_WIDTH-1:0]),
      .qiu_i_measure       (i_measure           ),    
      .qiu_i_ntp           (i_ntp               ),
      .qiu_i_edata         (qiu_i_edata         ),    //事件操作码
      .qiu_i_oprand        (qiu_i_oprand        ),    //事件操作数

      .qiu_i_clk           (qiu_i_clk           ),


      .qiu_o_valid         (qiu_o_valid         ),
      .qiu_o_ready         (qiu_o_ready         ),

      .qiu_o_wbck_edata    (qiu_o_wbck_edata     ),    //写回
      .qiu_o_wbck_oprand   (qiu_o_wbck_oprand    ),
      .qiu_o_wbck_tdata    (qiu_o_wbck_tdata     ),

      .qiu_req_alu_op1     (qiu_req_alu_op1       ),    //计算操作数
      .qiu_req_alu_op2     (qiu_req_alu_op2       ),
      .qiu_req_alu_res     (qiu_req_alu_res       )

  );
```

dpath模块，负责执行各种计算，输入要执行的计算和两个操作数，返回计算结果
```
  QPU_exu_alu_dpath u_QPU_exu_alu_dpath(
      .alu_req_alu         (alu_req_alu           ),    //alu发起的请求
      .alu_req_alu_add     (alu_req_alu_add       ),    //计算模式选择
      .alu_req_alu_sub     (alu_req_alu_sub       ),    
      .alu_req_alu_xor     (alu_req_alu_xor       ),
      .alu_req_alu_or      (alu_req_alu_or        ),
      .alu_req_alu_and     (alu_req_alu_and       ),
      .alu_req_alu_op1     (alu_req_alu_op1       ),    //操作数
      .alu_req_alu_op2     (alu_req_alu_op2       ),
      .alu_req_alu_res     (alu_req_alu_res       ),    //结果
           
      .bjp_req_alu         (bjp_req_alu           ),    //bjp发起请求
      .bjp_req_alu_op1     (bjp_req_alu_op1       ),
      .bjp_req_alu_op2     (bjp_req_alu_op2       ),
      .bjp_req_alu_cmp_eq  (bjp_req_alu_cmp_eq    ),
      .bjp_req_alu_cmp_ne  (bjp_req_alu_cmp_ne    ),
      .bjp_req_alu_cmp_lt  (bjp_req_alu_cmp_lt    ),
      .bjp_req_alu_cmp_gt  (bjp_req_alu_cmp_gt    ),
      .bjp_req_alu_cmp_res (bjp_req_alu_cmp_res   ),
             
      .qiu_req_alu         (qiu_req_alu           ),    //qiu发起请求
      .qiu_req_alu_op1     (qiu_req_alu_op1       ),
      .qiu_req_alu_op2     (qiu_req_alu_op2       ),
      .qiu_req_alu_res     (qiu_req_alu_res       )

    );
```

测试日志
---
----------------
7/23
可运行

----------------
7/25
测试bjp
1、bjp_i_rs1\bjp_i_rs2 始终为零，这个问题可能要测试到寄存器才能解决。
2、bjp_req_alu_cmp_gt 表现与期望不符，检查发现dpath中adder_res结果错误

----------------
7/26
测试alu主模块
1、i_valid/i_ready 现在还不能体现功能
2、i_rs1/i_rs2 还没能获取数据，没有连接寄存器模块
3、涉及到寄存器的数据现在还没办法检验
4、cwbck_o_data 一部分为红线，呈现不定态，从rglr过来的alu_o_wbck_cdata呈现不定态，
   修改dpath后已解决。#####
5、qiu_o_wbck_tdata/qiu_o_wbck_edata/qiu_o_wbck_oprand也是存在不定态
   qiu_o_wbck_tdata #####
   qiu_o_wbck_edata #####
   qiu_o_wbck_oprand #####
6、alu_req_alu_res 存在不定态，检查dpath #####


测试rglr
1、alu_req_alu_res 不定态 #####

测试dpath
1、mux_op 对不上，已修正。#####
2、op_sub 红线 修正后dapth全为绿线。#####


测试qiu
1、qiu_o_wbck_oprand。#####
2、qiu_o_wbck_edata。#####

----------------