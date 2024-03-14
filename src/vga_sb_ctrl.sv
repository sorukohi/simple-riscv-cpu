module vga_sb_ctrl (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        clk100m_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [3:0]  mem_be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,

  output logic [3:0]  vga_r_o,
  output logic [3:0]  vga_g_o,
  output logic [3:0]  vga_b_o,
  output logic        vga_hs_o,
  output logic        vga_vs_o
);
  
  logic [ 9:0] vga_addr;
  logic [ 1:0] vga_mode;
  logic        char_map_we;
  logic        col_map_we;
  logic        char_tiff_we;
  logic [31:0] char_map_rdata;
  logic [31:0] col_map_rdata;
  logic [31:0] char_tiff_rdata;

  vgachargen #(
    .CLK_FACTOR_25M           ( 100 / 25                ),
    .CH_T_RO_INIT_FILE_NAME   ( "lab12_vga_ch_t_ro.mem" ),
    .CH_T_RO_INIT_FILE_IS_BIN ( 1                       ),
    .CH_T_RW_INIT_FILE_NAME   ( "lab12_vga_ch_t_rw.mem" ),
    .CH_T_RW_INIT_FILE_IS_BIN ( 1                       ),
    .CH_MAP_INIT_FILE_NAME    ( "lab12_vga_ch_map.mem"  ),
    .CH_MAP_INIT_FILE_IS_BIN  ( 0                       ),
    .COL_MAP_INIT_FILE_NAME   ( "lab12_vga_col_map.mem" ),
    .COL_MAP_INIT_FILE_IS_BIN ( 0                       )
) vga_inst (
    .clk_i             ( clk_i           ), // системный синхроимпульс
    .clk100m_i         ( clk100m_i       ), // клок с частотой 100МГц
    .rst_i             ( rst_i           ), // сигнал сброса

  /*
      Интерфейс записи выводимого символа
  */
    .char_map_addr_i   ( vga_addr        ), // адрес позиции выводимого символа
    .char_map_we_i     ( char_map_we     ), // сигнал разрешения записи кода
    .char_map_be_i     ( mem_be_i        ), // сигнал выбора байтов для записи
    .char_map_wdata_i  ( write_data_i    ), // ascii-код выводимого символа
    .char_map_rdata_o  ( char_map_rdata  ), // сигнал чтения кода символа

  /*
      Интерфейс установки цветовой схемы
  */
    .col_map_addr_i    ( vga_addr        ), // адрес позиции устанавливаемой схемы
    .col_map_we_i      ( col_map_we      ), // сигнал разрешения записи схемы
    .col_map_be_i      ( mem_be_i        ), // сигнал выбора байтов для записи
    .col_map_wdata_i   ( write_data_i    ), // код устанавливаемой цветовой схемы
    .col_map_rdata_o   ( col_map_rdata   ), // сигнал чтения кода схемы

  /*
      Интерфейс установки шрифта.
  */
    .char_tiff_addr_i  ( vga_addr        ), // адрес позиции устанавливаемого шрифта
    .char_tiff_we_i    ( char_tiff_we    ), // сигнал разрешения записи шрифта
    .char_tiff_be_i    ( mem_be_i        ), // сигнал выбора байтов для записи
    .char_tiff_wdata_i ( write_data_i    ), // отображаемые пиксели в текущей позиции шрифта
    .char_tiff_rdata_o ( char_tiff_rdata ), // сигнал чтения пикселей шрифта

    .vga_r_o           ( vga_r_o         ), // красный канал vga
    .vga_g_o           ( vga_g_o         ), // зеленый канал vga
    .vga_b_o           ( vga_b_o         ), // синий канал vga
    .vga_hs_o          ( vga_hs_o        ), // линия горизонтальной синхронизации vga
    .vga_vs_o          ( vga_vs_o        )  // линия вертикальной синхронизации vga
  ); 
  
  assign vga_addr = addr_i[11:2];
  assign vga_mode = addr_i[13:12];

  localparam CHAR_MAP  = 2'b00;
  localparam COL_MAP   = 2'b01;
  localparam CHAR_TIFF = 2'b10;

  assign char_map_we  = (vga_mode == CHAR_MAP)  ? write_enable_i : 'd0;
  assign col_map_we   = (vga_mode == COL_MAP)   ? write_enable_i : 'd0;
  assign char_tiff_we = (vga_mode == CHAR_TIFF) ? write_enable_i : 'd0;

  logic         write_req;
  logic         read_req;
  
  logic         is_char_map_addr;
  logic         is_col_map_addr;
  logic         is_char_tiff_addr;

  logic         char_map_en;
  logic         col_map_en;
  logic         char_tiff_en;
  logic         read_en;

  logic [31:0]  rd;

  assign write_req          =  req_i &&  write_enable_i;
  assign read_req           =  req_i && ~write_enable_i;

  assign is_char_map_addr   = (addr_i >= 32'h0)    && (addr_i < 32'h960);
  assign is_col_map_addr    = (addr_i >= 32'h1000) && (addr_i < 32'h1960);
  assign is_char_tiff_addr  = (addr_i >= 32'h2000) && (addr_i < 32'h11000); 

  assign char_map_en        =  write_req && is_char_map_addr;  
  assign col_map_en         =  write_req && is_col_map_addr; 
  assign char_tiff_en       =  write_req && is_char_tiff_addr;  
  assign read_en            =  read_req  && (is_char_map_addr || is_col_map_addr || is_char_tiff_addr); 

  always_comb begin
    case (vga_mode) 
      CHAR_MAP  : rd = char_map_rdata;
      COL_MAP   : rd = col_map_rdata;
      CHAR_TIFF : rd = char_tiff_rdata;
      default   : rd = 'd0;
    endcase    
  end

  // synchronous read
  logic [31:0] sync_read_data;  
  always_ff @(posedge clk_i) begin
    if      (rst_i)   sync_read_data <= 'd0;
    else if (read_en) sync_read_data <= rd;
  end

  logic [1:0] selector;

  localparam  NOT_READING = 2'b00; // access to memory not allowed or occuring writing
  localparam  READING     = 2'b01; // occuring reading
  localparam  BAD         = 2'b10; // bad range for reading
  
  // manager signal for multiplexer which choose signal for output 
  always_comb begin
    if      (!req_i || write_enable_i) selector = NOT_READING;
    else if (read_en)                  selector = READING;
    else                               selector = BAD;
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

endmodule