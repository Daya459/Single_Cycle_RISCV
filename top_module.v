module top_module (
    input clk,
    input rst,
    input [31:0] data_mem_in,
    input [31:0] input_instr,
    output zero,
    output overflow
);
    // Wires for interconnection
    // Control signals from Control Unit to Datapath
    wire        branch;
    wire [1:0]  memreg;
    wire        d_wr_e;
    wire        d_rd_e;
    wire        auipc;
    wire        reg_we;
    wire        ALU_in_sel;
    wire        sb, sh, sw;
    wire        lb, lh, lw;
    wire        lbu, lhu;
    wire        jl;
    wire        jlr;
    wire        i_wr_e;
    wire [5:0]  ALU_op;

    // Datapath outputs
    wire [31:0] instruction;

    // Datapath instance
    datapath u_datapath (
        .clk(clk),
        .rst(rst),
        .PC_rst(1'b0), // Assuming PC_rst is tied low when not used
        .auipc(auipc),
        .branch(branch),
        .memreg(memreg),
        .reg_we(reg_we),
        .ALU_in_sel(ALU_in_sel),
        .i_wr_e(i_wr_e),
        .d_wr_e(d_wr_e),
        .d_rd_e(d_rd_e),
        .zero(zero),
        .overflow(overflow),
        .sb(sb), 
        .sh(sh), 
        .sw(sw),
        .lb(lb), 
        .lh(lh), 
        .lw(lw),
        .lbu(lbu), 
        .lhu(lhu),
        .jl(jl),
        .jlr(jlr),
        .data_mem_in(data_mem_in),
        .input_instr(input_instr),
        .ALU_op(ALU_op),
        .instruction(instruction) // Output from datapath
    );

    // Control unit instance
    control_unit u_control_unit (
        .instruction(instruction), // Input to control unit
        .branch(branch),
        .memreg(memreg),
        .d_wr_e(d_wr_e),
        .d_rd_e(d_rd_e),
        .auipc(auipc),
        .reg_we(reg_we), 
        .ALU_in_sel(ALU_in_sel),
        .sb(sb), 
        .sh(sh), 
        .sw(sw),
        .lb(lb), 
        .lh(lh), 
        .lw(lw), 
        .lbu(lbu), 
        .lhu(lhu),
        .jl(jl), 
        .jlr(jlr), 
        .i_wr_e(i_wr_e),
        .ALU_op(ALU_op)
    );

endmodule