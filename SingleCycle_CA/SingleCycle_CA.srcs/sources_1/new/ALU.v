`timescale 1ns / 1ps

module ALU(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult,
    output wire        Zero
);

    wire [32:0] carry;
    wire [31:0] slice_result;
    
    assign carry[0] = (ALUControl == 4'b0001) ? 1'b1 : 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : alu_array
            ALU_1Bit u_1b (
                .a(A[i]),
                .b(B[i]),
                .cin(carry[i]),
                .ALUControl(ALUControl),
                .result(slice_result[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    always @(*) begin
        case (ALUControl)
            4'b0101: ALUResult = A << B[4:0];  // SLL 
            4'b0110: ALUResult = A >> B[4:0];  // SRL 
            default: ALUResult = slice_result; // Output
        endcase
    end
    assign Zero = (ALUResult == 32'd0);

endmodule