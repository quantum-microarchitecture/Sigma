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
// Designer   : Bob Hu
//
// Description:
//  The simulation model of SRAM
//
// ====================================================================

`include "../tb/tb_define.v"

module sirv_sim_itcm_ram 
#(parameter DP = 512,
  parameter FORCE_X2ZERO = 0,
  parameter DW = 64,
  parameter MW = 4,
  parameter AW = 32 
)
(
  input             clk, 
  input  [DW-1  :0] din, 
  input  [AW-1  :0] addr,
  input             cs,
  input             we,
  input  [MW-1:0]   wem,
  output [DW-1:0]   dout
);

    reg [DW-1:0] mem_r [0:DP-1];
    reg [AW-1:0] addr_r;
    wire [MW-1:0] wen;
    wire ren;

    assign ren = cs & (~we);
    assign wen = ({MW{cs & we}} & wem);

    initial
    begin
      mem_r[0][DW-1:0] = 64'b0;
      mem_r[1][DW-1:0]  = {`SMIS_S13_001111,`SMIS_S14_000101};
      mem_r[2][DW-1:0]  = {`T0_GATE0_S0_XYGATE_H_S13,`T1_ZGATE_Z_XYGATE0};
      mem_r[3][DW-1:0]  = {`T1_ZGATE_1_S0_GATE0,`T4_XYGATE_Y_S2_XYGATE_X_S1};
      mem_r[4][DW-1:0]  = {`T0_XYGATE_Y90_S4_XYGATE_X90_S3,`T1_GATE0_S0_MEASURE_S14};
      mem_r[5][DW-1:0]  = {`QWAIT_4,`FMR_R2_S3};
      mem_r[6][DW-1:0] = {`ADDI_R3_R0_01010,`ADDI_R4_R0_01100};
      mem_r[7][DW-1:0] = {`ADDI_R5_R0_10000,`STORE_R3_R0_00011};
      mem_r[8][DW-1:0] = {`LOAD_R6_R0_00011,`STORE_R4_R5_00001};
      mem_r[9][DW-1:0] = {`LOAD_R7_R5_00001,`STORE_R5_R7_00010};
      mem_r[10][DW-1:0] = {`LOAD_R8_R0_00011,`ADDI_R8_R0_00001};
      mem_r[11][DW-1:0] = `instr_WFI;
    end


    genvar i;

    always @(posedge clk)
    begin
        if (ren) begin
            addr_r <= addr;
        end
    end

    generate
      for (i = 0; i < MW; i = i+1) begin :mem
        if((8*i+8) > DW ) begin: last
          always @(posedge clk) begin
            if (wen[i]) begin
               mem_r[addr][DW-1:8*i] <= din[DW-1:8*i];
            end
          end
        end
        else begin: non_last
          always @(posedge clk) begin
            if (wen[i]) begin
               mem_r[addr][8*i+7:8*i] <= din[8*i+7:8*i];
            end
          end
        end
      end
    endgenerate

  wire [DW-1:0] dout_pre;
  assign dout_pre = mem_r[addr_r];

  generate
   if(FORCE_X2ZERO == 1) begin: force_x_to_zero
      for (i = 0; i < DW; i = i+1) begin:force_x_gen 
          `ifndef SYNTHESIS//{
         assign dout[i] = (dout_pre[i] === 1'bx) ? 1'b0 : dout_pre[i];
          `else//}{
         assign dout[i] = dout_pre[i];
          `endif//}
      end
   end
   else begin:no_force_x_to_zero
     assign dout = dout_pre;
   end
  endgenerate

 
endmodule


module sirv_sim_dtcm_ram 
#(parameter DP = 512,
  parameter FORCE_X2ZERO = 0,
  parameter DW = 32,
  parameter MW = 4,
  parameter AW = 32 
)
(
  input             clk, 
  input  [DW-1  :0] din, 
  input  [AW-1  :0] addr,
  input             cs,
  input             we,
  input  [MW-1:0]   wem,
  output [DW-1:0]   dout
);

    reg [DW-1:0] mem_r [0:DP-1];
    reg [AW-1:0] addr_r;
    wire [MW-1:0] wen;
    wire ren;

    assign ren = cs & (~we);
    assign wen = ({MW{cs & we}} & wem);



    genvar i;

    always @(posedge clk)
    begin
        if (ren) begin
            addr_r <= addr;
        end
    end

    generate
      for (i = 0; i < MW; i = i+1) begin :mem
        if((8*i+8) > DW ) begin: last
          always @(posedge clk) begin
            if (wen[i]) begin
               mem_r[addr][DW-1:8*i] <= din[DW-1:8*i];
            end
          end
        end
        else begin: non_last
          always @(posedge clk) begin
            if (wen[i]) begin
               mem_r[addr][8*i+7:8*i] <= din[8*i+7:8*i];
            end
          end
        end
      end
    endgenerate

  wire [DW-1:0] dout_pre;
  assign dout_pre = mem_r[addr_r];

  generate
   if(FORCE_X2ZERO == 1) begin: force_x_to_zero
      for (i = 0; i < DW; i = i+1) begin:force_x_gen 
          `ifndef SYNTHESIS//{
         assign dout[i] = (dout_pre[i] === 1'bx) ? 1'b0 : dout_pre[i];
          `else//}{
         assign dout[i] = dout_pre[i];
          `endif//}
      end
   end
   else begin:no_force_x_to_zero
     assign dout = dout_pre;
   end
  endgenerate

 
endmodule

