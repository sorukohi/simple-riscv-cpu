module hex_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [31:0] addr_i,
  input  logic        req_i,
  input  logic [31:0] write_data_i,
  input  logic        write_enable_i,
  output logic [31:0] read_data_o,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему вывод цифр на семисегментные индикаторы
*/
  output logic [6:0] hex_led,
  output logic [7:0] hex_sel
);
  
  /*
    Connection to hexdigits module
  */
  logic [3:0] hex0, hex1, hex2, hex3, hex4, hex5, hex6, hex7;
  logic [7:0] bitmask;
  
  hex_digits hex_dig_inst (
    .clk_i     ( clk_i   ),
    .rst_i     ( rst_i   ),
    .hex0_i    ( hex0    ),
    .hex1_i    ( hex1    ),  
    .hex2_i    ( hex2    ),  
    .hex3_i    ( hex3    ),   
    .hex4_i    ( hex4    ), 
    .hex5_i    ( hex5    ), 
    .hex6_i    ( hex6    ),   
    .hex7_i    ( hex7    ),   
    .bitmask_i ( bitmask ), 

    .hex_led_o ( hex_led ),

    .hex_sel_o ( hex_sel )
  );

  /*
    Preparation for further working
  */
  logic         write_req;
  logic         read_req;
  
  logic         is_hex0_addr;
  logic         is_hex1_addr;
  logic         is_hex2_addr;
  logic         is_hex3_addr;
  logic         is_hex4_addr;
  logic         is_hex5_addr;
  logic         is_hex6_addr;
  logic         is_hex7_addr;
  logic         is_hex_addr;
  logic         is_bitmask_addr;
  logic         is_rst_addr;

  logic         hex0_valid;
  logic         hex1_valid;
  logic         hex2_valid;
  logic         hex3_valid;
  logic         hex4_valid;
  logic         hex5_valid;
  logic         hex6_valid;
  logic         hex7_valid;
  logic         hex_valid;
  logic         bitmask_valid;
  logic         rst_valid;

  logic         rst;
  logic         hex0_en;
  logic         hex1_en;
  logic         hex2_en;
  logic         hex3_en;
  logic         hex4_en;
  logic         hex5_en;
  logic         hex6_en;
  logic         hex7_en;
  logic         bitmask_en;
  logic         read_en;

  logic [31:0]  rd;

  assign write_req       =  req_i && write_enable_i;
  assign read_req        =  req_i && ~write_enable_i;

  assign is_hex0_addr    = (addr_i == 32'h0);
  assign is_hex1_addr    = (addr_i == 32'h4);
  assign is_hex2_addr    = (addr_i == 32'h8);
  assign is_hex3_addr    = (addr_i == 32'hC);
  assign is_hex4_addr    = (addr_i == 32'h10);
  assign is_hex5_addr    = (addr_i == 32'h14);
  assign is_hex6_addr    = (addr_i == 32'h18);
  assign is_hex7_addr    = (addr_i == 32'h1C);
  assign is_hex_addr     = is_hex0_addr || is_hex1_addr || is_hex2_addr || is_hex3_addr || is_hex4_addr || is_hex5_addr || is_hex6_addr || is_hex7_addr;
  assign is_bitmask_addr = (addr_i == 32'h20);
  assign is_rst_addr     = (addr_i == 32'h24); 

  assign hex0_valid      = (write_data_i <= 'd15);
  assign hex1_valid      = (write_data_i <= 'd15);
  assign hex2_valid      = (write_data_i <= 'd15);
  assign hex3_valid      = (write_data_i <= 'd15);
  assign hex4_valid      = (write_data_i <= 'd15);
  assign hex5_valid      = (write_data_i <= 'd15);
  assign hex6_valid      = (write_data_i <= 'd15);
  assign hex7_valid      = (write_data_i <= 'd15);
  assign hex_valid       = hex0_valid || hex1_valid || hex2_valid || hex3_valid || hex4_valid || hex5_valid || hex6_valid || hex7_valid; 
  assign bitmask_valid   = (write_data_i <= 32'd255);
  assign rst_valid       = (write_data_i == 32'd1);  

  assign rst             = rst_i || (write_req && is_rst_addr     && rst_valid);
  assign hex0_en         =           write_req && is_hex0_addr    && hex0_valid;
  assign hex1_en         =           write_req && is_hex1_addr    && hex1_valid;
  assign hex2_en         =           write_req && is_hex2_addr    && hex2_valid;
  assign hex3_en         =           write_req && is_hex3_addr    && hex3_valid;
  assign hex4_en         =           write_req && is_hex4_addr    && hex4_valid;
  assign hex5_en         =           write_req && is_hex5_addr    && hex5_valid;
  assign hex6_en         =           write_req && is_hex6_addr    && hex6_valid;
  assign hex7_en         =           write_req && is_hex7_addr    && hex7_valid;
  assign bitmask_en      =           write_req && is_bitmask_addr && bitmask_valid;
  assign read_en         =           read_req  && ((is_hex_addr && hex_valid) || (is_bitmask_addr && bitmask_valid));

  always_comb begin
    case (addr_i)
      'h00    : rd = {28'd0, hex0};
      'h04    : rd = {28'd0, hex1};
      'h08    : rd = {28'd0, hex2};
      'h0C    : rd = {28'd0, hex3};
      'h10    : rd = {28'd0, hex4};
      'h14    : rd = {28'd0, hex5};
      'h18    : rd = {28'd0, hex6};
      'h1C    : rd = {28'd0, hex7};
      'h20    : rd = {24'd0, bitmask};
      default : rd = 'd0;
    endcase
  end

  /*
    Main part of module.
    hex0..hex7 represent itself values on corresponding hexes of FPGA. 
    But show own data it will be if bitmask allow them. 
  */

  // Writing 
  always_ff @(posedge clk_i) begin
    if (rst) begin
      hex0 <= 'd0;
      hex1 <= 'd0;
      hex2 <= 'd0;
      hex3 <= 'd0;
      hex4 <= 'd0;
      hex5 <= 'd0;
      hex6 <= 'd0;
      hex7 <= 'd0;
    end else begin
      if (hex0_en) hex0 <= write_data_i[3:0];
      if (hex1_en) hex1 <= write_data_i[3:0];
      if (hex2_en) hex2 <= write_data_i[3:0];
      if (hex3_en) hex3 <= write_data_i[3:0];
      if (hex4_en) hex4 <= write_data_i[3:0];
      if (hex5_en) hex5 <= write_data_i[3:0];
      if (hex6_en) hex6 <= write_data_i[3:0];
      if (hex7_en) hex7 <= write_data_i[3:0];
    end
  end 

  always_ff @(posedge clk_i) begin
    if      (rst)        bitmask <= '1;
    else if (bitmask_en) bitmask <= write_data_i[7:0];
  end

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