`timescale 1ns / 1ps


module ALU1bit (
    input A, B, carryIn,
    input [3:0] ALUctl,
    output reg Result,
    output carryOut
);
    wire sum;
    assign carryOut = (ALUctl == 4'b0100) ? ((A & ~B) | (~B & carryIn) | (A & carryIn)) : ((A & B) | (B & carryIn) | (A & carryIn));
    assign sum = (ALUctl == 4'b0100) ? A ^ ~B ^ carryIn : A ^ B ^ carryIn;
    
    always @(*) begin
        case (ALUctl)
            4'b0000: Result = A & B;      // AND
            4'b0001: Result = A | B;      // OR
            4'b0010: Result = A ^ B;      // XOR
            4'b0011: Result = sum;        // ADD
            4'b0100: Result = sum;        // SUB
            4'b0101: Result = B << 1;     // SLL
            4'b0110: Result = B >> 1;     // SRL
            default: Result = 0;
        endcase
    end
endmodule


module ALU32bit (
    input [31:0] A, B,
    input [3:0] ALUctl,
    output reg [31:0] ALUResult,
    output Zero
);
    wire [31:0] cascaded_result;
    wire [31:0] shift_result;
    wire [31:0] carryWire;
    
    wire i_cin = (ALUctl == 4'b0100) ? 1'b1 : 1'b0; 
    
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : alu_slice
            ALU1bit bit_slice (
                .A(A[i]),
                .B(B[i]),
                .carryIn(i == 0 ? i_cin : carryWire[i-1]),
                .ALUctl(ALUctl),
                .Result(cascaded_result[i]),
                .carryOut(carryWire[i])
            );
        end
    endgenerate
    
    assign shift_result = (ALUctl == 4'b0101) ? (A << B[4:0]) : 
                          (ALUctl == 4'b0110) ? (A >> B[4:0]) : 
                          32'b0;
                          
    always @(*) begin
        if (ALUctl == 4'b0101 | ALUctl == 4'b0110)
            ALUResult = shift_result;
        else
            ALUResult = cascaded_result;
    end
    
    assign Zero = (ALUResult == 0);
endmodule

module RegisterFile(clk, reset, reg_write, rs1, rs2, rd, write_data, read_data1, read_data2);
    input wire clk, reset, reg_write;
    input wire [4:0] rs1, rs2, rd;
    input wire [31:0] write_data;
    output reg [31:0] read_data1, read_data2;
    reg [31:0] registers [31:0];

    integer k;
    initial begin
        registers[0] = 32'd0;
        for(k=1; k<32; k=k+1)
            registers[k] = k + 1; // Hard coded values for registers r[k] = 2 * k
    end
    
    always@(posedge clk) begin
        if(reg_write && rd != 5'd0)
            registers[rd] <= write_data;
    end

    always@(*) begin
        if(reset) begin 
            read_data1 = 32'd0; 
            read_data2 = 32'd0; 
        end
        else begin 
            read_data1 = registers[rs1]; 
            read_data2 = registers[rs2]; 
        end
    end
endmodule


module bcd_converter(
    input wire [15:0] value,   
    output reg [3:0] digit_0, 
    output reg [3:0] digit_1, 
    output reg [3:0] digit_2, 
    output reg [3:0] digit_3  
);
    integer i;
    always @(value) begin
        
        digit_0 = 4'd0;
        digit_1 = 4'd0;
        digit_2 = 4'd0;
        digit_3 = 4'd0;

        
        for (i = 15; i >= 0; i = i - 1) begin
            
            if (digit_3 >= 5) digit_3 = digit_3 + 3;
            if (digit_2 >= 5) digit_2 = digit_2 + 3;
            if (digit_1 >= 5) digit_1 = digit_1 + 3;
            if (digit_0 >= 5) digit_0 = digit_0 + 3;

            
            digit_3 = digit_3 << 1;
            digit_3[0] = digit_2[3];
            digit_2 = digit_2 << 1;
            digit_2[0] = digit_1[3];
            digit_1 = digit_1 << 1;
            digit_1[0] = digit_0[3];
            digit_0 = digit_0 << 1;
            digit_0[0] = value[i];
        end
    end
endmodule


// ==========================================
// Seven Segment Display Controller (Corrected)
// ==========================================
module seven_segment (
    input wire clk,             
    input wire reset,           
    input wire [3:0] digit_0,   
    input wire [3:0] digit_1,   
    input wire [3:0] digit_2,   
    input wire [3:0] digit_3,   
    output reg [6:0] seg,       
    output reg [3:0] an         
);
    reg [15:0] count_mux;
    reg [1:0] digit_select; 
    localparam MUX_RATE = 16'd12500; 

    always @(posedge clk) begin
        if (reset) begin
            count_mux <= 16'd0;
            digit_select <= 2'b00;
            // REMOVED: an <= 4'b1111; (This was causing the Multiple Driver error!)
        end else begin
            if (count_mux == MUX_RATE - 1) begin
                count_mux <= 16'd0;
                digit_select <= digit_select + 2'b01; 
            end else begin
                count_mux <= count_mux + 16'd1;
            end
        end
    end

    reg [3:0] current_digit;
    always @(*) begin
        // If reset is active, force anodes off. Otherwise, multiplex normally.
        if (reset) begin
            an = 4'b1111;
            current_digit = 4'd10; // Dash/Blank
        end else begin
            case (digit_select)
                2'b00: begin current_digit = digit_0; an = 4'b1110; end
                2'b01: begin current_digit = digit_1; an = 4'b1101; end
                2'b10: begin current_digit = digit_2; an = 4'b1011; end
                2'b11: begin current_digit = digit_3; an = 4'b0111; end
                default: begin current_digit = 4'd10; an = 4'b1111; end
            endcase
        end
    end

    always @(*) begin
        case (current_digit)
            4'd0:  seg = 7'b1000000;
            4'd1:  seg = 7'b1111001;
            4'd2:  seg = 7'b0100100;
            4'd3:  seg = 7'b0110000;
            4'd4:  seg = 7'b0011001;
            4'd5:  seg = 7'b0010010;
            4'd6:  seg = 7'b0000010;
            4'd7:  seg = 7'b1111000;
            4'd8:  seg = 7'b0000000;
            4'd9:  seg = 7'b0010000;
            4'hA:  seg = 7'b0001000; 
            4'hB:  seg = 7'b0000011; 
            4'hC:  seg = 7'b1000110; 
            4'hD:  seg = 7'b0100001; 
            4'hE:  seg = 7'b0000110; 
            4'hF:  seg = 7'b0001110; 
            4'd10: seg = 7'b0111111; 
            default: seg = 7'b1111111;
        endcase
    end
endmodule


module top_lab6(
    input wire clk,
    input wire reset,             // Map to center push button
    input wire [2:0] rs1_sw,      // Map to sw[2:0]
    input wire [2:0] rs2_sw,      // Map to sw[5:3]
    input wire [2:0] rd_sw,       // Map to sw[8:6]
    input wire [3:0] ALUctl,      // Map to sw[12:9]
    input wire reg_write,         // Map to sw[13]
    output wire [6:0] seg,        // 7-segment segments
    output wire [3:0] an,         // 7-segment anodes
    output wire zero              // Map to LED[0]
);
    
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] ALUResult;
    wire [3:0] digit_0, digit_1, digit_2, digit_3;

    
    RegisterFile reg_file_inst(
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .rs1({2'b00, rs1_sw}), 
        .rs2({2'b00, rs2_sw}), 
        .rd({2'b00, rd_sw}),   
        .write_data(ALUResult), 
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    ALU32bit ALu_inst(
        .A(read_data1),
        .B(read_data2),
        .ALUctl(ALUctl),
        .ALUResult(ALUResult),
        .Zero(zero)
    );

    
    bcd_converter bcd_inst (
        .value(ALUResult[15:0]), 
        .digit_0(digit_0),
        .digit_1(digit_1),
        .digit_2(digit_2),
        .digit_3(digit_3)
    );

    seven_segment seg_inst (
        .clk(clk),
        .reset(reset),
        .digit_0(digit_0),
        .digit_1(digit_1),
        .digit_2(digit_2),
        .digit_3(digit_3),
        .seg(seg),
        .an(an)
    );
endmodule