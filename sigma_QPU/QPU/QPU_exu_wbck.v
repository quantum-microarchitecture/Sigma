 /*                                                                      
 Copyright 2018 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  The Write-Back module to arbitrate the write-back request to regfile
//
// ====================================================================

`include "QPU_defines.v"

module QPU_exu_wbck(

  //////////////////////////////////////////////////////////////
  // The ALU Write-Back Interface
  // for classical instr 
  input  alu_cwbck_i_valid,                 //~QWAIT alu instruction
  output alu_cwbck_i_ready, 
  input  [`QPU_XLEN-1:0] alu_cwbck_i_data,   //for time reg and classical reg
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] alu_cwbck_i_rdidx,  //for time reg and classical reg

  input  alu_qcwbck_i_valid,                 
  output alu_qcwbck_i_ready, 
  input  [`QPU_XLEN-1:0] alu_qcwbck_i_data,   
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] alu_qcwbck_i_rdidx,  



  //for qwait instr
  input  alu_twbck_i_valid,  //new time point, QWAIT or QI & PI>0
  output alu_twbck_i_ready,
  input  [`QPU_TIME_WIDTH - 1 : 0] alu_twbck_i_data,

  //for quantum instr
  input alu_ewbck_i_valid,
  output alu_ewbck_i_ready,
  input [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] alu_ewbck_i_data,
  input [(`QPU_EVENT_NUM - 1) : 0] alu_ewbck_i_oprand,
 




  //////////////////////////////////////////////////////////////
  // The Final arbitrated Write-Back Interface to Regfile
  output  crf_wbck_o_ena,
  output  [`QPU_XLEN-1:0] crf_wbck_o_data,
  output  [`QPU_RFIDX_REAL_WIDTH-1:0] crf_wbck_o_rdidx,

  output  qcrf_wbck_o_ena,
  output  [`QPU_XLEN-1:0] qcrf_wbck_o_data,
  output  [`QPU_RFIDX_REAL_WIDTH-1:0] qcrf_wbck_o_rdidx,

  output trf_wbck_o_ena,
  output [`QPU_TIME_WIDTH - 1 : 0] trf_wbck_o_data,

  output erf_wbck_o_ena,
  output [(`QPU_EVENT_WIRE_WIDTH - 1) : 0] erf_wbck_o_data,
  output [(`QPU_EVENT_NUM - 1) : 0] erf_wbck_o_oprand,

  output tiq_wbck_o_ena,
  input  tiq_wbck_o_ready,
  output [`QPU_TIME_WIDTH - 1 : 0] tiq_wbck_o_data,

  output evq_wbck_o_ena,
  input  evq_wbck_o_ready


  );

  //////////////////////////////////////////////////////////////
  // The Final arbitrated classical reg Write-Back Interface


  wire crf_wbck_o_ready = 1'b1; // Regfile is always ready to be write because it just has 1 w-port


  assign alu_cwbck_i_ready   = crf_wbck_o_ready;

  
  wire crf_wbck_o_valid = alu_cwbck_i_valid;


  
  assign crf_wbck_o_ena   = crf_wbck_o_valid & crf_wbck_o_ready;
  assign crf_wbck_o_data  = alu_cwbck_i_data;
  assign crf_wbck_o_rdidx = alu_cwbck_i_rdidx;

  wire   qcrf_wbck_o_ready = 1'b1;
  assign qcrf_wbck_o_valid = alu_qcwbck_i_valid;
  assign alu_qcwbck_i_ready = qcrf_wbck_o_ready;
  
  assign qcrf_wbck_o_ena   = qcrf_wbck_o_valid & qcrf_wbck_o_ready;
  assign qcrf_wbck_o_data  = alu_qcwbck_i_data;
  assign qcrf_wbck_o_rdidx = alu_qcwbck_i_rdidx;



  //////////////////////////////////////////////////////////////
  // The Final arbitrated time reg Write-Back Interface
  wire trf_wbck_o_ready = tiq_wbck_o_ready & evq_wbck_o_ready;     //time and event queue are ~full
  assign alu_twbck_i_ready = trf_wbck_o_ready;
  
  wire trf_wbck_o_valid = alu_twbck_i_valid;

  assign  trf_wbck_o_ena   = trf_wbck_o_valid & trf_wbck_o_ready;
  assign  trf_wbck_o_data  = alu_twbck_i_data;

  //////////////////////////////////////////////////////////////
  // The Final arbitrated time reg Write-Back Interface    
  

  wire erf_wbck_o_ready = tiq_wbck_o_ready & evq_wbck_o_ready;
  assign alu_ewbck_i_ready = erf_wbck_o_ready;

  wire erf_wbck_o_valid = alu_ewbck_i_valid | alu_twbck_i_valid;                 //QI or QWAIT

  assign erf_wbck_o_ena = erf_wbck_o_valid & erf_wbck_o_ready;

  assign erf_wbck_o_data = alu_ewbck_i_data;
  assign erf_wbck_o_oprand = alu_ewbck_i_oprand;

  //////////////////////////////////////////////////////////////
  // time and event queue Write-Back Interface
  assign evq_wbck_o_ena = alu_twbck_i_valid & evq_wbck_o_ready & tiq_wbck_o_ready;          //ntp=1
  assign tiq_wbck_o_ena = alu_twbck_i_valid & evq_wbck_o_ready & tiq_wbck_o_ready;
  assign tiq_wbck_o_data = alu_twbck_i_data;


endmodule                                      
                                               
                                               
                                               
