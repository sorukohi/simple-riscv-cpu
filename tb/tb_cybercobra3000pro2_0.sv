`timescale 1ns / 1ps

module tb_cybercobra3000pro2_0;
  
  // To set clock pulsing
  logic clk;
  initial clk = '0;
  always #50 clk = ~clk;
  // To reset register file
  logic rst;
  initial begin
    rst = '1;
    #20;
    rst = '0;
  end
  
  logic [31:0] in;
  logic [31:0] out;
  logic [31:0] instruction;
  logic [7:0]  pc;
  
  cybercobra3000pro2_0 cc (
    .clk_i               (clk),
    .rst_i               (rst),
    .IN                  (in),
    .OUT                 (out),
    .pc_checking         (pc),
    .instruction_checking(instruction) 
  );
  
  logic [31:0] rom [255:0];
  initial $readmemb("ROM.txt", rom);
  
  integer i;
  initial i = 0;
  
  always @(posedge clk) begin
    $display(" ");
    $display($time, " i = %d", i + 1);
    
    if (rom[pc+1] === 32'bx) begin
      #20;
      if (out !== 32'b00000000_00000000_00000000_11111000) begin
        $display($time, " Incorrect answer");
        $display($time, " out = %b_%b_%b_%b",
            out[31:24], out[23:16], out[15:8], out[7:0]);
        $finish; 
      end else begin
        $display($time, " Correct answer");
        $display($time, " out = %b_%b_%b_%b",
            out[31:24], out[23:16], out[15:8], out[7:0]);
        $finish;
      end 
    end
    
    $display($time, " pc = %d", pc);
    $display($time, " instruction = %b_%b_%b_%b_%b_%b_%b_%b",
        instruction[31], instruction[30], instruction[29:28],
            instruction[27:23], instruction[22:18], instruction[17:13],
                instruction[12:5], instruction[4:0]);
//    if ((instruction[31] === 'd1) && (instruction[12:5] === 'd1)) begin
//      $display($time, " out = %b_%b_%b_%b",
//            out[31:24], out[23:16], out[15:8], out[7:0]);
//    end
 
    i = i + 1;
  end
    
endmodule
