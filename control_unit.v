module control_unit (
    input [31:0] instruction,
    output reg branch,
    output reg [1:0] memreg,
    output reg d_wr_e,
    output reg d_rd_e,
    output reg auipc,
    output reg reg_we,
    output reg ALU_in_sel,
    output reg sb, sh, sw,
    output reg lb, lh, lw,
    output reg lbu, lhu,
    output reg jl,
    output reg jlr,
    output i_wr_e,
    output reg [5:0] ALU_op
);

wire [6:0] op_code;
wire [2:0] func3;
wire [6:0] func7;

assign i_wr_e = 1'b0;
assign op_code = instruction[6:0];
assign func3   = instruction[14:12];
assign func7   = instruction[31:25];

localparam I_imm        = 7'b0010011; // I-type: Integer immediate arithmetic (e.g., addi, xori, slli)
localparam I_load       = 7'b0000011; // I-type: Load from memory (e.g., lb, lh, lw)
localparam I_jump       = 7'b1100111; // I-type: Indirect jump (jalr)
localparam I_sys        = 7'b1110011; // I-type: System instructions (e.g., ecall, ebreak, mret)
localparam R_alu        = 7'b0110011; // R-type: Integer register arithmetic (e.g., add, sub, xor)
localparam S_mem        = 7'b0100011; // S-type: Store to memory (e.g., sb, sh, sw)
localparam B_bran       = 7'b1100011; // B-type: Conditional branch (e.g., beq, bne, blt)
localparam J_uncon      = 7'b1101111; // J-type: Unconditional jump (jal)
localparam U_load       = 7'b0110111; // U-type: Load upper immediate (lui)
localparam U_add_up_imm = 7'b0010111; // U-type: Add upper immediate to PC (auipc)

// ALU_control signals
always @(*) begin
    if (op_code == R_alu) begin
        case (func3)
            3'b000 : begin
                if (func7 == 7'b0000000) begin
                    ALU_op = 6'b000011;                                        // ADD
                end else if (func7 == 7'b0100000) begin
                    ALU_op = 6'b010011;                                       // SUB
                end else begin
                    ALU_op = 6'bxxxxxx;
                end
            end
            3'b001 : ALU_op = (func7 == 7'b0000000) ? 6'b001000 : 6'bxxxxxx;   // SLL
            3'b010 : ALU_op = (func7 == 7'b0000000) ? 6'b010100 : 6'bxxxxxx;   // SLT
            3'b011 : ALU_op = (func7 == 7'b0000000) ? 6'b011011 : 6'bxxxxxx;   // SLTU
            3'b100 : ALU_op = (func7 == 7'b0000000) ? 6'b000010 : 6'bxxxxxx;   // XOR
            3'b101 : begin
                if (func7 == 7'b0000000) begin
                    ALU_op = 6'b001001;                                        // SRL
                end else if (func7 == 7'b0100000) begin
                    ALU_op = 6'b001010;                                        // SRA
                end else begin
                    ALU_op = 6'bxxxxxx; 
                end
            end
            3'b110 : ALU_op = (func7 == 7'b0000000) ? 6'b000001 : 6'bxxxxxx;    // OR
            3'b111 : ALU_op = (func7 == 7'b0000000) ? 6'b000000 : 6'bxxxxxx;    // AND
            default: ALU_op = 6'bxxxxxx;
        endcase
    end else if (op_code == I_imm) begin
        case (func3)
            3'b000: ALU_op = 6'b000011;                                         // ADDI
            3'b001: ALU_op = (func7 == 7'b0000000) ? 6'b001000 : 6'bxxxxxx;      // SLLI
            3'b010: ALU_op = 6'b010100;                                         // SLTI
            3'b011: ALU_op = 6'b011011;                                         // SLTIU
            3'b100: ALU_op = 6'b000010;                                         // XORI
            3'b101: begin
                if (func7 == 7'b0000000) ALU_op = 6'b001001;                    // SRLI
                else if (func7 == 7'b0100000) ALU_op = 6'b001010;               // SRAI
                else ALU_op = 6'bxxxxxx;
            end
            3'b110: ALU_op = 6'b000001;                                         // ORI
            3'b111: ALU_op = 6'b000000;                                         // ANDI
            default: ALU_op = 6'bxxxxxx;
        endcase
    end else if (op_code == I_load) begin
        case (func3)
            3'b000: ALU_op = 6'b000011;                                         // LB
            3'b001: ALU_op = 6'b000011;                                         // LH
            3'b010: ALU_op = 6'b000011;                                         // LW
            3'b100: ALU_op = 6'b000011;                                         // LBU
            3'b101: ALU_op = 6'b000011;                                         // LHU
            default: ALU_op = 6'bxxxxxx;                                        // Reserved/Unused
        endcase
    end else if (op_code == I_jump) begin
        case (func3)
            3'b000: ALU_op = 6'b000011;                                         // JALR
            default: ALU_op = 6'bxxxxxx;
        endcase
    // end else if (op_code == I_sys) begin
    //     case (func3)
    //         3'b000: ALU_op = 6'bxxxxxx;                                         // ECALL, EBREAK (no ALU operation)
    //         default: ALU_op = 6'bxxxxxx;
    //     endcase
    end else if (op_code == S_mem) begin
        case (func3)
            3'b000: ALU_op = 6'b000011;                                         // SB (Store Byte)
            3'b001: ALU_op = 6'b000011;                                         // SH (Store Halfword)
            3'b010: ALU_op = 6'b000011;                                         // SW (Store Word)
            default: ALU_op = 6'bxxxxxx;                                        // Reserved/Unused
        endcase
    end else if (op_code == B_bran) begin
        case (func3)
            3'b000: ALU_op = 6'b010110;                                         // BEQ
            3'b001: ALU_op = 6'b010111;                                         // BNE
            3'b100: ALU_op = 6'b010100;                                         // BLT
            3'b101: ALU_op = 6'b010101;                                         // BGE
            3'b110: ALU_op = 6'b011011;                                         // BLTU
            3'b111: ALU_op = 6'b011100;                                         // BGEU
            default: ALU_op = 6'bxxxxxx;
        endcase
    end else if (op_code == J_uncon) begin
        ALU_op =  6'bxxxxxx;                                                    // JAL
    end else if (op_code == U_load) begin
        ALU_op =  6'b000011;                                                    // LUI
    end else if (op_code == U_add_up_imm) begin
        ALU_op =  6'bxxxxxx;                                                    // AUIPC
    end else begin
        ALU_op = 6'bxxxxxx;
    end
end


always @(*) begin
    branch     = 1'b0;
    memreg     = 2'b00;
    sb         = 1'b0;
    sh         = 1'b0;
    sw         = 1'b0;
    lb         = 1'b0;
    lh         = 1'b0;
    lw         = 1'b0;
    lbu        = 1'b0;
    lhu        = 1'b0;
    jl         = 1'b0;
    jlr        = 1'b0;
    auipc      = 1'b0;
    reg_we     = 1'b0;
    d_wr_e     = 1'b0;
    d_rd_e     = 1'b0;
    ALU_in_sel = 1'b0;
    case (op_code)
        I_imm : begin
            ALU_in_sel = 1'b1;
            reg_we     = 1'b1;
            memreg     = 2'b01;
        end
        I_jump : begin
            jlr        = (func3 == 3'b000);
            reg_we     = (func3 == 3'b000);
            ALU_in_sel = (func3 == 3'b000);
            memreg     = 2'b11;
        end
        I_load : begin
            reg_we     = 1'b1;
            memreg     = 2'b00;
            ALU_in_sel = 1'b1;
            d_rd_e     = 1'b1;
            lb         = (func3 == 3'b000);
            lh         = (func3 == 3'b001);
            lw         = (func3 == 3'b010);
            lbu        = (func3 == 3'b100);
            lhu        = (func3 == 3'b101);
        end
        // I_sys : begin

        // end
        R_alu : begin
            reg_we     = 1'b1;
            ALU_in_sel = 1'b0;
            memreg     = 2'b01;
        end
        S_mem : begin
            d_wr_e     = 1'b1; // Added: Data memory write enable for store operations
            sb         = (func3 == 3'b000);
            sh         = (func3 == 3'b001); // Corrected: sh for func3 001
            sw         = (func3 == 3'b010); // Corrected: sw for func3 010
            ALU_in_sel = 1'b1;
        end
        B_bran : begin
            branch = 1'b1;
        end
        J_uncon : begin
            reg_we = 1'b1;
            jl     = 1'b1;
            memreg = 2'b11;
        end
        U_load : begin
            reg_we = 1'b1;
            memreg = 2'b10;
        end
        U_add_up_imm : begin
            ALU_in_sel = 1'b1;
            auipc      = 1'b1;
            reg_we     = 1'b1;
            memreg     = 2'b01;
        end
        default: ; // No operation
    endcase
 
end
endmodule
