`timescale 1ns / 1ps

module data_memory(
    input [31:0] address,
    input [31:0] data_in,
    input clk, WR_E, RD_E,
    input sb, sh, sw,
    input lb, lh, lw,
    input lbu, lhu,
    output [31:0] data_out
    );
    
    
    wire [8:0] bank_addr;

    wire [7:0] bank0_read_data;
    wire [7:0] bank1_read_data;
    wire [7:0] bank2_read_data;
    wire [7:0] bank3_read_data;

    reg [7:0] data0;
    reg [7:0] data1;
    reg [7:0] data2;
    reg [7:0] data3;

    reg [7:0] bank0_write_data;
    reg [7:0] bank1_write_data;
    reg [7:0] bank2_write_data;
    reg [7:0] bank3_write_data;


    wire [1:0] control_3;
    wire bank0_enable, bank1_enable, bank2_enable, bank3_enable;

    // Declare missing signals
    reg [7:0] data0_int;
    reg [7:0] data1_int1;
    reg [7:0] data1_int0;
    reg [7:0] data2_int;
    wire load;


    assign bank0_enable = WR_E && (sb || sh || sw) && (!address[1] && !address[0]);
    assign bank1_enable = WR_E && ((sb && !address[1] && address[0]) || (sh && !address[1] && !address[0]) || (sw && !address[1] && !address[0]));
    assign bank2_enable = WR_E && ((sb && address[1] && !address[0]) || (sh && address[1] && !address[0])  || (sw && !address[1] && !address[0]));
    assign bank3_enable = WR_E && ((sb && address[1] && address[0])  || (sh && address[1] && !address[0])  || (sw && !address[1] && !address[0]));
    

    // assign write_enable = WR_E && (sb || sh && !address[0] || sw && !address[1] && !address[0]);
    assign control_3[1] = !sb && !sh;
    assign control_3[0] = !sb && !sw;
    assign bank_addr = address[10:2];

    // Write Data assignment 
    always @(*) begin
        bank0_write_data = data_in[7:0];
        bank1_write_data = sh || sw ? data_in[15:8]  : data_in[7:0];
        bank2_write_data = sw ? data_in[23:16] : data_in[7:0];

        case (control_3)
            00 : bank3_write_data = data_in[7:0];
            01 : bank3_write_data = data_in[15:8];
            10 : bank3_write_data = data_in[23:16];
            11 : bank3_write_data = data_in[7:0];  // This will never be used
            default: bank3_write_data = data_in[7:0];
        endcase
    end

    dist_mem_gen_1 bank0 (
    .a(bank_addr),
    .d(bank0_write_data),
    .clk(clk),
    .we(bank0_enable),
    .spo(bank0_read_data)
  );

    dist_mem_gen_1 bank1 (
    .a(bank_addr),
    .d(bank1_write_data),
    .clk(clk),
    .we(bank1_enable),
    .spo(bank1_read_data)
  );

    dist_mem_gen_1 bank2 (
    .a(bank_addr),
    .d(bank2_write_data),
    .clk(clk),
    .we(bank2_enable),
    .spo(bank2_read_data)
  );


    dist_mem_gen_1 bank3 (
    .a(bank_addr),
    .d(bank3_write_data),
    .clk(clk),
    .we(bank3_enable),
    .spo(bank3_read_data)
  );

always @(*) begin

    // data0 write
    case (address[1:0])
        2'b00 : data0_int = bank0_read_data;
        2'b01 : data0_int = bank1_read_data;
        2'b10 : data0_int = bank2_read_data;
        2'b11 : data0_int = bank3_read_data;
        default: data0_int = bank0_read_data;
    endcase

    if (lw) begin
        data0 = bank0_read_data;
    end else 
        if (lhu || lh) begin
            if (address[1]) begin
                data0 = bank2_read_data;
            end else begin
                data0 = bank0_read_data;
            end
        end else begin
            data0 = data0_int;
    end

    // data1 write
    if (lw) begin
        data1 = bank1_read_data;
    end else 
        if (lhu || lh) begin
            if (address[1]) begin
                data1_int1 = bank3_read_data;
                data1     = data1_int1;
            end else begin
                data1_int1 = bank1_read_data;
                data1     = data1_int1;
            end
        end else begin
            if (lb && !lbu) begin
                data1_int0 = {8{data0_int[7]}};
                data1      = data1_int0;
            end else begin
                data1_int0 = 8'b00000000;
                data1      = data1_int0;
            end         
    end

    // data2 write
    if (lh) begin
        data2_int = {8{data1_int1[7]}};
    end else begin
        if (lhu) begin
            data2_int = 8'b00000000;
        end else begin
            data2_int = data1_int0;
        end
    end

    data2 = lw ? bank2_read_data : data2_int;
    data3 = lw ? bank3_read_data : data2_int;
end



// assign RD_E = lb || lbu || lh || lhu || lw;
assign data_out = RD_E ? {data3, data2, data1, data0} : 32'hXXXXXXXX;
    
endmodule