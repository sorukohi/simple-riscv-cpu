`timescale 1ns / 1ps

import riscv_pkg::*;

module decoder_riscv (
  input  logic [31:0] fetched_instr_i,
  output logic [ 1:0] a_sel_o,
  output logic [ 2:0] b_sel_o,
  output logic [ 4:0] alu_op_o,
  output logic [ 2:0] csr_op_o,
  output logic        csr_we_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 2:0] mem_size_o,
  output logic        gpr_we_o,
  output logic [ 1:0] wb_sel_o,
  output logic        illegal_instr_o,
  output logic        branch_o,
  output logic        jal_o,
  output logic        jalr_o,
  output logic        mret_o 
);
  
  logic [ 1: 0] low_digits;
  logic [ 6: 2] opcode;
  logic [31:25] funct7;
  logic [31:25] funct3;
  
  assign low_digits = fetched_instr_i[ 1: 0];
  assign opcode     = fetched_instr_i[ 6: 2];
  assign funct7     = fetched_instr_i[31:25];
  assign funct3     = fetched_instr_i[14:12];

  always_comb begin
    a_sel_o         = OP_A_RS1;
    b_sel_o         = OP_B_RS2;
    alu_op_o        = ALU_ADD;
    csr_op_o        = CSR_RW;
    csr_we_o        = 1'b0;
    mem_req_o       = 1'b0;
    mem_we_o        = 1'b0;
    mem_size_o      = LDST_W;
    gpr_we_o        = 1'b0;
    wb_sel_o        = WB_EX_RESULT;
    illegal_instr_o = 1'b0;
    jal_o           = 1'b0;
    jalr_o          = 1'b0;
    branch_o        = 1'b0;
    mret_o          = 1'b0;
    
    if (low_digits == 2'b11) begin
      case (opcode)
          OP_OPCODE: begin
            case(funct7)                
              7'b0000000 : begin
                a_sel_o                = OP_A_RS1;
                b_sel_o                = OP_B_RS2;
                gpr_we_o               = 1'b1;
                case (funct3)
                  3'b000  : alu_op_o   = ALU_ADD;
                  3'b001  : alu_op_o   = ALU_SLL;
                  3'b010  : alu_op_o   = ALU_SLTS;
                  3'b011  : alu_op_o   = ALU_SLTU;
                  3'b100  : alu_op_o   = ALU_XOR;
                  3'b101  : alu_op_o   = ALU_SRL;
                  3'b110  : alu_op_o   = ALU_OR;  
                  3'b111  : alu_op_o   = ALU_AND;
                  default : begin
                    illegal_instr_o    = 1'b1;
                    gpr_we_o           = 1'b0;
                  end
                endcase
              end
              7'b0100000 : begin
                a_sel_o                = OP_A_RS1;
                b_sel_o                = OP_B_RS2;
                gpr_we_o               = 1'b1;
                case (funct3)
                  3'b000  : alu_op_o   = ALU_SUB;
                  3'b101  : alu_op_o   = ALU_SRA;
                  default : begin
                    illegal_instr_o    = 1'b1;
                    gpr_we_o           = 1'b0;
                  end
                endcase
              end              
              default: illegal_instr_o = 1'b1;
            endcase
          end
          BRANCH_OPCODE: begin
            a_sel_o             = OP_A_RS1;
            b_sel_o             = OP_B_RS2;
            branch_o            = 1'b1;
            case (funct3)
              3'b000: alu_op_o  = ALU_EQ;
              3'b001: alu_op_o  = ALU_NE;
              3'b100: alu_op_o  = ALU_LTS;
              3'b101: alu_op_o  = ALU_GES;
              3'b110: alu_op_o  = ALU_LTU;
              3'b111: alu_op_o  = ALU_GEU;
              default: begin
                illegal_instr_o = 1'b1;
                branch_o        = 1'b0;
              end
            endcase
          end
          OP_IMM_OPCODE: begin
            a_sel_o               = OP_A_RS1;
            b_sel_o               = OP_B_IMM_I;
            gpr_we_o              = 1'b1;
            case (funct3)
              3'b000: alu_op_o    = ALU_ADD;
              3'b010: alu_op_o    = ALU_SLTS;
              3'b011: alu_op_o    = ALU_SLTU;
              3'b100: alu_op_o    = ALU_XOR;
              3'b110: alu_op_o    = ALU_OR;
              3'b111: alu_op_o    = ALU_AND;
              3'b001: begin
                if (funct7 == 7'b0000000) begin
                  alu_op_o        = ALU_SLL;
                end else begin
                  illegal_instr_o = 1'b1;
                  gpr_we_o        = 1'b0;
                end 
              end    
              3'b101: begin
                if (funct7 == 7'b0000000) begin
                  alu_op_o        = ALU_SRL;
                end else if (funct7 == 7'b0100000) begin
                  alu_op_o        = ALU_SRA;
                end else begin
                  illegal_instr_o = 1'b1;
                  gpr_we_o        = 1'b0;
                end 
              end
              default: begin
                illegal_instr_o   = 1'b1;
                gpr_we_o          = 1'b0;
              end
            endcase             
          end
          LOAD_OPCODE: begin
            a_sel_o             = OP_A_RS1;
            b_sel_o             = OP_B_IMM_I;
            mem_req_o           = 1'b1;
            wb_sel_o            = WB_LSU_DATA;
            gpr_we_o            = 1'b1;
            case (funct3)
              3'b000: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_B;
              end
              3'b001: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_H;
              end
              3'b010: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_W;
              end
              3'b100: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_BU;
              end
              3'b101: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_HU;
              end
              default: begin
                illegal_instr_o = 1'b1;
                mem_req_o       = 1'b0;
                wb_sel_o        = WB_EX_RESULT;
                gpr_we_o        = 1'b0;
              end 
            endcase
          end
          STORE_OPCODE: begin
            a_sel_o             = OP_A_RS1;
            b_sel_o             = OP_B_IMM_S;
            mem_req_o           = 1'b1;
            mem_we_o            = 1'b1;
            case (funct3)
              3'b000: begin              
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_B;
              end
              3'b001: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_H;
              end
              3'b010: begin
                alu_op_o        = ALU_ADD;
                mem_size_o      = LDST_W;
              end
              default: begin
                illegal_instr_o = 1'b1;
                mem_req_o       = 1'b0;
                mem_we_o        = 1'b0;
              end
            endcase
          end
          JAL_OPCODE: begin
            jal_o    = 1'b1;
            a_sel_o  = OP_A_CURR_PC;
            b_sel_o  = OP_B_INCR;
            alu_op_o = ALU_ADD;
            gpr_we_o = 1'b1;
          end
          JALR_OPCODE: begin
            if (funct3 == 3'b000) begin
              jalr_o          = 1'b1;
              a_sel_o         = OP_A_CURR_PC;
              b_sel_o         = OP_B_INCR;
              alu_op_o        = ALU_ADD;
              gpr_we_o        = 1'b1;
            end
            else begin
              illegal_instr_o = 1'b1;
            end  
          end
          LUI_OPCODE: begin
            a_sel_o  = OP_A_ZERO;
            b_sel_o  = OP_B_IMM_U;
            alu_op_o = ALU_ADD;
            gpr_we_o = 1'b1;
          end
          AUIPC_OPCODE: begin
            a_sel_o  = OP_A_CURR_PC;
            b_sel_o  = OP_B_IMM_U;
            alu_op_o = ALU_ADD;
            gpr_we_o = 1'b1;
          end
          SYSTEM_OPCODE: begin
            csr_we_o                         = 1'b1;
            gpr_we_o                         = 1'b1;
            wb_sel_o                         = WB_CSR_DATA;
            case (funct3)
              3'b000  : begin
                csr_we_o                     = 1'b0;
                gpr_we_o                     = 1'b0;
                wb_sel_o                     = WB_EX_RESULT;
                case (fetched_instr_i[31:20])
                  12'h000  : illegal_instr_o = 1'b1;
                  12'h001  : illegal_instr_o = 1'b1;
                  12'h302  : mret_o          = 1'b1;
                  default  : illegal_instr_o = 1'b1;
                endcase
              end
              CSR_RW  : csr_op_o             = CSR_RW;
              CSR_RS  : csr_op_o             = CSR_RS;
              CSR_RC  : csr_op_o             = CSR_RC;
              CSR_RWI : csr_op_o             = CSR_RWI;
              CSR_RSI : csr_op_o             = CSR_RSI;
              CSR_RCI : csr_op_o             = CSR_RCI;
              default : begin
                illegal_instr_o              = 1'b1;
                csr_we_o                     = 1'b0;
                gpr_we_o                     = 1'b0;
                wb_sel_o                     = WB_EX_RESULT;
              end
            endcase
          end
          MISC_MEM_OPCODE: begin
            if (funct3 == 3'b000) begin
              // NOP
            end else illegal_instr_o = 1'b1;
          end       
          default: illegal_instr_o = 1'b1;
      endcase
    end else illegal_instr_o = 1'b1;
  end

endmodule
