`timescale 1ns / 1ps

module Seg7(
    input wire clk,
    input wire rst,
    input wire [7:0] left_val,  // Instruction opcode (Left 2 digits)
    input wire [7:0] right_val, // Countdown value (Right 2 digits)
    output reg [6:0] seg,       // 7-segment patterns
    output reg [3:0] an         // Anode selectors
);

    // 20-bit counter to step down the 100MHz clock to a ~95Hz refresh rate
    reg [19:0] refresh_counter;
    always @(posedge clk or posedge rst) begin
        if (rst)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
    end

    // Use the top 2 bits of the counter to select which of the 4 digits to turn on
    wire [1:0] digit_sel = refresh_counter[19:18];
    reg [3:0] hex_digit;

    always @(*) begin
        case(digit_sel)
            2'b00: begin an = 4'b1110; hex_digit = right_val[3:0]; end   
            2'b01: begin an = 4'b1101; hex_digit = right_val[7:4]; end   
            2'b10: begin an = 4'b1011; hex_digit = left_val[3:0];  end   
            2'b11: begin an = 4'b0111; hex_digit = left_val[7:4];  end   
            default: begin an = 4'b1111; hex_digit = 4'b0000; end
        endcase
    end

    // Hex to 7-Segment Decoder
    always @(*) begin
        case(hex_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end

endmodule