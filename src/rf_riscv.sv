`timescale 1ns / 1ps

module rf_riscv (
  input  logic        clk_i,
  
  input  logic        write_enable_i,
  input  logic [ 4:0] write_addr_i,
  input  logic [31:0] write_data_i,
    
  input  logic [ 4:0] read_addr1_i,
  input  logic [ 4:0] read_addr2_i,
  output logic [31:0] read_data1_o,
  output logic [31:0] read_data2_o
);

  logic [31:0] rf_mem [31:0];
  always_ff @(posedge clk_i) if (write_enable_i) rf_mem[write_addr_i] <= write_data_i;
  
  assign read_data1_o = (read_addr1_i == 5'b0) ? 5'b0 : rf_mem[read_addr1_i];
  assign read_data2_o = (read_addr2_i == 5'b0) ? 5'b0 : rf_mem[read_addr2_i];

endmodule
