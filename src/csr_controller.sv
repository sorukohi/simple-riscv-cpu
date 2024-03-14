`timescale 1ns / 1ps

import csr_pkg::*;

module csr_controller (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,
  
  input  logic [ 2:0] opcode_i,
  
  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,
  
  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);
  
  logic [31:0] data_i_modified;
  
  // Sending on registers modified data 
  always_comb begin
    case (opcode_i)
       CSR_RW  : data_i_modified =  rs1_data_i;
       CSR_RS  : data_i_modified =  rs1_data_i | read_data_o;
       CSR_RC  : data_i_modified = ~rs1_data_i & read_data_o;
       CSR_RWI : data_i_modified =  imm_data_i;
       CSR_RSI : data_i_modified =  imm_data_i | read_data_o;
       CSR_RCI : data_i_modified = ~imm_data_i & read_data_o;
       default : data_i_modified =  rs1_data_i;
    endcase
  end
  
  logic [31:0] mscratch;
  logic [31:0] mcause;
  // Enable signals for registers changing demux: write_enable_i, addr_i 
  logic        mie_en;
  logic        mtvec_en;
  logic        mscratch_en;
  logic        mepc_en;
  logic        mcause_en;
  
  // Registers themselves
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      mie_o    <= 'd0;
      mtvec_o  <= 'd0;
      mscratch <= 'd0;
      mepc_o   <= 'd0;
      mcause   <= 'd0;
    end else begin
      if (mie_en)      mie_o    <= data_i_modified;
      if (mtvec_en)    mtvec_o  <= data_i_modified;
      if (mscratch_en) mscratch <= data_i_modified;

      if (mepc_en || trap_i) begin
        if (trap_i)    mepc_o <= pc_i;
        else           mepc_o <= data_i_modified;
      end 

      if (mcause_en || trap_i) begin
        if (trap_i)    mcause <= mcause_i;
        else           mcause <= data_i_modified;
      end
    end
  end
  
  // Demux enable signal for registers
  always_comb begin
    mie_en      = 1'd0;
    mtvec_en    = 1'd0;
    mscratch_en = 1'd0;
    mepc_en     = 1'd0;
    mcause_en   = 1'd0;
    case (addr_i)
      MIE_ADDR      : mie_en      = write_enable_i;
      MTVEC_ADDR    : mtvec_en    = write_enable_i;
      MSCRATCH_ADDR : mscratch_en = write_enable_i;
      MEPC_ADDR     : mepc_en     = write_enable_i;
      MCAUSE_ADDR   : mcause_en   = write_enable_i;
    endcase
  end
  
  // Mux for read_data_o
  always_comb begin
    case (addr_i)
      MIE_ADDR      : read_data_o = mie_o;
      MTVEC_ADDR    : read_data_o = mtvec_o;
      MSCRATCH_ADDR : read_data_o = mscratch;
      MEPC_ADDR     : read_data_o = mepc_o;
      MCAUSE_ADDR   : read_data_o = mcause;
      default       : read_data_o = 32'd0;
    endcase
  end

endmodule
