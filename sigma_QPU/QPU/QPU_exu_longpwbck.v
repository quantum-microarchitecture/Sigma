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
// Designer   : QI ZHOU
//
// Description:
//  The Write-Back module to arbitrate the write-back request from all 
//  long pipe modules
//
// ====================================================================

`include "QPU_defines.v"

module QPU_exu_longpwbck(




  //////////////////////////////////////////////////////////////
  // The LSU Write-Back Interface
  input  lsu_wbck_i_valid, // Handshake valid
  output lsu_wbck_i_ready, // Handshake ready
  input  [`QPU_XLEN-1:0] lsu_wbck_i_data,


  //////////////////////////////////////////////////////////////
  // The Long pipe instruction Wback interface to final wbck module
  output longp_wbck_o_valid, // Handshake valid
  input  longp_wbck_o_ready, // Handshake ready
  output [`QPU_XLEN-1:0] longp_wbck_o_data,
  output [`QPU_RFIDX_REAL_WIDTH -1:0] longp_wbck_o_rdidx,

 
  //The itag of toppest entry of OITF
  input  [`QPU_RFIDX_REAL_WIDTH-1:0] oitf_ret_rdidx,
  input  oitf_ret_rdwen,     
  output oitf_ret_ena,

  input  clk,
  input  rst_n
  );


  //////////////////////////////////////////////////////////////
  // The Final arbitrated Write-Back Interface
  wire need_wbck = oitf_ret_rdwen;
  
  wire wbck_i_valid;
  wire wbck_i_ready;

  assign wbck_i_valid = lsu_wbck_i_valid;
  assign wbck_i_ready = (need_wbck ? longp_wbck_o_ready : 1'b1);
  
  assign lsu_wbck_i_ready = wbck_i_ready;
  assign longp_wbck_o_valid = need_wbck & wbck_i_valid; 

 
  assign longp_wbck_o_data  = lsu_wbck_i_data;
  assign longp_wbck_o_rdidx = oitf_ret_rdidx;


  assign oitf_ret_ena = wbck_i_valid & wbck_i_ready;           

endmodule                                      
                                               
                                               
                                               
