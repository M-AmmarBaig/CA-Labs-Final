`timescale 1ns / 1ps

module ALU_1Bit (
    input  wire       a,
    input  wire       b,
    input  wire       cin,
    input  wire [3:0] ALUControl,
    output reg        result,
    output wire       cout
);

    wire b_inv;
    wire sum;
    
    // Invert B if the operation is Subtraction (ALUControl == 0001)
    assign b_inv = (ALUControl == 4'b0001) ? ~b : b;
    
    // 1-Bit Full Adder Logic
    assign sum  = a ^ b_inv ^ cin;
    assign cout = (a & b_inv) | (cin & (a ^ b_inv));
    
    // 1-Bit Multiplexer
    always @(*) begin
        case (ALUControl)
            4'b0000: result = sum;       // ADD
            4'b0001: result = sum;       // SUB / BEQ
            4'b0010: result = a & b;     // AND
            4'b0011: result = a | b;     // OR
            4'b0100: result = a ^ b;     // XOR
            default: result = 1'b0;      // Shifts are handled at the 32-bit wrapper level
        endcase
    end

endmodule