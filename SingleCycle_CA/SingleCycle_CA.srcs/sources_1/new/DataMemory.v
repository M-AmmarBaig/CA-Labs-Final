`timescale 1ns / 1ps
module DataMemory (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [8:0]  address,  
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    reg [31:0] memory [0:511];

    always @(posedge clk) begin
        if (MemWrite) begin
            memory[address] <= write_data; 
        end
    end

    always @(*) begin
        if (MemRead) begin
            read_data = memory[address];
        end else begin
            read_data = 32'd0;
        end
    end

endmodule
