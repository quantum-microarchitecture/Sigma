                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  This module to implement the QIU instructions
//
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_alu_qiu(

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Handshake Interface 
  //
  input  qiu_i_valid, // Handshake valid
  output qiu_i_ready, // Handshake ready

  input  [`QPU_QUBIT_NUM - 1 : 0] qiu_i_rs1,      ///SMIS的有效位数为QUBIT_NUM位，输入的时候也要输入相同的位数！！！
  input  [`QPU_QUBIT_NUM - 1 : 0] qiu_i_rs2,
  input  [`QPU_XLEN - 1 : 0] qiu_i_imm,
  

  input  [`QPU_DECINFO_QIU_WIDTH-1:0] qiu_i_info,
  input  qiu_i_measure,
  input  qiu_i_ntp,
  input  [`QPU_EVENT_WIRE_WIDTH - 1 : 0] qiu_i_edata,               ///reg->disp->qiu
  input  [`QPU_EVENT_NUM - 1 : 0] qiu_i_oprand,                    ///reg->disp->qiu
  input  [`QPU_TIME_WIDTH - 1 : 0] qiu_i_clk,
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The QIU Write-back/Commit Interface
  output qiu_o_valid, // Handshake valid
  input  qiu_o_ready, // Handshake ready

  output [`QPU_EVENT_WIRE_WIDTH - 1 : 0] qiu_o_wbck_edata,
  output [`QPU_EVENT_NUM - 1 : 0] qiu_o_wbck_oprand,                
  output [`QPU_TIME_WIDTH - 1 : 0] qiu_o_wbck_tdata,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // To share the ALU datapath
  // 
  // The operands and info for QIU
 
  output [`QPU_XLEN-1:0] qiu_req_alu_op1,
  output [`QPU_XLEN-1:0] qiu_req_alu_op2,


  input  [`QPU_XLEN-1:0] qiu_req_alu_res


  );
  

  wire [`QPU_QI_EVENT_WIDTH - 1 : 0] opcode1 = qiu_i_info[`QPU_DECINFO_QIU_OPCODE1];
  wire [`QPU_QI_EVENT_WIDTH - 1 : 0] opcode2 = qiu_i_info[`QPU_DECINFO_QIU_OPCODE2];

  genvar i;
  generate
    for(i = 0 ; i< `QPU_EVENT_NUM ; i = i + 1) begin
      ///对于非测量指令，event oprand 的对应位，表示该比特是否做操作，opcode为操作波形的地址
      if (i < `QPU_QI_EVENT_NUM) begin
        assign qiu_o_wbck_oprand[i] = (~qiu_i_measure) & (qiu_i_rs1[i] | qiu_i_rs2[i] | (qiu_i_oprand[i] & (~qiu_i_ntp)));
        assign qiu_o_wbck_edata[((i+1)*`QPU_QI_EVENT_WIDTH) - 1 : i*`QPU_QI_EVENT_WIDTH] = 
        ({`QPU_QI_EVENT_WIDTH{~qiu_i_measure}}) & ( ({`QPU_QI_EVENT_WIDTH{qiu_i_rs1[i]}} & opcode1) | ({`QPU_QI_EVENT_WIDTH{qiu_i_rs2[i]}} & opcode2) | (qiu_i_edata[((i+1)*`QPU_QI_EVENT_WIDTH) - 1 : i*`QPU_QI_EVENT_WIDTH] & {`QPU_QI_EVENT_WIDTH{~qiu_i_ntp}}) );
      end

      ///对于测量指令，event oprand 的对应位，表示该该操作为测量操作，opcode为执行测量操作的比特掩码
      else begin
        assign qiu_o_wbck_oprand[i] = qiu_i_measure;
        assign qiu_o_wbck_edata[`QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (i-`QPU_QI_EVENT_NUM + 1) * `QPU_MEASURE_EVENT_WIDTH - 1 : `QPU_QI_EVENT_NUM * `QPU_QI_EVENT_WIDTH + (i-`QPU_QI_EVENT_NUM) * `QPU_MEASURE_EVENT_WIDTH] = ({`QPU_MEASURE_EVENT_WIDTH{qiu_i_measure}}) & qiu_i_rs1;

      end


    end 


  endgenerate
  assign qiu_o_valid = qiu_i_valid;
  assign qiu_i_ready = qiu_o_ready;

  assign qiu_req_alu_op1 = {{`QPU_XLEN - `QPU_TIME_WIDTH{1'b0}},qiu_i_clk};
  assign qiu_req_alu_op2 = qiu_i_imm;
  assign qiu_o_wbck_tdata = qiu_req_alu_res[`QPU_TIME_WIDTH - 1 : 0];



  

endmodule
