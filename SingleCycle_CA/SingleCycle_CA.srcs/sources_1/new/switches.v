`timescale 1ns / 1ps
module switches(
    input  wire [15:0] switches_in,
    input  wire [31:0] memAddress,
    input  wire        readEnable,
    output wire [31:0] readData
);
    // Priority encoder - highest active switch wins
    wire [15:0] encoded = 
        switches_in[15] ? 16'd15 : switches_in[14] ? 16'd14 :
        switches_in[13] ? 16'd13 : switches_in[12] ? 16'd12 :
        switches_in[11] ? 16'd11 : switches_in[10] ? 16'd10 :
        switches_in[9]  ? 16'd9  : switches_in[8]  ? 16'd8  :
        switches_in[7]  ? 16'd7  : switches_in[6]  ? 16'd6  :
        switches_in[5]  ? 16'd5  : switches_in[4]  ? 16'd4  :
        switches_in[3]  ? 16'd3  : switches_in[2]  ? 16'd2  :
        switches_in[1]  ? 16'd1  : 16'd0;

    // Only respond when address bits 9:8 == 2'b11 (768-1023)
    assign readData = (readEnable && (memAddress[9:8] == 2'b11)) 
                      ? {16'd0, encoded} 
                      : 32'd0;
endmodule