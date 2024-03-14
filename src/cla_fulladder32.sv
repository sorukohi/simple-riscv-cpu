`timescale 1ns / 1ps

module cla_fulladder32 (
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,
  input  logic        carry_i,
  output logic [31:0] sum_o,
  output logic        carry_o
);

  logic [8:0] tmp_carry;

  assign tmp_carry[0] = carry_i; 
  assign carry_o = tmp_carry[8];
  
  for (genvar i = 0; i < 8; i = i + 1) begin : newgen
    cla_four add (
      .a_i     ( a_i[4*i+3: 4*i]   ),
      .b_i     ( b_i[4*i+3: 4*i]   ),
      .carry_i ( tmp_carry[i]      ),
      .sum_o   ( sum_o[4*i+3: 4*i] ),
      .carry_o ( tmp_carry[i+1]    )
    );
  end
  
endmodule

