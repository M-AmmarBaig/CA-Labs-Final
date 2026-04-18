`timescale 1ns / 1ps
module leds(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] writeData,
    input  wire        writeEnable,
    input  wire [31:0] memAddress,
    output reg  [15:0] leds_out
);
    // Only write when address bits 9:8 == 2'b10 (512-767)
    wire LEDWrite = writeEnable && (memAddress[9:8] == 2'b10);

    always @(posedge clk or posedge rst) begin
        if (rst) 
            leds_out <= 16'd0;
        else if (LEDWrite) 
            leds_out <= writeData[15:0];
    end
endmodule