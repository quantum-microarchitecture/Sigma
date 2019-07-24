                                                                      
//=====================================================================
//
// Description:
//  The files to include all the macro defines
//
// ====================================================================
`include "config.v"

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////// ISA relevant macro
//
`define QPU_INSTR_SIZE 32
`define QPU_PC_SIZE 32
`define QPU_ADDR_SIZE 32
`define QPU_XLEN 32
`define QPU_RFIDX_WIDTH 5
`define QPU_RFIDX_REAL_WIDTH 6                       //加flag位后为6

`define QPU_QUBIT_NUM 12
`define QPU_QUBIT_NUM_LENGTH 4                       //log(qubit_num+1)   最多支持15 qubit，0000表示无操作     


`define QPU_OITF_DEPTH  4
`define QPU_MOITF_DEPTH 4
`define QPU_ITAG_WIDTH  2
`define QPU_QITAG_WIDTH 2  




`define QPU_EVENT_NUM (`QPU_QI_XYEVENT_NUM + `QPU_QI_ZEVENT_NUM + `QPU_MEASURE_EVENT_NUM)         //1 QI xyevent of each qubit ,1 zevent , 1 measure event for AGU and 1 measure event for MCU
`define QPU_QI_XYEVENT_NUM (`QPU_QUBIT_NUM)
`define QPU_MEASURE_EVENT_NUM 2
`define QPU_QI_ZEVENT_NUM 1
`define QPU_QI_EVENT_NUM (`QPU_QI_XYEVENT_NUM + `QPU_QI_ZEVENT_NUM)  //先xy，最后一个为z

`define QPU_QI_EVENT_QUEUE_DEPTH 10
`define QPU_MEASURE_EVENT_QUEUE_DEPTH 10

`define QPU_TIME_QUEUE_DEPTH 15                                

`define QPU_QI_EVENT_WIDTH 14
`define QPU_QI_XYEVENT_WIDTH 14
`define QPU_QI_ZEVENT_WIDTH 14
`define QPU_MEASURE_EVENT_WIDTH `QPU_QUBIT_NUM
`define QPU_TIME_WIDTH 16
`define QPU_EVENT_WIRE_WIDTH (`QPU_QUBIT_NUM * `QPU_QI_XYEVENT_WIDTH + `QPU_QI_ZEVENT_WIDTH + 2 * `QPU_MEASURE_EVENT_WIDTH)         //QI_xyevent + QI_zevent + measure_event


`define QPU_QI_EVENT_WIRE_WIDTH (`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH)

`define QPU_QI_EVENT_QUEUE_WIDTH (`QPU_EVENT_PTR_WIDTH + `QPU_QI_EVENT_WIDTH)               //只有QI事件需要qubit_num辅助定位波形，测量事件不需要，事件队列需要ptr
`define QPU_MEASURE_EVENT_QUEUE_WIDTH (`QPU_EVENT_PTR_WIDTH + `QPU_MEASURE_EVENT_WIDTH)                            //事件队列需要ptr





`define QPU_EVENT_PTR_WIDTH 5                     //太小的话，有可能出现，PTR套一圈，导致事件的ptr出错！！！！！！！

`define QPU_RFREG_NUM 64 ///classical and quantum
`define QPU_CLASSICAL_RFREG_NUM 32
`define QPU_QUANTUM_RFREG_NUM 32


        /*量子操作数编码 
        首位：
        0：xy方向单比特操作，包括反馈和非反馈，以及0门和测量
        1：GATE
        首位为0
        测量操作0 00000000 ：无操作
        0 0XXXXXXX：无反馈XY单门(127)
        0 10XXXXXX：测量为1则执行的XY单门（64）
        0 110XXXXX：测量为0则执行的XY单门（32）
        0 111XXXXX：测量相同则执行的XY单门（31）
        0 11111111：
        首位为1
        1 0XXXXXXX+XXXXX (XY方向GATE)（4096）
        1 1XXXXXXX+XXXXX (Z方向GATE，包括组合GATE以及每个比特Z方向的单门及双门（4096）
        */


 `define QPU_DECINFO_GRP_WIDTH    2
  `define QPU_DECINFO_GRP_ALU      `QPU_DECINFO_GRP_WIDTH'd0
  `define QPU_DECINFO_GRP_LSU      `QPU_DECINFO_GRP_WIDTH'd1
  `define QPU_DECINFO_GRP_BJP      `QPU_DECINFO_GRP_WIDTH'd2
  `define QPU_DECINFO_GRP_QIU      `QPU_DECINFO_GRP_WIDTH'd3
  
      `define QPU_DECINFO_GRP_LSB  0
      `define QPU_DECINFO_GRP_MSB  (`QPU_DECINFO_GRP_LSB+`QPU_DECINFO_GRP_WIDTH-1)
  `define QPU_DECINFO_GRP          `QPU_DECINFO_GRP_MSB:`QPU_DECINFO_GRP_LSB
  
  `define QPU_DECINFO_SUBDECINFO_LSB    (`QPU_DECINFO_GRP_MSB+1)

  
  `define QPU_ALU_ADDER_WIDTH (`QPU_XLEN + 1)




// ALU group
      `define QPU_DECINFO_ALU_ADD_LSB    `QPU_DECINFO_SUBDECINFO_LSB
      `define QPU_DECINFO_ALU_ADD_MSB    (`QPU_DECINFO_ALU_ADD_LSB+1-1)
  `define QPU_DECINFO_ALU_ADD    `QPU_DECINFO_ALU_ADD_MSB :`QPU_DECINFO_ALU_ADD_LSB 
      `define QPU_DECINFO_ALU_SUB_LSB    (`QPU_DECINFO_ALU_ADD_MSB+1)
      `define QPU_DECINFO_ALU_SUB_MSB    (`QPU_DECINFO_ALU_SUB_LSB+1-1)
  `define QPU_DECINFO_ALU_SUB    `QPU_DECINFO_ALU_SUB_MSB :`QPU_DECINFO_ALU_SUB_LSB 
      `define QPU_DECINFO_ALU_XOR_LSB    (`QPU_DECINFO_ALU_SUB_MSB+1)
      `define QPU_DECINFO_ALU_XOR_MSB    (`QPU_DECINFO_ALU_XOR_LSB+1-1)
  `define QPU_DECINFO_ALU_XOR    `QPU_DECINFO_ALU_XOR_MSB :`QPU_DECINFO_ALU_XOR_LSB 
      `define QPU_DECINFO_ALU_OR_LSB    (`QPU_DECINFO_ALU_XOR_MSB+1)
      `define QPU_DECINFO_ALU_OR_MSB    (`QPU_DECINFO_ALU_OR_LSB+1-1)
  `define QPU_DECINFO_ALU_OR     `QPU_DECINFO_ALU_OR_MSB  :`QPU_DECINFO_ALU_OR_LSB  
      `define QPU_DECINFO_ALU_AND_LSB    (`QPU_DECINFO_ALU_OR_MSB+1)
      `define QPU_DECINFO_ALU_AND_MSB    (`QPU_DECINFO_ALU_AND_LSB+1-1)
  `define QPU_DECINFO_ALU_AND    `QPU_DECINFO_ALU_AND_MSB :`QPU_DECINFO_ALU_AND_LSB 
      `define QPU_DECINFO_ALU_SMIS_LSB    (`QPU_DECINFO_ALU_AND_MSB+1)
      `define QPU_DECINFO_ALU_SMIS_MSB    (`QPU_DECINFO_ALU_SMIS_LSB+1-1)
  `define QPU_DECINFO_ALU_SMIS    `QPU_DECINFO_ALU_SMIS_MSB :`QPU_DECINFO_ALU_SMIS_LSB   
      `define QPU_DECINFO_ALU_FMR_LSB    (`QPU_DECINFO_ALU_SMIS_MSB+1)
      `define QPU_DECINFO_ALU_FMR_MSB    (`QPU_DECINFO_ALU_FMR_LSB+1-1)
  `define QPU_DECINFO_ALU_FMR    `QPU_DECINFO_ALU_FMR_MSB :`QPU_DECINFO_ALU_FMR_LSB 
      `define QPU_DECINFO_ALU_QWAIT_LSB    (`QPU_DECINFO_ALU_FMR_MSB+1)
      `define QPU_DECINFO_ALU_QWAIT_MSB    (`QPU_DECINFO_ALU_QWAIT_LSB+1-1)
  `define QPU_DECINFO_ALU_QWAIT    `QPU_DECINFO_ALU_QWAIT_MSB :`QPU_DECINFO_ALU_QWAIT_LSB 
      `define QPU_DECINFO_ALU_OP2IMM_LSB    (`QPU_DECINFO_ALU_QWAIT_MSB+1)
      `define QPU_DECINFO_ALU_OP2IMM_MSB    (`QPU_DECINFO_ALU_OP2IMM_LSB+1-1)
  `define QPU_DECINFO_ALU_OP2IMM    `QPU_DECINFO_ALU_OP2IMM_MSB :`QPU_DECINFO_ALU_OP2IMM_LSB 
  `define QPU_DECINFO_ALU_WIDTH    (`QPU_DECINFO_ALU_OP2IMM_MSB+1)

   //LSU group
    `define QPU_DECINFO_LSU_LOAD_LSB      `QPU_DECINFO_SUBDECINFO_LSB
    `define QPU_DECINFO_LSU_LOAD_MSB      (`QPU_DECINFO_LSU_LOAD_LSB+1-1)   
  `define QPU_DECINFO_LSU_LOAD      `QPU_DECINFO_LSU_LOAD_MSB   :`QPU_DECINFO_LSU_LOAD_LSB   
    `define QPU_DECINFO_LSU_STORE_LSB      (`QPU_DECINFO_LSU_LOAD_MSB+1)
    `define QPU_DECINFO_LSU_STORE_MSB      (`QPU_DECINFO_LSU_STORE_LSB+1-1)   
  `define QPU_DECINFO_LSU_STORE     `QPU_DECINFO_LSU_STORE_MSB  :`QPU_DECINFO_LSU_STORE_LSB  

  `define QPU_DECINFO_LSU_WIDTH    (`QPU_DECINFO_LSU_STORE_MSB+1)

  // Bxx group
      `define QPU_DECINFO_BJP_BPRDT_LSB `QPU_DECINFO_SUBDECINFO_LSB
      `define QPU_DECINFO_BJP_BPRDT_MSB (`QPU_DECINFO_BJP_BPRDT_LSB+1-1)
  `define QPU_DECINFO_BJP_BPRDT  `QPU_DECINFO_BJP_BPRDT_MSB:`QPU_DECINFO_BJP_BPRDT_LSB
      `define QPU_DECINFO_BJP_BEQ_LSB (`QPU_DECINFO_BJP_BPRDT_MSB+1)
      `define QPU_DECINFO_BJP_BEQ_MSB (`QPU_DECINFO_BJP_BEQ_LSB+1-1)
  `define QPU_DECINFO_BJP_BEQ    `QPU_DECINFO_BJP_BEQ_MSB  :`QPU_DECINFO_BJP_BEQ_LSB  
      `define QPU_DECINFO_BJP_BNE_LSB (`QPU_DECINFO_BJP_BEQ_MSB+1)
      `define QPU_DECINFO_BJP_BNE_MSB (`QPU_DECINFO_BJP_BNE_LSB+1-1)
  `define QPU_DECINFO_BJP_BNE    `QPU_DECINFO_BJP_BNE_MSB  :`QPU_DECINFO_BJP_BNE_LSB  
      `define QPU_DECINFO_BJP_BLT_LSB (`QPU_DECINFO_BJP_BNE_MSB+1)
      `define QPU_DECINFO_BJP_BLT_MSB (`QPU_DECINFO_BJP_BLT_LSB+1-1)
  `define QPU_DECINFO_BJP_BLT    `QPU_DECINFO_BJP_BLT_MSB  :`QPU_DECINFO_BJP_BLT_LSB  
      `define QPU_DECINFO_BJP_BGT_LSB (`QPU_DECINFO_BJP_BLT_MSB+1)
      `define QPU_DECINFO_BJP_BGT_MSB (`QPU_DECINFO_BJP_BGT_LSB+1-1)
  `define QPU_DECINFO_BJP_BGT    `QPU_DECINFO_BJP_BGT_MSB  :`QPU_DECINFO_BJP_BGT_LSB  
  
`define QPU_DECINFO_BJP_WIDTH  (`QPU_DECINFO_BJP_BGT_MSB+1)

  //Quantum Instruction group
      `define QPU_DECINFO_QIU_QOP1_GATE_LSB `QPU_DECINFO_SUBDECINFO_LSB
      `define QPU_DECINFO_QIU_QOP1_GATE_MSB (`QPU_DECINFO_QIU_QOP1_GATE_LSB + 1 - 1)
    `define QPU_DECINFO_QIU_QOP1_GATE `QPU_DECINFO_QIU_QOP1_GATE_MSB : `QPU_DECINFO_QIU_QOP1_GATE_LSB
      `define QPU_DECINFO_QIU_QOP2_GATE_LSB (`QPU_DECINFO_QIU_QOP1_GATE_MSB + 1)
      `define QPU_DECINFO_QIU_QOP2_GATE_MSB (`QPU_DECINFO_QIU_QOP2_GATE_LSB + 1 - 1)
    `define QPU_DECINFO_QIU_QOP1_GATE `QPU_DECINFO_QIU_QOP2_GATE_MSB : `QPU_DECINFO_QIU_QOP2_GATE_LSB
      `define QPU_DECINFO_QIU_OPCODE1_LSB (`QPU_DECINFO_QIU_QOP2_GATE_MSB + 1)
      `define QPU_DECINFO_QIU_OPCODE1_MSB (`QPU_DECINFO_QIU_OPCODE1_LSB + 14 - 1)
    `define QPU_DECINFO_QIU_OPCODE1 `QPU_DECINFO_QIU_OPCODE1_MSB : `QPU_DECINFO_QIU_OPCODE1_LSB
      `define QPU_DECINFO_QIU_OPCODE2_LSB (`QPU_DECINFO_QIU_OPCODE1_MSB + 1)
      `define QPU_DECINFO_QIU_OPCODE2_MSB (`QPU_DECINFO_QIU_OPCODE2_LSB + 14 - 1)
    `define QPU_DECINFO_QIU_OPCODE2 `QPU_DECINFO_QIU_OPCODE2_MSB : `QPU_DECINFO_QIU_OPCODE2_LSB

`define QPU_DECINFO_QIU_WIDTH  (`QPU_DECINFO_QIU_OPCODE2_MSB+1)

`define QPU_DECINFO_WIDTH  (`QPU_DECINFO_QIU_WIDTH)                      ///why is the original code QIU_WIDTH + 1?s? 






                              
`define QPU_DTCM_ADDR_BASE   `QPU_CFG_DTCM_ADDR_BASE 
`define QPU_ITCM_ADDR_BASE   `QPU_CFG_ITCM_ADDR_BASE 
                             

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////// ITCM relevant macro
//
`ifdef QPU_CFG_HAS_ITCM//{
  `define QPU_HAS_ITCM 1
  `define QPU_ITCM_ADDR_WIDTH  `QPU_CFG_ITCM_ADDR_WIDTH
  // The ITCM size is 2^addr_width bytes, and ITCM is 64bits wide (8 bytes)
  //  so the DP is 2^addr_wdith/8
  //  so the AW is addr_wdith - 3
  `define QPU_ITCM_RAM_DP      (1<<(`QPU_CFG_ITCM_ADDR_WIDTH-3)) 
  `define QPU_ITCM_RAM_AW          (`QPU_CFG_ITCM_ADDR_WIDTH-3) 
  `define QPU_ITCM_BASE_REGION  `QPU_ADDR_SIZE-1:`QPU_ITCM_ADDR_WIDTH
  
  `define QPU_CFG_ITCM_DATA_WIDTH_IS_64
  `ifdef QPU_CFG_ITCM_DATA_WIDTH_IS_64
    `define QPU_ITCM_DATA_WIDTH_IS_64
    `define QPU_ITCM_DATA_WIDTH  64
    `define QPU_ITCM_WMSK_WIDTH  8
  
    `define QPU_ITCM_RAM_ECC_DW  8
    `define QPU_ITCM_RAM_ECC_MW  1
  `endif
  `ifndef QPU_HAS_ECC //{
    `define QPU_ITCM_RAM_DW      `QPU_ITCM_DATA_WIDTH
    `define QPU_ITCM_RAM_MW      `QPU_ITCM_WMSK_WIDTH
    `define QPU_ITCM_OUTS_NUM 1 // If no-ECC, ITCM is 1 cycle latency then only allow 1 oustanding for external agent
  `endif//}

  `define QPU_HAS_ITCM_EXTITF
`endif//}

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////// DTCM relevant macro
//
`ifdef QPU_CFG_HAS_DTCM//{
  `define QPU_HAS_DTCM 1
  `define QPU_DTCM_ADDR_WIDTH  `QPU_CFG_DTCM_ADDR_WIDTH
  // The DTCM size is 2^addr_width bytes, and DTCM is 32bits wide (4 bytes)
  //  so the DP is 2^addr_wdith/4
  //  so the AW is addr_wdith - 2
  `define QPU_DTCM_RAM_DP      (1<<(`QPU_CFG_DTCM_ADDR_WIDTH-2)) 
  `define QPU_DTCM_RAM_AW          (`QPU_CFG_DTCM_ADDR_WIDTH-2) 
  `define QPU_DTCM_BASE_REGION `QPU_ADDR_SIZE-1:`QPU_DTCM_ADDR_WIDTH
  
    `define QPU_DTCM_DATA_WIDTH  32
    `define QPU_DTCM_WMSK_WIDTH  4
  
    `define QPU_DTCM_RAM_ECC_DW  7
    `define QPU_DTCM_RAM_ECC_MW  1

  `ifndef QPU_HAS_ECC //{
    `define QPU_DTCM_RAM_DW      `QPU_DTCM_DATA_WIDTH
    `define QPU_DTCM_RAM_MW      `QPU_DTCM_WMSK_WIDTH
    `define QPU_DTCM_OUTS_NUM 1 // If no-ECC, DTCM is 1 cycle latency then only allow 1 oustanding for external agent
  `endif//}


  `define QPU_HAS_DTCM_EXTITF
`endif//}



/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////// LSU relevant macro
//
    // Currently is OITF_DEPTH, In the future, if the ROCC
    // support multiple oustanding
    // we can enlarge this number to 2 or 4
    // Although we defined the OITF depth as 2, but for LSU, we still only allow 1 oustanding for LSU
    `define QPU_LSU_OUTS_NUM    1
    `define QPU_LSU_OUTS_NUM_IS_1
  //`endif//}



