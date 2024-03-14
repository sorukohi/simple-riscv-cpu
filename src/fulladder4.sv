`timescale 1ns / 1ps

module fulladder4 (
  input  logic [3:0] a_i,
  input  logic [3:0] b_i,
  input  logic       carry_i,
  output logic [3:0] sum_o,
  output logic       carry_o
);
  logic [4:0] tmp_carry;
  assign tmp_carry[0] = carry_i; 
  assign carry_o = tmp_carry[4];
  
  for (genvar i = 0; i < 4; i = i + 1) begin : newgen
    fulladder add (
      .a_i    (a_i[i]),
      .b_i    (b_i[i]),
      .carry_i(tmp_carry[i]),
      .sum_o  (sum_o[i]),
      .carry_o(tmp_carry[i+1])
    );
  end
  
endmodule
