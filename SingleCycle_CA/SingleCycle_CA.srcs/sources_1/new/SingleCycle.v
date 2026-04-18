`timescale 1ns / 1ps
module SingleCycle(
    input wire clk,
    input wire rst,
    
    // NEW: I/O ports
    input  wire [15:0] switches,
    output wire [15:0] leds,
    output wire [6:0] seg,      
    output wire [3:0] an
    
);
    
    // Internal wires - PC path
    wire [31:0] PC, PC_Next, PC_Plus4;
    wire [31:0] instruction;
    
    // Internal wires - Control signals
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0] ALUOp;
    wire [3:0] ALU_Ctrl_Signal;
    wire PCSrc;
    
    // Internal wires - Datapath
    wire [31:0] imm;
    wire [31:0] readData1, readData2, WriteData;
    wire [31:0] ALU_B, ALUResult;
    wire Zero;
    wire [31:0] mem_read_data;
    wire [31:0] BranchTarget;
    
    // NEW: I/O wires
    wire [31:0] sw_read_data;
    wire [31:0] final_read_data;

    // NEW: Address decode - only use DataMemory when address range is 00
    assign final_read_data = (ALUResult[9:8] == 2'b11) ? sw_read_data : mem_read_data;
    
    reg [3:0] clk_div = 0;
    reg clk10Mhz = 0;
    
    always @(posedge clk) begin
        if (clk_div == 4) begin
            clk_div <= 0;
            clk10Mhz <= ~clk10Mhz;
        end else begin
            clk_div <= clk_div + 1;
        end
    end

    //----------------------------------------------------------
    // FETCH STAGE
    //----------------------------------------------------------
    
    ProgCounter u_PC (
        .clk(clk10Mhz),
        .rst(rst),
        .PC_Next(PC_Next),
        .PC(PC)
    );
    PcAdd4 u_PA4 (
        .PC(PC),
        .PC_Plus4(PC_Plus4)
    );
    instructionMemory u_IM (
        .instAddress(PC),
        .instruction(instruction)
    );
    //----------------------------------------------------------
    // DECODE STAGE
    //----------------------------------------------------------
    MainControl u_MainControl (
        .opcode(instruction[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite)
    );
    RegisterFile u_RF (
        .clk(clk10Mhz),
        .rst(rst),
        .WriteEnable(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .WriteData(WriteData),
        .ReadData1(readData1),
        .ReadData2(readData2)
    );
    ImmGen u_ImmG (
        .instruction(instruction),
        .imm(imm)
    );
    //----------------------------------------------------------
    // EXECUTE STAGE
    //----------------------------------------------------------
    ALUControl u_ALUCon (
        .ALUOp(ALUOp),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .ALUControl(ALU_Ctrl_Signal)
    );
    Mux2x1 u_ALUSrcMux (
        .in0(readData2),
        .in1(imm),
        .sel(ALUSrc),
        .out(ALU_B)
    );
    ALU u_ALU (
        .A(readData1),
        .B(ALU_B),
        .ALUControl(ALU_Ctrl_Signal),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );
    BranchAdder u_BA (
        .PC(PC),
        .imm(imm),
        .BranchTarget(BranchTarget)
    );
    // Branch is taken only when Branch control is high and ALU result is zero
    assign PCSrc = Branch & Zero;
    Mux2x1 u_PCMux (
        .in0(PC_Plus4),
        .in1(BranchTarget),
        .sel(PCSrc),
        .out(PC_Next)
    );
    //----------------------------------------------------------
    // MEMORY STAGE
    //----------------------------------------------------------
    DataMemory u_DataMem (
        .clk(clk10Mhz),
        .MemWrite(MemWrite & (ALUResult[9:8] == 2'b00)),   // NEW: only write to RAM
        .MemRead(MemRead   & (ALUResult[9:8] == 2'b00)),   // NEW: only read from RAM
        .address(ALUResult[10:2]),
        .write_data(readData2),
        .read_data(mem_read_data)
    );
    //----------------------------------------------------------
    // WRITEBACK STAGE
    //----------------------------------------------------------
    Mux2x1 u_MemtoRegMux (
        .in0(ALUResult),
        .in1(final_read_data),   // CHANGED: was mem_read_data, now includes switch data
        .sel(MemtoReg),
        .out(WriteData)
    );

    //----------------------------------------------------------
    // NEW: I/O MODULE INSTANTIATIONS
    //----------------------------------------------------------
    switches u_Switches (
        .switches_in(switches),
        .memAddress(ALUResult),
        .readEnable(MemRead),
        .readData(sw_read_data)
    );

    leds u_LEDs (
        .clk(clk),
        .rst(rst),
        .writeData(readData2),
        .writeEnable(MemWrite),
        .memAddress(ALUResult),
        .leds_out(leds)
    );
    
    reg [15:0] captured_opcode;
    reg [15:0] prev_switches;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            captured_opcode <= 16'd0;
            prev_switches <= 16'd0;
        end else begin
            prev_switches <= switches;
            // Capture opcode last 4 hex digits (instruction[15:0]) at rising edge of switch
            if (switches != 16'd0 && prev_switches == 16'd0) begin
                captured_opcode <= instruction[15:0];
            end
        end
    end

    Seg7 u_7seg (
        .clk(clk), // 100MHz for refresh
        .rst(rst),            
        .left_val(captured_opcode[15:8]), 
        .right_val(captured_opcode[7:0]), 
        .seg(seg), 
        .an(an)
    ); 

endmodule