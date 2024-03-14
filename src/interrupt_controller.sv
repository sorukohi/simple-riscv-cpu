`timescale 1ns / 1ps

module interrupt_controller (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic        irq_req_i,
  input  logic        mie_i,
  input  logic        mret_i,

  output logic        irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
  );
  
  logic irq_req_i_AND_mie_i;
  logic NOT_exc_h_set_OR_irq_h_Q;
  logic mret_i_AND_not_exc_h_set;
  logic exc_h_set;
  logic irq_h_set;
  logic exc_h_D;
  logic irq_h_D;
  logic exc_h_Q;
  logic irq_h_Q;

  assign irq_req_i_AND_mie_i      =  irq_req_i && mie_i;
  assign NOT_exc_h_set_OR_irq_h_Q = ~(exc_h_set || irq_h_Q);
  assign mret_i_AND_not_exc_h_set = mret_i && (~exc_h_set);
  assign exc_h_set                = exception_i || exc_h_Q;
  assign irq_h_set                = irq_o || irq_h_Q;
  assign exc_h_D                  = exc_h_set && (~mret_i);
  assign irq_h_D                  = irq_h_set && (~mret_i_AND_not_exc_h_set);
  assign irq_h_D                  = irq_h_set && (~mret_i_AND_not_exc_h_set);

  always_ff @(posedge clk_i) if (rst_i) exc_h_Q <= 1'd0;
                             else       exc_h_Q <= exc_h_D;

  always_ff @(posedge clk_i) if (rst_i) irq_h_Q <= 1'd0;
                             else       irq_h_Q <= irq_h_D;

  assign irq_cause_o = 32'h1000_0010;
  assign irq_o       = irq_req_i_AND_mie_i && NOT_exc_h_set_OR_irq_h_Q;
  assign irq_ret_o   = mret_i_AND_not_exc_h_set;

 endmodule
