`timescale 1ns / 1ps

module fulladder32 (
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,
  input  logic       carry_i,
  output logic [31:0] sum_o,
  output logic       carry_o
);
  logic [8:0] tmp_carry;
  assign tmp_carry[0] = carry_i; 
  assign carry_o = tmp_carry[8];
  
  for (genvar i = 0; i < 32; i = i + 4) begin : newgen
    fulladder4 add (
      .a_i    (a_i[i+3: i]),
      .b_i    (b_i[i+3: i]),
      .carry_i(tmp_carry[i/4]),
      .sum_o  (sum_o[i+3: i]),
      .carry_o(tmp_carry[i/4 + 1])
    );
  end
  
endmodule
