`timescale 1ns / 1ps

module instruction_memory(
    input [31:0] address,
    input [31:0] data_in,
    input clk, WR_E,
    output [31:0] instruction
    );
    
    
    wire [8:0] bank_addr;

    // Bank address
    assign bank_addr = address[10:2];

    dist_mem_gen_0 i_mem (
    .a(bank_addr),
    .d(data_in),
    .clk(clk),
    .we(WR_E),
    .spo(instruction)
  );
    
endmodule
