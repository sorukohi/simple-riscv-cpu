module sw_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,  // не используется, добавлен для
                                     // совместимости с системной шиной
  output logic [31:0] read_data_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
  input logic [15:0]  sw_i
);

  logic [15:0] sw_stored;

  always_ff @(posedge clk_i) begin
    if      (rst_i)              interrupt_request_o <= 'd0;
    else if (interrupt_return_i) interrupt_request_o <= 'd0;
    else if (sw_stored != sw_i)  interrupt_request_o <= 'd1;
  end

  always_ff @(posedge clk_i) begin
    if      (rst_i)             sw_stored <= 'd0;
    else if (sw_stored != sw_i) sw_stored <= sw_i;
  end

  // synchronous read
  logic [31:0] sync_read_data;  
  always_ff @(posedge clk_i) begin
    if (rst_i) sync_read_data <= 'd0;
    if (req_i) sync_read_data <= {16'd0, sw_i};
    else       sync_read_data <= 'd0;
  end

  logic [1:0] selector;

  localparam  NOT_READING = 2'b00; // access to memory not allowed or occuring writing
  localparam  READING     = 2'b01; // occuring reading
  localparam  BAD         = 2'b10; // bad range for reading
  
  // manager signal for multiplexer which choose signal for output 
  always_comb begin
    if      (!req_i || write_enable_i)   selector = NOT_READING;
    else if (req_i && (addr_i == 32'h0)) selector = READING;
    else                                 selector = BAD;
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