`timescale 1ns / 1ps
module ImmGen (
    input  wire [31:0] instruction,
    output reg  [31:0] imm
);

    wire [6:0] opcode = instruction[6:0];

    localparam I_ALU  = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;

    always @(*) begin
        case (opcode)

            // I-type: instr[31:20]
            I_ALU,
            LOAD: begin
                imm = {{20{instruction[31]}}, instruction[31:20]};
            end

            // S-type: instr[31:25] | instr[11:7]
            STORE: begin
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            // B-type: imm[12|10:5|4:1|11]
            BRANCH: begin
                imm = {{20{instruction[31]}}, instruction[31], instruction[7],
                        instruction[30:25], instruction[11:8]};
            end

            default: imm = 32'b0;

        endcase
    end

endmodule