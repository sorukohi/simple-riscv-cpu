module led_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,

/*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
  output logic [15:0] led_o
);

  logic [15:0] led_val;
  logic        led_mode;

  logic        write_req;
  logic        read_req;
  
  logic        is_val_addr;
  logic        is_mode_addr;
  logic        is_rst_addr;

  logic        val_valid;
  logic        mode_valid;
  logic        rst_valid;

  logic        rst;
  logic        val_en;
  logic        mode_en;
  logic        read_en;

  assign write_req    =  req_i && write_enable_i;
  assign read_req     =  req_i && ~write_enable_i;

  assign is_val_addr  = (addr_i == 32'h0);
  assign is_mode_addr = (addr_i == 32'h4);
  assign is_rst_addr  = (addr_i == 32'h24); 

  assign val_valid    = (write_data_i <= 32'hffff);
  assign mode_valid   = (write_data_i <= 32'd1);
  assign rst_valid    = (write_data_i == 32'd1);

  assign rst          = (write_req && is_rst_addr  && rst_valid) || rst_i;
  assign val_en       =  write_req && is_val_addr  && val_valid;  
  assign mode_en      =  write_req && is_mode_addr && mode_valid; 
  assign read_en      =  read_req  && ((is_val_addr && val_valid) || (is_mode_addr && mode_valid)); 

  always_ff @(posedge clk_i) begin
    if      (rst)    led_val <= 'd0;
    else if (val_en) led_val <= write_data_i[15:0];
  end

  always_ff @(posedge clk_i) begin
    if      (rst)     led_mode <= 'd0;
    else if (mode_en) led_mode <= write_data_i[0];
  end

  logic [31:0] cntr;
  localparam TIME_WINK = 20_000_000; 

  always_ff @(posedge clk_i) begin
    if      (rst)               cntr <= 'd0;
    else if (led_mode == 1'b0)  cntr <= 'd0;
    else if (cntr >= TIME_WINK) cntr <= 'd0;
    else                        cntr <= cntr + 'd1;
  end

  always_ff @(posedge clk_i) begin
    if      (rst)                  led_o <= 'd0;
    else if (led_mode == 1'b0)     led_o <= led_val;
    else if (cntr < TIME_WINK / 2) led_o <= led_val;
    else                           led_o <= 'd0;
  end

  logic [31:0] rd;
  assign       rd = is_val_addr ? {16'd0, led_val} : {31'd0, led_mode};

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