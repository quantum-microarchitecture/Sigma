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
                                                                         
                                                                         
                                                                         



`define QPU_CFG_ADDR_SIZE   32

`define QPU_CFG_REGNUM_IS_32
/////////////////////////////////////////////////////////////////
`define QPU_CFG_HAS_ITCM
    // 64KB have address 16bits wide
    //   The depth is 64*1024*8/64=8192
`define QPU_CFG_ITCM_ADDR_WIDTH  16

//    // 1024KB have address 20bits wide
//    //   The depth is 1024*1024*8/64=131072
//`define QPU_CFG_ITCM_ADDR_WIDTH  20

//    // 2048KB have address 21bits wide
//    //   The depth is 2*1024*1024*8/64=262144
//`define QPU_CFG_ITCM_ADDR_WIDTH  21


/////////////////////////////////////////////////////////////////
`define QPU_CFG_HAS_DTCM
    // 16KB have address 14 wide
    //   The depth is 16*1024*8/32=4096

    // 256KB have address 18 wide
    //   The depth is 256*1024*8/32=65536

//    // 1MB have address 20bits wide
//    //   The depth is 1024*1024*8/32=262144

/////////////////////////////////////////////////////////////////
//`define QPU_CFG_REGFILE_LATCH_BASED
//


//
`define QPU_CFG_ITCM_ADDR_BASE   `QPU_CFG_ADDR_SIZE'h8000_0000 
`define QPU_CFG_DTCM_ADDR_BASE   `QPU_CFG_ADDR_SIZE'h9000_0000 


`define QPU_CFG_DTCM_ADDR_WIDTH 16
