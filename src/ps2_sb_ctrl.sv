module ps2_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [31:0]  addr_i,
  input  logic         req_i,
  input  logic [31:0]  write_data_i,
  input  logic         write_enable_i,
  output logic [31:0]  read_data_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему прием данных с клавиатуры
*/
  input  logic kclk_i,
  input  logic kdata_i
);

  /* 
    PS2 connection
  */
  logic [7:0] keycodeout;
  logic       keycode_valid;

  PS2Receiver ps2_inst (
    .clk_i           ( clk_i         ),
    .rst_i           ( rst_i         ),
    .kclk_i          ( kclk_i        ),
    .kdata_i         ( kdata_i       ),
    .keycodeout_o    ( keycodeout    ),
    .keycode_valid_o ( keycode_valid )
  );

  /*
    Preparation for further working
  */
  logic        write_req;
  logic        read_req;

  logic        is_scan_addr;
  logic        is_scan_unread_addr;
  logic        is_rst_addr;

  logic        scan_valid;
  logic        scan_unread_valid;
  logic        rst_valid;

  logic        rst;
  logic        read_en;

  logic        flash_scan_code_is_unread;
  logic        set_scan_code_is_unread;
  logic [31:0] rd;

  assign write_req                 = req_i && write_enable_i;
  assign read_req                  = req_i && ~write_enable_i;
      
  assign is_scan_addr              = (addr_i == 32'h0);
  assign is_scan_unread_addr       = (addr_i == 32'h4);
  assign is_rst_addr               = (addr_i == 32'h24); 
      
  assign scan_valid                = (write_data_i <= 32'd255);
  assign scan_unread_valid         = (write_data_i <= 32'd1);
  assign rst_valid                 = (write_data_i == 32'd1);
      
  assign rst                       = rst_i || (write_req && is_rst_addr         && rst_valid);
  assign read_en                   =           read_req  && ((is_scan_addr && scan_valid) || (is_scan_unread_addr && scan_unread_valid)); 

  assign flash_scan_code_is_unread = (read_req && is_scan_addr && scan_valid) || interrupt_return_i;
  assign set_scan_code_is_unread   = keycode_valid;
  assign rd                        = is_scan_addr ? {24'd0, scan_code} : {31'd0, scan_code_is_unread};

  /* 
      Main part of module.
      To read scan_code reg necessary valid address, values range and not req for write. Same for other.
      Flag scan_code_is_unread notice about new received scan code from keyboard and, thus, set interrupt flag for cpu.
      This flag is being reset if data from scan_read reg will be read.
      Of course, right contacting with 0x24 reg of this module or external rst_i will cause reset, thus scan_code and scan_code_is_unread will be reset.
  */
  logic [7:0]  scan_code;
  logic        scan_code_is_unread;

  always_ff @(posedge clk_i) begin
    if      (rst)           scan_code <= 'd0;
    else if (keycode_valid) scan_code <= keycodeout;
  end

  always_ff @(posedge clk_i) begin
    if      (rst)                       scan_code_is_unread <= 'd0;
    else if (keycode_valid)             scan_code_is_unread <= 'd1;
    else if (flash_scan_code_is_unread) scan_code_is_unread <= 'd0;
  end

  assign interrupt_request_o = scan_code_is_unread;

  // synchronous read
  logic [31:0] sync_read_data;  
  always_ff @(posedge clk_i) begin
    if      (rst)     sync_read_data <= 'd0;
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