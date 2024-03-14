`timescale 1ns / 1ps

module riscv_core (
  input  logic        clk_i,
  input  logic        rst_i,
  
  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  input  logic        irq_req_i,
  
  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o,
  output logic        irq_ret_o
);

  // Expansion of constants
  logic [31:0] imm_i;
  logic [31:0] imm_u;
  logic [31:0] imm_s;
  logic [31:0] imm_b;
  logic [31:0] imm_j;
  logic [31:0] imm_z;
  
  assign imm_i = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_u = {instr_i[31:12], 12'h000};
  assign imm_s = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign imm_b = {{19{instr_i[31]}},{instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'd0}};
  assign imm_j = {{11{instr_i[31]}},{instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'd0}};
  assign imm_z = {27'd0, instr_i[19:15]};

  // Decoder block ports
  logic [ 1:0] a_sel;
  logic [ 2:0] b_sel;
  logic [ 4:0] alu_op;
  logic [ 2:0] csr_op;
  logic        csr_we;
  logic        gpr_we;
  logic [ 1:0] wb_sel;
  logic        illegal_instr;
  logic        branch;
  logic        jal;
  logic        jalr;
  logic        mret;
  logic        mem_req;
  logic        mem_we;
  
  // RF block ports
  logic [31:0] rd1;
  logic [31:0] rd2;
  logic        rf_en;
  logic [31:0] wb_data;
  logic [ 4:0] ra1;
  logic [ 4:0] ra2;
  logic [ 4:0] wa;

  // CSR block ports
  logic        trap;
  logic [11:0] csr_addr_i;
  logic [31:0] mcause;
  logic [31:0] csr_wd;
  logic [31:0] mie;
  logic [31:0] mepc;
  logic [31:0] mtvec;

  // IRQ contoller block prots
  logic        irq;
  logic [31:0] irq_cause;

  assign trap       = irq || illegal_instr;
  assign csr_addr_i = instr_i[31:20];
  assign mcause     = illegal_instr ? 32'h0000_0002 : irq_cause;

  csr_controller csr_inst (
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .trap_i        (trap),

    .opcode_i      (csr_op),

    .addr_i        (csr_addr_i),
    .pc_i          (pc),
    .mcause_i      (mcause),
    .rs1_data_i    (rd1),
    .imm_data_i    (imm_z),
    .write_enable_i(csr_we),

    .read_data_o   (csr_wd),
    .mie_o         (mie),
    .mepc_o        (mepc),
    .mtvec_o       (mtvec)        
  );

  interrupt_controller int_cntrlr_inst (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .exception_i(illegal_instr),
    .irq_req_i  (irq_req_i),
    .mie_i      (mie),
    .mret_i     (mret),

    .irq_ret_o  (irq_ret_o),
    .irq_cause_o(irq_cause),
    .irq_o      (irq)
  );

  logic  irq_req;
  logic  irq_ret;
  
  // ALU block ports
  logic [31:0] a_alu;
  logic [31:0] b_alu;
  logic        flag_alu;
  logic [31:0] result_alu;
  
  always_comb begin
    case (wb_sel)
      2'b00   : wb_data = result_alu;
      2'b01   : wb_data = mem_rd_i;
      2'b10   : wb_data = csr_wd;
      default : wb_data = result_alu;
    endcase
  end

  assign rf_en = gpr_we && (~stall_i || trap);
  assign ra1   = instr_i[19:15];
  assign ra2   = instr_i[24:20];
  assign wa    = instr_i[11: 7];
  
  // PC body kit
  logic [31:0] pc; 
  logic [31:0] pc_jalr;
  logic        jump;
  logic [31:0] jump_b_addr;
  logic [31:0] jump_j_addr;
  logic [31:0] common_step;
  
  assign pc_jalr     = rd1 + imm_i;
  assign jump        = jal || (flag_alu && branch);
  assign jump_b_addr = pc + imm_b;
  assign jump_j_addr = pc + imm_j;
  assign common_step = pc + 32'd4;
  
  always_ff @(posedge clk_i) begin
    if      (rst_i)            pc <= 32'd0;
    else if (stall_i)          pc <= pc;
    else if (mret)             pc <= mepc;
    else if (trap)             pc <= mtvec;
    else if (jalr)             pc <= {pc_jalr[31:1], 1'd0};
    else if (jump) if (branch) pc <= jump_b_addr;
                   else        pc <= jump_j_addr;
    else                       pc <= common_step;
  end

  assign instr_addr_o = pc;

  decoder_riscv dcd (
    .fetched_instr_i(instr_i),
    .a_sel_o        (a_sel),
    .b_sel_o        (b_sel),
    .alu_op_o       (alu_op),
    .csr_op_o       (csr_op),
    .csr_we_o       (csr_we),
    .mem_req_o      (mem_req),
    .mem_we_o       (mem_we),
    .mem_size_o     (mem_size_o),
    .gpr_we_o       (gpr_we),
    .wb_sel_o       (wb_sel),
    .illegal_instr_o(illegal_instr),
    .branch_o       (branch),
    .jal_o          (jal),
    .jalr_o         (jalr),
    .mret_o         (mret) 
  );

  assign mem_req_o = mem_req & ~trap;
  assign mem_we_o  = mem_we & ~trap;

  rf_riscv rf (
    .clk_i         (clk_i),
    .write_enable_i(rf_en),
    .read_addr1_i  (ra1),
    .read_addr2_i  (ra2),
    .write_addr_i  (wa),
    .write_data_i  (wb_data),
    .read_data1_o  (rd1),
    .read_data2_o  (rd2)
  );

  assign mem_wd_o = rd2;

  always_comb begin
    case (a_sel)
      2'b00   : a_alu = rd1;
      2'b01   : a_alu = pc;
      2'b10   : a_alu = '0;
      default : a_alu = rd1;
    endcase
  end

  always_comb begin
    case (b_sel)
      3'b000  : b_alu = rd2;
      3'b001  : b_alu = imm_i;
      3'b010  : b_alu = imm_u;
      3'b011  : b_alu = imm_s;
      3'b100  : b_alu = 'd4;
      default : b_alu = rd2;
    endcase
  end
  
  alu_riscv alu (
    .a_i     (a_alu),
    .b_i     (b_alu),
    .alu_op_i(alu_op),
    .flag_o  (flag_alu),
    .result_o(result_alu)
  );
  
  assign mem_addr_o = result_alu; 
  
endmodule