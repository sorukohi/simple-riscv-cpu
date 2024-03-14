`timescale 1ns / 1ps

//`define __for_instr__
//`define __for_cybercobra_tb__
//`define __for_cybercobra_wrapper__
//`define __for_cybercobra_mine__
//`define __for_cybercobra_extra__
//`define __for_riscv_checking__
//`define __for_riscv_mine__
//`define __for_riscv_irq__
//`define __lab_12_sw_led_instr__
//`define __lab_12_ps2_hex_instr__
`define __lab_12_ps2_vga_instr__

module instr_mem (
  input  logic [31:0] addr_i,
  output logic [31:0] read_data_o
);

  logic [31:0] rom [1023:0]; 
  
  `ifdef __for_instr__              initial $readmemh("instr_mem.txt", rom);
  `elsif __for_cybercobra_tb__      initial $readmemh("cybercobra_tb_mem.txt", rom);
  `elsif __for_cybercobra_wrapper__ initial $readmemh("cybercobra_wrapper_mem.txt", rom);
  `elsif __for_cybercobra_mine__    initial $readmemh("cybercobra_mine_mem.txt", rom);
  `elsif __for_cybercobra_extra__   initial $readmemh("cybercobra_extra_mem.txt", rom);
  `elsif __for_riscv_checking__     initial $readmemh("program.txt", rom);
  `elsif __for_riscv_mine__         initial $readmemh("mine_program.txt", rom);
  `elsif __for_riscv_irq__          initial $readmemh("irq_program.txt", rom);
  `elsif __lab_12_sw_led_instr__    initial $readmemh("lab_12_sw_led_instr.mem", rom);
  `elsif __lab_12_ps2_hex_instr__   initial $readmemh("lab_12_ps2_hex_instr.mem", rom);
  `elsif __lab_12_ps2_vga_instr__   initial $readmemh("lab_12_ps2_vga_instr.mem", rom);
  `endif
  
  logic [31:0] cell_addr;
  assign cell_addr = addr_i >> 2; 
  
  logic  addr_in_range;
  assign addr_in_range = (addr_i <= 32'd4095);
  
  always_comb begin
    if (addr_in_range) read_data_o = rom[cell_addr];
    else               read_data_o = 32'b0;
  end
  
endmodule
