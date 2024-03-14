`timescale 1ns / 1ps

module cla_four_fulladder #(
  parameter fulladder_amount = 4
) (
  input  logic [fulladder_amount-1:0] a_i,
  input  logic [fulladder_amount-1:0] b_i,
  input  logic                        carry_i,
  output logic [fulladder_amount-1:0] sum_o,
  output logic                        carry_o
);
  
  logic [fulladder_amount-1:0] G;
  logic [fulladder_amount-1:0] P;
  logic [fulladder_amount-1:0] G_res;
  logic [fulladder_amount-1:0] P_res;
  logic [fulladder_amount-1:0] tmp_carry;
  
  // Initial values
  assign G[0]         = a_i[0] & b_i[0];
  assign P[0]         = a_i[0] ^ b_i[0];
  assign G_res[0]     = G[0] | (P[0] & carry_i);
  assign P_res[0]     = &P[0];
  assign tmp_carry[0] = G_res[0] | (P_res[0] & carry_i);
  assign sum_o[0]     = a_i[0] ^ b_i[0] ^ carry_i;  
  
  // Increasing blocks
  for (genvar i = 1; i < fulladder_amount; i = i + 1) begin : newgen
    assign G[i]         = a_i[i] & b_i[i];
    assign P[i]         = a_i[i] ^ b_i[i]; 
    assign G_res[i]     = G[i] | (P[i] & G_res[i-1]); 
    assign P_res[i]     = &P[i:0];
    assign tmp_carry[i] = G_res[i] | (P_res[i] & carry_i);
    assign sum_o[i]     = a_i[i] ^ b_i[i] ^ tmp_carry[i-1]; 
  end
  
  assign carry_o = tmp_carry[fulladder_amount-1];

endmodule
