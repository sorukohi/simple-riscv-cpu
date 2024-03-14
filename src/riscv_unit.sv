`timescale 1ns / 1ps

// `define __SW_INT__;
`define __PS2_INT__;
//`define __UART_RX_INT__;

module riscv_unit (
  input  logic        clk_i,
  input  logic        resetn_i,

  // Входы и выходы периферии
  input  logic [15:0] sw_i,       // Переключатели

  output logic [15:0] led_o,      // Светодиоды

  input  logic        kclk_i,     // Тактирующий сигнал клавиатуры
  input  logic        kdata_i,    // Сигнал данных клавиатуры

  output logic [ 6:0] hex_led_o,  // Вывод семисегментных индикаторов
  output logic [ 7:0] hex_sel_o,  // Селектор семисегментных индикаторов

  input  logic        rx_i,       // Линия приема по UART
  output logic        tx_o,       // Линия передачи по UART

  output logic [3:0]  vga_r_o,    // красный канал vga
  output logic [3:0]  vga_g_o,    // зеленый канал vga
  output logic [3:0]  vga_b_o,    // синий канал vga
  output logic        vga_hs_o,   // линия горизонтальной синхронизации vga
  output logic        vga_vs_o    // линия вертикальной синхронизации vga
);
  
  logic sysclk, rst;

  sys_clk_rst_gen divider (
    .ex_clk_i     ( clk_i    ),
    .ex_areset_n_i( resetn_i ),
    .div_i        ( 10       ),
    .sys_clk_o    ( sysclk   ),
    .sys_reset_o  ( rst      )
  );

  logic [31:0] instr_addr;
  logic [31:0] instr;

  instr_mem in_mem (
    .addr_i     ( instr_addr ),
    .read_data_o( instr      )
  );

  logic        core_stall;
  logic [31:0] core_rd;
  logic [31:0] core_addr;
  logic [ 2:0] core_size;
  logic        core_req;
  logic        core_we;
  logic [31:0] core_wd;

  logic        irq_req;
  logic        irq_ret;

  logic        sw_int_req;
  logic        ps2_int_req;
  logic        uart_rx_int_req;

  riscv_core core (
    .clk_i        ( sysclk         ),
    .rst_i        ( rst            ),

    .stall_i      ( core_stall     ),
    .instr_i      ( instr          ),
    .mem_rd_i     ( core_rd        ),

    `ifdef __SW_INT__
      .irq_req_i  ( sw_int_req      ),
    `elsif __PS2_INT__
      .irq_req_i  ( ps2_int_req     ),
    `elsif __UART_RX_INT__
      .irq_req_i  ( uart_rx_int_req ),
    `endif
    
    .instr_addr_o ( instr_addr      ),
    .mem_addr_o   ( core_addr       ),
    .mem_size_o   ( core_size       ),
    .mem_req_o    ( core_req        ),
    .mem_we_o     ( core_we         ),
    .mem_wd_o     ( core_wd         ),
    .irq_ret_o    ( irq_ret         )
  );

  logic        lsu_req;
  logic [31:0] lsu_addr;
  logic [ 2:0] lsu_size;
  logic [31:0] lsu_wd;
  logic        lsu_we;
  logic [ 3:0] lsu_be;

  logic [31:0] ext_rd;
  logic        mem_ready;

  riscv_lsu lsu (
    .clk_i        ( sysclk     ),
    .rst_i        ( rst        ),
 
    .core_req_i   ( core_req   ),
    .core_we_i    ( core_we    ),
    .core_size_i  ( core_size  ),
    .core_addr_i  ( core_addr  ),
    .core_wd_i    ( core_wd    ),
    .core_rd_o    ( core_rd    ),
    .core_stall_o ( core_stall ),
 
    .mem_req_o    ( lsu_req    ),
    .mem_we_o     ( lsu_we     ),
    .mem_be_o     ( lsu_be     ),
    .mem_addr_o   ( lsu_addr   ),
    .mem_wd_o     ( lsu_wd     ),
    .mem_rd_i     ( ext_rd     ),
    .mem_ready_i  ( mem_ready  )
  );

  logic [31:0] ext_dvc_addr;
  assign       ext_dvc_addr    = {8'd0, lsu_addr[23:0]};

  logic  [7:0] ext_rd_selector;
  assign       ext_rd_selector = lsu_addr[31:24]; 

  always_comb begin
    case (ext_rd_selector)
      8'h00   : ext_rd = mem_rd;
      8'h01   : ext_rd = sw_rd;
      8'h02   : ext_rd = led_rd;
      8'h03   : ext_rd = ps2_rd;
      8'h04   : ext_rd = hex_rd;
      8'h05   : ext_rd = uart_rx_rd;
      8'h06   : ext_rd = uart_tx_rd;
      8'h07   : ext_rd = vga_rd;
      default : ext_rd = mem_rd;
    endcase
  end

  logic [7:0] ext_dvc_ptr;
  assign      ext_dvc_ptr = 8'b0000_0001 << ext_rd_selector;

  logic [31:0] mem_rd;
  logic [31:0] sw_rd;
  logic [31:0] led_rd;
  logic [31:0] ps2_rd;
  logic [31:0] hex_rd;
  logic [31:0] uart_rx_rd;
  logic [31:0] uart_tx_rd;
  logic [31:0] vga_rd;

  ext_mem dt_mem (
    .clk_i          ( sysclk                    ),
    .mem_req_i      ( lsu_req && ext_dvc_ptr[0] ),
    .write_enable_i ( lsu_we                    ),
    .byte_enable_i  ( lsu_be                    ),
    .addr_i         ( ext_dvc_addr              ),
    .write_data_i   ( lsu_wd                    ),
    .read_data_o    ( mem_rd                    ),
    .ready_o        ( mem_ready                 )
  );

  sw_sb_ctrl sw_inst (
    .clk_i               ( sysclk                    ),
    .rst_i               ( rst                       ),
    .req_i               ( lsu_req && ext_dvc_ptr[1] ),
    .write_enable_i      ( lsu_we                    ),
    .addr_i              ( ext_dvc_addr              ),
    .write_data_i        ( lsu_wd                    ),
    .read_data_o         ( sw_rd                     ),
 
    .interrupt_request_o ( sw_int_req                ),
    .interrupt_return_i  ( irq_ret                   ),
 
    .sw_i                ( sw_i                      )  
  );

  led_sb_ctrl led_inst (
    .clk_i          ( sysclk                    ),
    .rst_i          ( rst                       ),
    .req_i          ( lsu_req && ext_dvc_ptr[2] ),
    .write_enable_i ( lsu_we                    ),
    .addr_i         ( ext_dvc_addr              ),
    .write_data_i   ( lsu_wd                    ),
    .read_data_o    ( led_rd                    ),
   
    .led_o          ( led_o                     )
  );

  ps2_sb_ctrl ps2_inst (
    .clk_i               ( sysclk                    ),
    .rst_i               ( rst                       ),
    .addr_i              ( ext_dvc_addr              ),
    .req_i               ( lsu_req && ext_dvc_ptr[3] ),
    .write_data_i        ( lsu_wd                    ),
    .write_enable_i      ( lsu_we                    ),
    .read_data_o         ( ps2_rd                    ),

    .interrupt_request_o ( ps2_int_req               ),
    .interrupt_return_i  ( irq_ret                   ),

    .kclk_i              ( kclk_i                    ),
    .kdata_i             ( kdata_i                   )
  );

  hex_sb_ctrl hex_dig_inst (
    .clk_i          ( sysclk                    ),
    .rst_i          ( rst                       ),
    .addr_i         ( ext_dvc_addr              ),
    .req_i          ( lsu_req && ext_dvc_ptr[4] ),
    .write_data_i   ( lsu_wd                    ),
    .write_enable_i ( lsu_we                    ),
    .read_data_o    ( hex_rd                    ),

    .hex_led        ( hex_led_o                 ),
    .hex_sel        ( hex_sel_o                 )
  );
  
  vga_sb_ctrl vga_inst (
    .clk_i          ( sysclk                    ),
    .rst_i          ( rst                       ),
    .clk100m_i      ( clk_i                     ),
    .req_i          ( lsu_req && ext_dvc_ptr[7] ),
    .write_enable_i ( lsu_we                    ),
    .mem_be_i       ( lsu_be                    ),
    .addr_i         ( ext_dvc_addr              ),
    .write_data_i   ( lsu_wd                    ),
    .read_data_o    ( vga_rd                    ),

    .vga_r_o        ( vga_r_o                   ),
    .vga_g_o        ( vga_g_o                   ),
    .vga_b_o        ( vga_b_o                   ),
    .vga_hs_o       ( vga_hs_o                  ),
    .vga_vs_o       ( vga_vs_o                  )
  );

endmodule
