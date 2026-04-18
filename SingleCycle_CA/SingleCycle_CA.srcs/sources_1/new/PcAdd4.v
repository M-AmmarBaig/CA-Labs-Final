`timescale 1ns / 1ps
module PcAdd4(
    input  wire [31:0] PC,
    output wire [31:0] PC_Plus4
);
    assign PC_Plus4 = PC + 32'd4; // Computes sequential address
endmodule