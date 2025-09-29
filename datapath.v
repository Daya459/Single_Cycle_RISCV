`timescale 1ns / 1ps
module datapath(
    input clk,
    input rst,
    input PC_rst,
    input auipc,
    input branch,
    input memreg,
    input reg_we,
    input ALU_in_sel,
    input i_wr_e,
    input d_wr_e,
    input d_rd_e,
    input sb, sh, sw,
    input lb, lh, lw,
    input lbu, lhu,
    input jl,
    input jlr,
    input [5:0] ALU_op,
    input [31:0] data_mem_in,
    input [31:0] input_instr,
    // Outputs
    output zero,
    output overflow,
    output [31:0] instruction
    );

    reg  [31:0] PC;
    wire [31:0] PC_inc;

    reg [31:0] reg_data_in;
    wire [31:0] data1_out, data2_out;

    wire [31:0] data_mem_out;

    wire [31:0] imm;
    wire [31:0] ALU_out;
    wire [31:0] ALU_in1;
    wire [31:0] ALU_in2;

    wire jump;

    assign PC_inc = PC + 4;
    assign jump   = jl || jlr;

    always @(posedge clk ) begin
        if (!rst) begin
            PC <= PC_rst;
        end else begin
            if (jump || (branch && ALU_out[0])) begin
                if (jl || branch) begin
                    PC <= PC + (imm << 1);
                end else begin
                    PC <= ALU_out;
                end
            end else begin
                PC <= PC_inc;
            end
        end
    end

    instruction_memory inst_mem (
        .address(PC),
        .data_in(input_instr),
        .clk(clk),
        .WR_E(i_wr_e),
        .instruction(instruction)
    );

//    assign reg_data_in = jump ? PC_inc : (memreg ? data_mem_out : ALU_out);
    always @(*) begin
        case (memreg)
            2'b00: reg_data_in = data_mem_out;
            2'b01: reg_data_in = ALU_out;
            2'b10: reg_data_in = imm;
            2'b11: reg_data_in = PC_inc;
            default: reg_data_in = 32'd0;
        endcase
    end

    immediate_form imm_form_inst (
        .instruction(instruction),
        .immediate(imm)
    );
    
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

    assign ALU_in1 = auipc ? PC : data1_out;
    assign ALU_in2 = ALU_in_sel ? imm : data2_out;

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
        .data_in(data_mem_in),
        .clk(clk),
        .WR_E(d_wr_e),
        .RD_E(d_rd_e),
        .sb(sb),
        .sh(sh),
        .sw(sw),
        .lb(lb),
        .lh(lh),
        .lw(lw),
        .lbu(lbu),
        .lhu(lhu),
        .data_out(data_mem_out)
    );

endmodule
