`timescale 1ns / 1ps
module datapath(
    input clk,
    input rst,
    input PC_rst
    );

    wire instr_wr_e;
    reg [31:0] PC;
    wire [31:0] PC_inc;
    wire [31:0] PC_imm;
    wire [31:0] PC_next;
    wire [31:0] input_instr;
    wire [31:0] instruction;

    wire reg_we;
    wire [31:0] reg_data_in;
    wire [31:0] data1_out, data2_out;

    wire [31:0] data_mem_data_in;
    wire data_mem_WR_E;
    wire data_mem_RD_E;
    wire sb, sh, sw;
    wire lb, lh, lw;
    wire lbu, lhu;
    wire [31:0] data_mem_data_out;

    wire [31:0] imm_add;
    wire [5:0] ALU_op;
    wire [31:0] ALU_out;
    wire [31:0] ALU_in1;
    wire [31:0] ALU_in2;
    wire PC_sel;
    wire branch;
    wire memreg;
    wire ALU_src;
    wire zero;
    wire overflow;

    always @(posedge clk ) begin
        if (!rst) begin
            PC <= PC_rst;
        end else begin
            if (PC_sel) begin
                if (jal || branch) begin
                    PC <= PC + (imm_add << 1);
                end else begin
                    PC <= ALU_out;
                end
            end else begin
                PC <= PC_inc;
            end
        end
    end

    assign PC_inc = PC + 4;
    assign PC_sel  = jl || jlr || (branch && ALU_out[31]);

    instruction_memory inst_mem (
        .address(PC),
        .data_in(input_instr),
        .clk(clk),
        .WR_E(instr_wr_e),
        .instruction(instruction)
    );

    assign reg_data_in = jl || jlr ? PC_inc : (memreg ? data_mem_data_out : ALU_out);

    register_file regfile (
        .clk(clk),
        .rst(rst),
        .write_enable(reg_we),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd1(instruction[11:7]),
        .data_in(reg_data_in),
        .data1_out(data1_out),
        .data2_out(data2_out)
    );

    assign ALU_in1 = data1_out;
    assign ALU_in2 = ALU_src ? imm_add : data2_out;

    alu alu_inst(
        .a_n(ALU_op[5]),
        .b_n(ALU_op[4]),
        .a(ALU_in1),
        .b(ALU_in2),
        .ALU_op(ALU_op[3:0]),
        .result(ALU_out),
        .zero(zero),
        .overflow(overflow)
    );

    data_memory dmem (
        .address(ALU_out),
        .data_in(data_mem_data_in),
        .clk(clk),
        .WR_E(data_mem_WR_E),
        .RD_E(data_mem_RD_E),
        .sb(sb),
        .sh(sh),
        .sw(sw),
        .lb(lb),
        .lh(lh),
        .lw(lw),
        .lbu(lbu),
        .lhu(lhu),
        .data_out(data_mem_data_out)
    );

endmodule
