`timescale 1ns / 1ps
module SingleCycle_tb();
    reg clk;
    reg rst;
    reg PCSrc;
    reg [31:0] instruction;
    wire [31:0] PC, PCPlus4, imm, BranchTarget, PCNext;

    ProgCounter u_PC (
        .clk(clk),
        .rst(rst),
        .PC_Next(PCNext),
        .PC(PC)
    );
    PcAdd4 u_pcAdd (
        .PC(PC),
        .PC_Plus4(PCPlus4)
    );
    ImmGen u_immGen (
        .instruction(instruction),
        .imm(imm)
    );
    BranchAdder u_brAdd (
        .PC(PC),
        .imm(imm),
        .BranchTarget(BranchTarget)
    );
    Mux2x1 u_pcmux (
        .in0(PCPlus4),
        .in1(BranchTarget),
        .sel(PCSrc),
        .out(PCNext)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        PCSrc = 0;
        instruction = 32'd0;
        #10;
        rst = 0;

        // TEST 1: Sequential PC+4 updates
        #10; // PC becomes 4
        #10; // PC becomes 8

        // TEST 2: LW x2, 16(x0) -> imm should be +16
        instruction = 32'h01000103;
        #10; // PC becomes 12

        // TEST 3: BEQ forward branch by +8 bytes
        // immGen outputs +4, BranchAdder shifts << 1 to get +8
        // PC should update to (12 + 8) = 20
        instruction = 32'h00208463;
        PCSrc = 1;
        #10; // PC should update to 20

        PCSrc = 0;
        #10; // PC becomes 24

        $finish;
    end
endmodule