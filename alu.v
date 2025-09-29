module alu (
    input a_n,
    input b_n,
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0] ALU_op,
    output reg [31:0] result,
    output zero,
    output overflow
);


wire [31:0] a_updated;
wire [31:0] b_updated;
wire cout;
wire [1:0] cin;
wire [31:0] result_sum;

assign a_updated = a_n ? ~a : a;
assign b_updated = b_n ? ~b : b;
assign cin[1]  = a_n & b_n;
assign cin[0]  = a_n ^ b_n;


assign {cout, result_sum} = a_updated + b_updated + cin;

assign zero = ~|result_sum; 

assign overflow = (a_updated[31] ^~ b_updated[31]) && (result_sum[31] != a_updated[31]);  // Equivalent formula would be cout ^ co30.

always @(*) begin
    case (ALU_op)
        4'b0000 : result = a_updated & b_updated;
        4'b0001 : result = a_updated | b_updated;
        4'b0010 : result = a_updated ^ b_updated;
        4'b0011 : result = result_sum;
        4'b0100 : result = {30'b0,  result_sum[31] ^ overflow};   // For blt and slt
        4'b0101 : result = {30'b0, !(result_sum[31] ^ overflow)}; // For bge
        4'b0110 : result = {30'b0, zero};                         // For beq
        4'b0111 : result = {30'b0, !zero};                        // For bne
        4'b1000 : result = a << b[4:0];                                // For sll and slli 
        4'b1001 : result = a >> b[4:0];                                // For srl and srli
        4'b1010 : result = a >>> b[4:0];                               // For sra and srai
        4'b1011 : result = {30'b0,  !cout};                      // For bltu and sltu
        4'b1100 : result = {30'b0,  cout};                       // For bgeu
        default: result = 32'hXXXXXXXX;
    endcase
end
endmodule