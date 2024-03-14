`timescale 1ns / 1ps


`define __lab_12_ps2ascii_data__

module ext_mem (
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [ 3:0] byte_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o
);

  // memory initialization
  logic [31:0] mem [4095:0];
  `ifdef __lab_12_ps2ascii_data__
    initial $readmemh("lab_12_ps2ascii_data.mem", mem);
  `endif
  
  // input address divided by 4 due to byte-addressing
  logic [31:0] cell_addr;
  assign       cell_addr = addr_i >> 2; 
  
  // allowing range for reading
  logic  good_range;
  assign good_range = (addr_i < 32'd16384) && (addr_i >= 32'd0);
  
  // synchronous read
  logic [31:0] sync_read_data;  
  always_ff @(posedge clk_i) begin
    if (mem_req_i) sync_read_data <= mem[cell_addr];
    else           sync_read_data <= 'd0;
  end
  
  // synchronous write
  always_ff @(posedge clk_i) begin 
    if (mem_req_i && write_enable_i && good_range) begin
      if (byte_enable_i[3]) mem[cell_addr][31:24] <= write_data_i[31:24];
      if (byte_enable_i[2]) mem[cell_addr][23:16] <= write_data_i[23:16];
      if (byte_enable_i[1]) mem[cell_addr][15: 8] <= write_data_i[15: 8];
      if (byte_enable_i[0]) mem[cell_addr][ 7: 0] <= write_data_i[ 7: 0];
    end
  end
  
  logic [1:0] selector;
  
  localparam NOT_READING = 2'b00; // access to memory not allowed or occuring writing
  localparam READING     = 2'b01; // occuring reading
  localparam BAD         = 2'b10; // bad range for reading
  
  // manager signal for multiplexer which choose signal for output 
  always_comb begin
    if      (!mem_req_i || write_enable_i) selector = NOT_READING;
    else if (mem_req_i && good_range)      selector = READING;
    else                                   selector = BAD;
  end
  
  // multiplexer which choose signal for output 
  always_comb begin
    unique case (selector)
      NOT_READING : read_data_o = 32'hfa11_1eaf;
      READING     : read_data_o = sync_read_data;
      BAD         : read_data_o = 32'hdead_beef;
      default     : read_data_o = read_data_o;
    endcase
  end
  
  assign ready_o = 'd1;
  
endmodule