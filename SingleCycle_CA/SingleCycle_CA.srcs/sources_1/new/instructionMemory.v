module instructionMemory #(
    parameter OPERAND_LENGTH = 31
)(
    input [OPERAND_LENGTH:0] instAddress,
    output [31:0] instruction
);
    reg [31:0] memory [0:63];     
    initial begin
        // Only use the file. No for loops!
        $readmemh("lab10.mem", memory); 
    end
    // Word-aligned: byte address / 4 = index
    assign instruction = memory[instAddress[7:2]]; 
endmodule