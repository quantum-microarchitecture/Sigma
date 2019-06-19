                                                                                                                                      
//=====================================================================
//
// Designer   : QI ZHOU
//
// Description:
//  This module to implement the datapath of ALU
//
// ====================================================================
`include "QPU_defines.v"

module QPU_exu_alu_dpath(

  //////////////////////////////////////////////////////
  // ALU request the datapath
  input  alu_req_alu,

  input  alu_req_alu_add ,
  input  alu_req_alu_xor ,
  input  alu_req_alu_or  ,
  input  alu_req_alu_and ,
  input  [`QPU_XLEN-1:0] alu_req_alu_op1,
  input  [`QPU_XLEN-1:0] alu_req_alu_op2,

  output [`QPU_XLEN-1:0] alu_req_alu_res,

  //////////////////////////////////////////////////////
  // BJP request the datapath
  input  bjp_req_alu,

  input  [`QPU_XLEN-1:0] bjp_req_alu_op1,
  input  [`QPU_XLEN-1:0] bjp_req_alu_op2,
  input  bjp_req_alu_cmp_eq ,
  input  bjp_req_alu_cmp_ne ,
  input  bjp_req_alu_cmp_lt ,
  input  bjp_req_alu_cmp_gt ,

  output bjp_req_alu_cmp_res,

  //////////////////////////////////////////////////////
  // LSU request the datapath
  input  lsu_req_alu,

  input  [`QPU_XLEN-1:0] lsu_req_alu_op1,
  input  [`QPU_XLEN-1:0] lsu_req_alu_op2,

  output [`QPU_XLEN-1:0] lsu_req_alu_res,

  ////////////////////////////////////////////////////
  // QIU request the datapath
  input qiu_req_alu,
  
  input  [`QPU_XLEN-1:0] qiu_req_alu_op1,
  input  [`QPU_XLEN-1:0] qiu_req_alu_op2,

  output [`QPU_XLEN-1:0] qiu_req_alu_res


  );


  wire [`QPU_XLEN-1:0] mux_op1;
  wire [`QPU_XLEN-1:0] mux_op2;

  wire [`QPU_XLEN-1:0] misc_op1 = mux_op1[`QPU_XLEN-1:0];
  wire [`QPU_XLEN-1:0] misc_op2 = mux_op2[`QPU_XLEN-1:0];



  wire op_add;
  wire op_sub = op_cmp_lt | op_cmp_gt;
  wire op_addsub = op_add | op_sub; 

  wire op_or;
  wire op_xor;
  wire op_and;



  wire op_cmp_eq ;
  wire op_cmp_ne ;
  wire op_cmp_lt ;
  wire op_cmp_gt ;

  wire cmp_res;




  //////////////////////////////////////////////////////////////
  // Impelment the Adder
  //
  // The Adder will be reused to handle the add/sub/compare op

     // Only the MULDIV request ALU-adder with 35bits operand with sign extended 
     // already, all other unit request ALU-adder with 32bits opereand without sign extended
     //   For non-MULDIV operands

  wire [`QPU_ALU_ADDER_WIDTH - 1 : 0] adder_op1 =
      {{`QPU_ALU_ADDER_WIDTH - `QPU_XLEN{misc_op1[`QPU_XLEN - 1]}},misc_op1};
  wire [`QPU_ALU_ADDER_WIDTH - 1 : 0] adder_op2 =
      {{`QPU_ALU_ADDER_WIDTH - `QPU_XLEN{misc_op2[`QPU_XLEN - 1]}},misc_op2};


  wire adder_cin;
  wire [`QPU_ALU_ADDER_WIDTH-1:0] adder_in1;
  wire [`QPU_ALU_ADDER_WIDTH-1:0] adder_in2;
  wire [`QPU_ALU_ADDER_WIDTH-1:0] adder_res;

  wire adder_add;
  wire adder_sub;

  assign adder_add =  op_add; 
  assign adder_sub =  op_cmp_lt | op_cmp_gt;

  wire adder_addsub = adder_add | adder_sub; 
  

  assign adder_in1 = {`QPU_ALU_ADDER_WIDTH{adder_addsub}} & (adder_op1);
  assign adder_in2 = {`QPU_ALU_ADDER_WIDTH{adder_addsub}} & (adder_sub ? (~adder_op2) : adder_op2);
  assign adder_cin = adder_addsub & adder_sub;

  assign adder_res = adder_in1 + adder_in2 + adder_cin;



  //////////////////////////////////////////////////////////////
  // Impelment the XOR-er
  //
  // The XOR-er will be reused to handle the XOR and compare op

  wire [`QPU_XLEN - 1 : 0] xorer_in1;
  wire [`QPU_XLEN - 1 : 0] xorer_in2;

  wire xorer_op = op_xor | (op_cmp_eq | op_cmp_ne); 

  assign xorer_in1 = {`QPU_XLEN{xorer_op}} & misc_op1;
  assign xorer_in2 = {`QPU_XLEN{xorer_op}} & misc_op2;

  wire [`QPU_XLEN-1:0] xorer_res = xorer_in1 ^ xorer_in2;
     // The OR and AND is too light-weight, so no need to gate off
  wire [`QPU_XLEN-1:0] orer_res  = misc_op1 | misc_op2; 
  wire [`QPU_XLEN-1:0] ander_res = misc_op1 & misc_op2; 


  //////////////////////////////////////////////////////////////
  // Generate the CMP operation result
       // It is Non-Equal if the XOR result have any bit non-zero
  wire neq  = (|xorer_res); 
  wire cmp_res_ne  = (op_cmp_ne  & neq);
       // It is Equal if it is not Non-Equal
  wire cmp_res_eq  = op_cmp_eq  & (~neq);
       // It is Less-Than if the adder result is negative
  wire cmp_res_lt  = op_cmp_lt  & adder_res[`QPU_XLEN];
       // It is Greater-Than if the adder result is postive
  wire op1_gt_op2  = (~adder_res[`QPU_XLEN]);
  wire cmp_res_gt  = op_cmp_gt  & op1_gt_op2;

  assign cmp_res = cmp_res_eq 
                 | cmp_res_ne 
                 | cmp_res_lt 
                 | cmp_res_gt  ;

 

  //////////////////////////////////////////////////////////////
  // Generate the final result
  wire [`QPU_XLEN-1:0] alu_dpath_res = 
        ({`QPU_XLEN{op_or       }} & orer_res )
      | ({`QPU_XLEN{op_and      }} & ander_res)
      | ({`QPU_XLEN{op_xor      }} & xorer_res)
      | ({`QPU_XLEN{op_addsub   }} & adder_res[`QPU_XLEN-1:0])
        ;

  /////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////
  //  The ALU-Datapath Mux for the requestors 
  // for LSU,only add to get the real address
  localparam DPATH_MUX_WIDTH = ((`QPU_XLEN*2)+8);

  assign  {
     mux_op1
    ,mux_op2
    ,op_add
    ,op_or
    ,op_xor
    ,op_and
    ,op_cmp_eq 
    ,op_cmp_ne 
    ,op_cmp_lt 
    ,op_cmp_gt 
    }
    = 
        ({DPATH_MUX_WIDTH{alu_req_alu}} & {
             alu_req_alu_op1
            ,alu_req_alu_op2
            ,alu_req_alu_add
            ,alu_req_alu_or
            ,alu_req_alu_xor
            ,alu_req_alu_and
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
        })
      | ({DPATH_MUX_WIDTH{bjp_req_alu}} & {
             bjp_req_alu_op1
            ,bjp_req_alu_op2
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,bjp_req_alu_cmp_eq 
            ,bjp_req_alu_cmp_ne 
            ,bjp_req_alu_cmp_lt 
            ,bjp_req_alu_cmp_gt 
        })
      | ({DPATH_MUX_WIDTH{lsu_req_alu}} & {
             lsu_req_alu_op1
            ,lsu_req_alu_op2
            ,1'b1
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
        })

      | ({DPATH_MUX_WIDTH{qiu_req_alu}} & {
             qiu_req_alu_op1
            ,qiu_req_alu_op2
            ,1'b1
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
        })
        ;
        
  assign alu_req_alu_res     = alu_dpath_res[`QPU_XLEN-1:0];
  assign lsu_req_alu_res     = alu_dpath_res[`QPU_XLEN-1:0];
  assign qiu_req_alu_res     = alu_dpath_res[`QPU_XLEN-1:0];
  assign bjp_req_alu_cmp_res = cmp_res;


endmodule                                      
                                               
                                               
                                               
