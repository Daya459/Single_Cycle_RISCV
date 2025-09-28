module immediate_form (
    input  [31:0] instruction,
    output reg [31:0] immediate,
);

wire [6:0] op_code;
wire [2:0] func3;

localparam I_imm        = 0010011; // I-type: Integer immediate arithmetic (e.g., addi, xori, slli)
localparam I_load       = 0000011; // I-type: Load from memory (e.g., lb, lh, lw)
localparam I_jumo       = 1100111; // I-type: Indirect jump (jalr)
localparam I_sys        = 1110011; // I-type: System instructions (e.g., ecall, ebreak, mret)
localparam R_alu        = 0110011; // R-type: Integer register arithmetic (e.g., add, sub, xor)
localparam S_mem        = 0100011; // S-type: Store to memory (e.g., sb, sh, sw)
localparam B_bran       = 1100011; // B-type: Conditional branch (e.g., beq, bne, blt)
localparam J_uncon      = 1101111; // J-type: Unconditional jump (jal)
localparam U_load       = 0110111; // U-type: Load upper immediate (lui)
localparam U_add_up_imm = 0010111; // U-type: Add upper immediate to PC (auipc)

assign op_code = instruction[6:0];
assign func3   = instruction[14:12];

assign immediate[31] = instruction[31];

assign U = op_code == U_add_up_imm || op_code == U_load;
assign J = op_code == J_uncon;
assign I = op_code == I_imm || op_code == I_load || op_code == I_jumo || op_code == I_sys;
assign S = op_code == S_mem;
assign B = op_code == B_bran;

always @(*) begin
    if (U) begin
        immediate[30:20] = instruction[30:20];
    end else begin
        immediate[30:20] = {11{instruction[31]}};
    end
end

always @(*) begin
    if (U || J) begin
        immediate[19:12] = instruction[19:12];
    end else begin
        immediate[19:12] = {8{instruction[31]}};
    end
end

always @(*) begin
    if (I || S) begin
        immediate[11] = instruction[31];
    end else if (B) begin
        immediate[11] = instruction[7];
    end else if (U) begin
        immediate[11] = 1'b0;
    end else begin
        immediate[11] = instruction[20];
    end
end

always @(*) begin
    if (I || S || B || J) begin
        immediate[10:5] = instruction[30:25];
    end else begin
        immediate[10:5] = 6'd0;
    end
end

always @(*) begin
    if (S || B) begin
        immediate[4:1] = instruction[11:8];
    end else if (I || J) begin
        immediate[4:1] = instruction[24:21];
    end else begin
        immediate[4:1] = 4'd0;
    end
end

always @(*) begin
    if (I) begin
        immediate[0] = instruction[20];
    end else if (S) begin
        immediate[0] = instruction[7];
    end else begin
        immediate[0] = 1'b0;
    end
end
endmodule