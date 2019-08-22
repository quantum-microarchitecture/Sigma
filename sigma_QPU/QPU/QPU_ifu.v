//=====================================================================
//
// Designer   : HL
//
// Description:
//  The IFU to implement entire instruction fetch unit.
//
// ====================================================================
`include "QPU_defines.v"

module QPU_ifu(
  output[`QPU_PC_SIZE-1:0] inspect_pc,
  output ifu_active,
  input  itcm_nohold,

  input  [`QPU_PC_SIZE-1:0] pc_rtvec,  


  input  ifu_holdup,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to ITCM, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  output ifu_icb_cmd_valid, // Handshake valid
  input  ifu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [`QPU_ITCM_ADDR_WIDTH-1:0]   ifu_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  input  ifu_icb_rsp_valid, // Response valid 
  output ifu_icb_rsp_ready, // Response ready
            // Note: the RSP rdata is inline with AXI definition
  input  [`QPU_ITCM_DATA_WIDTH-1:0] ifu_icb_rsp_rdata, 



  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The IR stage to EXU interface
  output [`QPU_INSTR_SIZE-1:0] ifu_o_ir,// The instruction register
  output [`QPU_PC_SIZE-1:0] ifu_o_pc,   // The PC register along with
  output ifu_o_pc_vld,
  output [`QPU_RFIDX_WIDTH-1:0] ifu_o_rs1idx,
  output [`QPU_RFIDX_WIDTH-1:0] ifu_o_rs2idx,
  output ifu_o_prdt_taken,               // The Bxx is predicted as taken

  output ifu_o_valid, // Handshake signals with EXU stage
  input  ifu_o_ready,

  output  pipe_flush_ack,
  input   pipe_flush_req,
  input   [`QPU_PC_SIZE-1:0] pipe_flush_add_op1,  
  input   [`QPU_PC_SIZE-1:0] pipe_flush_add_op2,
  `ifdef QPU_TIMING_BOOST//}
  input   [`QPU_PC_SIZE-1:0] pipe_flush_pc,  
  `endif//}

      
  // The halt request come from other commit stage
  //   If the ifu_halt_req is asserting, then IFU will stop fetching new 
  //     instructions and after the oustanding transactions are completed,
  //     asserting the ifu_halt_ack as the response.
  //   The IFU will resume fetching only after the ifu_halt_req is deasserted
  input  ifu_halt_req,
  output ifu_halt_ack,


  input  clk,
  input  rst_n
  );

  
  wire ifu_req_valid; 
  wire ifu_req_ready; 
  wire [`QPU_PC_SIZE-1:0]   ifu_req_pc; 
  wire ifu_req_seq;
  wire ifu_rsp_valid; 
  wire ifu_rsp_ready; 

  //wire ifu_rsp_replay;   
  wire [`QPU_INSTR_SIZE-1:0] ifu_rsp_instr; 

  QPU_ifu_ifetch u_QPU_ifu_ifetch(
    .inspect_pc   (inspect_pc),
    .pc_rtvec      (pc_rtvec),  

    .ifu_req_valid (ifu_req_valid),
    .ifu_req_ready (ifu_req_ready),
    .ifu_req_pc    (ifu_req_pc   ),
    .ifu_req_seq     (ifu_req_seq     ),

    .ifu_rsp_valid (ifu_rsp_valid),
    .ifu_rsp_ready (ifu_rsp_ready),
    .ifu_rsp_instr (ifu_rsp_instr),

    .ifu_o_ir      (ifu_o_ir     ),
    .ifu_o_pc      (ifu_o_pc     ),
    .ifu_o_pc_vld  (ifu_o_pc_vld ),
    .ifu_o_rs1idx  (ifu_o_rs1idx),
    .ifu_o_rs2idx  (ifu_o_rs2idx),
    .ifu_o_prdt_taken(ifu_o_prdt_taken),
    .ifu_o_valid   (ifu_o_valid  ),
    .ifu_o_ready   (ifu_o_ready  ),

    .pipe_flush_ack     (pipe_flush_ack    ), 
    .pipe_flush_req     (pipe_flush_req    ),
    .pipe_flush_add_op1 (pipe_flush_add_op1),     
  `ifdef QPU_TIMING_BOOST//}
    .pipe_flush_pc      (pipe_flush_pc),  
  `endif//}
    .pipe_flush_add_op2 (pipe_flush_add_op2), 
    .ifu_halt_req  (ifu_halt_req ),
    .ifu_halt_ack  (ifu_halt_ack ),

    .clk           (clk          ),
    .rst_n         (rst_n        ) 
  );



  QPU_ifu_ift2icb u_QPU_ifu_ift2icb (
    .ifu_req_valid (ifu_req_valid),
    .ifu_req_ready (ifu_req_ready),
    .ifu_req_pc    (ifu_req_pc   ),
    .ifu_req_seq     (ifu_req_seq     ),

    .ifu_rsp_valid (ifu_rsp_valid),
    .ifu_rsp_ready (ifu_rsp_ready),
    .ifu_rsp_instr (ifu_rsp_instr),
    .itcm_nohold   (itcm_nohold),

    .ifu_icb_cmd_valid(ifu_icb_cmd_valid),
    .ifu_icb_cmd_ready(ifu_icb_cmd_ready),
    .ifu_icb_cmd_addr (ifu_icb_cmd_addr ),

    .ifu_icb_rsp_valid(ifu_icb_rsp_valid),
    .ifu_icb_rsp_ready(ifu_icb_rsp_ready),
    .ifu_icb_rsp_rdata(ifu_icb_rsp_rdata),

    .ifu_holdup (ifu_holdup),


    .clk           (clk          ),
    .rst_n         (rst_n        ) 
  );

  assign ifu_active = 1'b1;// Seems the IFU never rest at block level
  
endmodule





































