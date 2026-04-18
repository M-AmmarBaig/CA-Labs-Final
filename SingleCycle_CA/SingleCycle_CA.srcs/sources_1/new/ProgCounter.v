`timescale 1ns / 1ps
module ProgCounter(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] PC_Next,
    output reg  [31:0] PC
);
    always @(posedge clk) begin
        if (rst)
            PC <= 32'd0;   
        else
            PC <= PC_Next;  // Update PC on every clock edge
    end
endmodule