`timescale 1ns / 1ps
module ALUControl(
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,     
    output reg  [3:0] ALUControl
);
    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0000; // Load/Store -> ADD
            2'b01: ALUControl = 4'b0001; // Branch -> SUB
            2'b11: ALUControl = 4'b0000; // I-Type (ADDI) -> ADD
            2'b10: begin                 // R-Type
                case(funct3)
                    3'b000: begin
                        if (funct7[5] == 1'b1)  // Extract bit 5 internally
                            ALUControl = 4'b0001; // SUB
                        else
                            ALUControl = 4'b0000; // ADD
                    end
                    3'b001: ALUControl = 4'b0101; // SLL
                    3'b101: ALUControl = 4'b0110; // SRL
                    3'b100: ALUControl = 4'b0100; // XOR
                    3'b110: ALUControl = 4'b0011; // OR
                    3'b111: ALUControl = 4'b0010; // AND
                    default: ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule