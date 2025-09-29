module immediate_form (
    input  [31:0] instruction,
    output reg [31:0] immediate
);

wire [6:0] op_code;
//wire [2:0] func3;
wire U, J, I, S, B;

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

assign op_code = instruction[6:0];
//assign func3   = instruction[14:12];

assign U = op_code == U_add_up_imm || op_code == U_load;
assign J = op_code == J_uncon;
assign I = op_code == I_imm || op_code == I_load || op_code == I_jump || op_code == I_sys;
assign S = op_code == S_mem;
assign B = op_code == B_bran;

always @(*) begin
    // immediate[31]
    immediate[31] = instruction[31];

    // immediate[30:20]
    if (U) begin
        immediate[30:20] = instruction[30:20];
    end else begin
        immediate[30:20] = {11{instruction[31]}};
    end

    // immediate[19:12]
    if (U || J) begin
        immediate[19:12] = instruction[19:12];
    end else begin
        immediate[19:12] = {8{instruction[31]}};
    end

    // immediate[11]
    if (I || S) begin
        immediate[11] = instruction[31];
    end else if (B) begin
        immediate[11] = instruction[7];
    end else if (U) begin
        immediate[11] = 1'b0;
    end else begin // J
        immediate[11] = instruction[20];
    end

    // immediate[10:5]
    if (I || S || B || J) begin
        immediate[10:5] = instruction[30:25];
    end else begin // U
        immediate[10:5] = 6'd0;
    end

    // immediate[4:1]
    if (S || B) begin
        immediate[4:1] = instruction[11:8];
    end else if (I || J) begin
        immediate[4:1] = instruction[24:21];
    end else begin // U
        immediate[4:1] = 4'd0;
    end

    // immediate[0]
    if (I) begin
        immediate[0] = instruction[20];
    end else if (S) begin
        immediate[0] = instruction[7];
    end else begin // U, J, B
        immediate[0] = 1'b0;
    end
end

endmodule