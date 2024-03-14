`timescale 1ns / 1ps

module cla_four (
  input  logic [3:0] a_i,
  input  logic [3:0] b_i,
  input  logic       carry_i,
  output logic [3:0] sum_o,
  output logic       carry_o
);
  
  logic [3:0] P;
  logic [3:0] G;
  
  for (genvar i = 0; i < 4; i = i + 1) begin : newgen
    assign P[i] = a_i[i] ^ b_i[i];
    assign G[i] = a_i[i] & b_i[i];
  end
  
  logic [3:0] carry_inter;
  
	assign carry_inter[0] = G[0] | (P[0] & carry_i);
	assign carry_inter[1] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & carry_i);
	assign carry_inter[2] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & carry_i);
	assign carry_inter[3] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & carry_i);
	assign carry_o = carry_inter[3];
					           
  assign sum_o[0] = P[0] ^ carry_i;
  assign sum_o[1] = P[1] ^ carry_inter[0];
  assign sum_o[2] = P[2] ^ carry_inter[1];
  assign sum_o[3] = P[3] ^ carry_inter[2];

endmodule