// Part 1: Smallest piece of the ALU (1-bit)
module ALU1bit (
    input a, b, cin,    
    input [3:0] op,     
    output reg res,     
    output cout         
);
    wire add_res;

    assign cout = (op == 4'b0100) ? ((a & ~b) | (~b & cin) | (a & cin)) :
                                    ((a & b) | (b & cin) | (a & cin));
                                    
    assign add_res = (op == 4'b0100) ? a ^ ~b ^ cin : a ^ b ^ cin;

    always @(*) begin
        case (op)
            4'b0000: res = a & b;           
            4'b0001: res = a | b;           
            4'b0010: res = a ^ b;           
            4'b0011, 4'b0100: res = add_res; 
            default: res = 1'b0;            
        endcase
    end
endmodule

// Part 2: Putting 32 of those bits together
module ALU32bit (
    input [31:0] a_in,  
    input [31:0] b_in,  
    input [3:0] select, 
    output reg [31:0] result, 
    output zero_flag    
); 
    wire [31:0] logic_arith;
    wire [31:0] shifter;
    wire [31:0] carry_chain;
    
    wire init_cin = (select == 4'b0100); 

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : alu_gen
            ALU1bit unit (
                .a(a_in[i]), 
                .b(b_in[i]), 
                .cin(i == 0 ? init_cin : carry_chain[i-1]), 
                .op(select),
                .res(logic_arith[i]), 
                .cout(carry_chain[i])
            );
        end
    endgenerate

    assign shifter = (select == 4'b0101) ? (a_in << b_in[4:0]) :
                     (select == 4'b0110) ? (a_in >> b_in[4:0]) : 32'h0;

    always @(*) begin
        if (select == 4'b0101 || select == 4'b0110) 
            result = shifter;
        else 
            result = logic_arith;
    end

    assign zero_flag = (result == 32'b0);
endmodule

// Part 3: Turning numbers into 7-segment display patterns
module hex_to_7seg(
    input [3:0] hex,
    output reg [6:0] seg
);
    always @(*) begin
        case(hex)
            4'h0: seg = 7'b1000000; 4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100; 4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001; 4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010; 4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000; 4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000; 4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110; 4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110; 4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule

// Part 4: Debouncer with a configurable wait time
module debounce_vector #(parameter WIDTH = 16, parameter WAIT_VAL = 20'hFFFFF) (
    input clk,
    input [WIDTH-1:0] noisy_stuff,
    // FIX: Initialize to 0 so we don't start with 'X'
    output reg [WIDTH-1:0] clean_stuff = 0 
);
    reg [19:0] timer = 0; 
    // FIX: Initialize to 0 so we don't start with 'X'
    reg [WIDTH-1:0] sync_0 = 0, sync_1 = 0; 

    always @(posedge clk) begin
        sync_0 <= noisy_stuff;
        sync_1 <= sync_0;

        if (sync_1 != clean_stuff) begin
            timer <= timer + 1;
            if (timer >= WAIT_VAL) begin
                clean_stuff <= sync_1;
                timer <= 0;
            end
        end else begin
            timer <= 0;
        end
    end
endmodule

// Part 5: Top Module
// FIX: Added the parameter here so the testbench can reach it easily
module top_module #(parameter DEBOUNCE_WAIT = 20'hFFFFF) (
    input clk,
    input [5:0] a_in,      
    input [5:0] b_in,      
    input [3:0] select,    
    output [7:0] result,   
    output zero_flag,      
    output [6:0] seg,      
    output [3:0] an       
);
    wire [5:0] a_clean, b_clean;
    wire [3:0] sel_clean;

    // Use the DEBOUNCE_WAIT parameter instead of a hardcoded number
    debounce_vector #(.WIDTH(16), .WAIT_VAL(DEBOUNCE_WAIT)) filter (
        .clk(clk),
        .noisy_stuff({select, b_in, a_in}),
        .clean_stuff({sel_clean, b_clean, a_clean})
    );

    wire [31:0] A_32 = {26'b0, a_clean};
    wire [31:0] B_32 = {26'b0, b_clean};
    wire [31:0] RES_32;

    ALU32bit uut (A_32, B_32, sel_clean, RES_32, zero_flag);

    assign result = RES_32[7:0];
    assign an = 4'b1110; 
    hex_to_7seg display (.hex(RES_32[3:0]), .seg(seg));
endmodule