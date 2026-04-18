`timescale 1ns / 1ps
module RegisterFile (
    input  wire        clk,
    input  wire        rst,
    input  wire        WriteEnable,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] WriteData,
 
    output wire [31:0] ReadData1,
    output wire [31:0] ReadData2
);
 
    reg [31:0] regs [31:0];
    integer i;
 
    // Synchronous write; x0 writes are ignored
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (WriteEnable && rd != 5'b0) begin
            regs[rd] <= WriteData;
        end
    end
 
    // Asynchronous read; x0 always returns 0
    assign ReadData1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign ReadData2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
 
endmodule