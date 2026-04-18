`timescale 1ns / 1ps
module BranchAdder(
    input  wire [31:0] PC,
    input  wire [31:0] imm,
    output wire [31:0] BranchTarget
);
    assign BranchTarget = PC + (imm << 1); 
endmodule
