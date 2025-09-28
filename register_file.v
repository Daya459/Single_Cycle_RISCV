module register_file (
    input clk,
    input rst,
    input write_enable,
    input  [4:0] rs1,
    input  [4:0] rs2, // add missing comma
    input  [4:0] rd1,
    input  [31:0] data_in,
    output [31:0] data1_out,
    output [31:0] data2_out
);

reg [31:0] write_select; // change to reg

reg  [31:0] register [31:0];
integer i; // declare loop variable

always @(*) begin
    write_select = 32'd0;
    write_select[rd1] = 1'b1;
end

// Register write part
always @(posedge clk) begin
    if (!rst) begin
        for (i  = 0; i < 32; i = i+1) begin
            register[i] <= 32'd0;
        end
    end else begin
        if (write_enable) begin
            for (i  = 0; i < 32; i = i+1) begin
                if (write_select[i] == 1) begin
                    register[i] <= i == 0 ? 32'd0 : data_in;
                end
            end 
        end
    end
end

assign data1_out = register[rs1];
assign data2_out = register[rs2]; 
endmodule