`timescale 1ns / 1ps

import riscv_pkg::LDST_B;
import riscv_pkg::LDST_H;
import riscv_pkg::LDST_W;
import riscv_pkg::LDST_BU;
import riscv_pkg::LDST_HU;

module riscv_lsu (
  input logic clk_i,
  input logic rst_i,

  // Интерфейс с ядром
  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,

  // Интерфейс с памятью
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 3:0] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);

  assign mem_req_o  = core_req_i;
  assign mem_we_o   = core_we_i;

  always_comb begin
    unique case (core_size_i)
      LDST_B  : begin
        unique case (core_addr_i[1:0])
          2'b00 : mem_be_o = 4'b0001;
          2'b01 : mem_be_o = 4'b0010;
          2'b10 : mem_be_o = 4'b0100;
          2'b11 : mem_be_o = 4'b1000;
        endcase
      end
      LDST_H  : begin
        unique case (core_addr_i[1])
          1'b0 : mem_be_o = 4'b0011;
          1'b1 : mem_be_o = 4'b1100;
        endcase
      end
      LDST_W  : mem_be_o = 4'b1111;
      default : mem_be_o = 4'b1111;
    endcase
  end
  
  assign mem_addr_o = core_addr_i;
  
  always_comb begin
    unique case (core_size_i)
      LDST_B  : mem_wd_o = {4{core_wd_i[ 7: 0]}};
      LDST_H  : mem_wd_o = {2{core_wd_i[15: 0]}};
      LDST_W  : mem_wd_o = core_wd_i;
      default : mem_wd_o = core_wd_i; 
    endcase
  end
  
  always_comb begin
    unique case (core_size_i)
      LDST_B  : begin
        unique case (core_addr_i[1:0])
          2'b00 : core_rd_o = {{24{mem_rd_i[7]}},  mem_rd_i[ 7: 0]};
          2'b01 : core_rd_o = {{24{mem_rd_i[15]}}, mem_rd_i[15: 8]};
          2'b10 : core_rd_o = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
          2'b11 : core_rd_o = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
        endcase
      end
      LDST_H  : begin
        unique case (core_addr_i[1])
          1'b0 : core_rd_o = {{16{mem_rd_i[15]}}, mem_rd_i[15: 0]};
          1'b1 : core_rd_o = {{16{mem_rd_i[31]}}, mem_rd_i[31:16]};
        endcase
      end
      LDST_W  : core_rd_o = mem_rd_i;
      LDST_BU : begin
        unique case (core_addr_i[1:0])
          2'b00 : core_rd_o = {24'd0, mem_rd_i[ 7: 0]};
          2'b01 : core_rd_o = {24'd0, mem_rd_i[15: 8]};
          2'b10 : core_rd_o = {24'd0, mem_rd_i[23:16]};
          2'b11 : core_rd_o = {24'd0, mem_rd_i[31:24]};
        endcase
      end
      LDST_HU : begin
        unique case (core_addr_i[1])
          1'b0 : core_rd_o = {16'd0, mem_rd_i[15: 0]};
          1'b1 : core_rd_o = {16'd0, mem_rd_i[31:16]};
        endcase
      end
      default : core_rd_o = mem_rd_i;
    endcase
  end

  logic  stall_reg;
  assign stall_reg_next = (core_req_i && ~(stall_reg && mem_ready_i));

  always_ff @(posedge clk_i) begin
    if (rst_i) stall_reg <= 1'd1;
    else       stall_reg <= stall_reg_next;
  end

  assign core_stall_o = stall_reg_next;

endmodule