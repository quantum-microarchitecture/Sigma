decode模块测试文档
===

模块功能
---
将IR寄存器中的指令译码，进行分类和标记，为后续的派遣执行进行准备
```
  QPU_exu_decode test_exu_decode(
      .i_instr (i_instr),              //输入指令
      .i_pc (i_pc),                    //输入pc
      .i_prdt_taken (i_prdt_taken),    //ifu过来的预测跳转信号

      .dec_rs1x0(dec_rs1x0),           //操作数1为零
      .dec_rs2x0(dec_rs2x0),           //操作数2为零
      .dec_rs1en(dec_rs1en),           //需要用到操作数1
      .dec_rs2en(dec_rs2en),           //需要用到操作数2
      .dec_rdwen(dec_rdwen),           //需要用到目的操作数
      .dec_rs1idx(dec_rs1idx),         //操作数1索引地址
      .dec_rs2idx(dec_rs2idx),         //操作数2索引地址
      .dec_rdidx(dec_rdidx),           //目的操作数索引地址
      .dec_info(dec_info),             //信息总线
      .dec_imm(dec_imm),               //立即数
      .dec_pc(dec_pc),                 //pc

      .dec_new_timepoint(dec_new_timepoint),          //新时间点标记
      .dec_need_qubitflag(dec_need_qubitflag),        //是否需要涉及比特的标记
      .dec_measure(dec_measure),                      //测量标记
      .dec_fmr(dec_fmr),                              //取测量结果标记

      .dec_bxx(dec_bxx),                              //跳转指令标记
      .dec_bjp_imm(dec_bjp_imm)                       //跳转立即数
  );

```


测试日志
---
----------------
7/22
依次执行各条指令，检验其输出结果是否符合预期
输入：
```
  initial
  begin
    #0 i_instr = `instr_LOAD;
    #0 i_pc = `QPU_PC_SIZE'b0;
    #0 i_prdt_taken = 1'b0;
    #2 i_instr = `instr_STORE;

    #5 i_instr = `instr_BEQ;
    #2 i_instr = `instr_BNE;
    #2 i_instr = `instr_BLT;
    #2 i_instr = `instr_BGT;

    #5 i_instr = `instr_ADDI;
    #2 i_instr = `instr_XORI;
    #2 i_instr = `instr_ORI;
    #2 i_instr = `instr_ANDI;

    #5 i_instr = `instr_ADD;
    #2 i_instr = `instr_XOR;
    #2 i_instr = `instr_OR;
    #2 i_instr = `instr_AND;

    #10 i_instr = `instr_QWAIT;
    #2 i_instr = `instr_FMR;
    #2 i_instr = `instr_SMIS;
    #2 i_instr = `instr_QI;
    #2 i_instr = `instr_measure;

    #5 i_instr = `instr_WFI;


  end
```
输出：基本符合预期结果

----------------
7/24
添加输入测试：
```
    #5 i_instr = `instr_QI_1;
    #2 i_instr = `instr_QI_2;
    #2 i_instr = `instr_QI_3;
```
输出：符合预期结果
-------------------





