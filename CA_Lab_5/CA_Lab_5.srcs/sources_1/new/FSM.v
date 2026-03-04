`timescale 1ns / 1ps

module lab5_controller #(
    parameter integer SYS_CLK_FREQ = 100_000_000 // System clock rate (100MHz)
)(
    input wire clk,
    input wire btnC,           // Reset Button
    input wire [15:0] sw,      // Switches as analog inputs ranging from 15 to 0
    output wire [15:0] led,    // Board LEDs
    output wire [6:0] seg,     // Cathode segments
    output wire [3:0] an       // Anode control
);

    wire sys_reset;    
    
    // Instantiating the Debouncer for switch
    debouncer db_inst (
        .clk   (clk),
        .pbin  (btnC),
        .pbout (sys_reset)
    );
    wire [31:0] sw_reg_data;
    reg  [31:0] led_reg_data;
    
    // Base addresses for peripherals
    localparam [29:0] ADDR_SWITCHES = 30'h00000001;
    localparam [29:0] ADDR_LEDS     = 30'h00000002;

    // Switch Interface Module
    switches sw_driver (
        .clk        (clk),
        .rst        (sys_reset),
        .btns       (16'd0),        
        .writeData  (32'd0),        
        .writeEnable(1'b0),
        .readEnable (1'b1),         
        .memAddress (ADDR_SWITCHES),
        .switches   (sw),
        .readData   (sw_reg_data)
    );

    // LED Interface Module
    leds led_driver (
        .clk        (clk),
        .rst        (sys_reset),
        .writeData  (led_reg_data),
        .writeEnable(1'b1),         
        .readEnable (1'b0),
        .memAddress (ADDR_LEDS),
        .readData   (),             
        .leds       (led)
    );

    // Priority Encoder to check for highest priority switched turned on
    function [15:0] get_priority_val;
        input [15:0] raw_input;
        begin
            if (raw_input[15])      get_priority_val = 16'd15;
            else if (raw_input[14]) get_priority_val = 16'd14;
            else if (raw_input[13]) get_priority_val = 16'd13;
            else if (raw_input[12]) get_priority_val = 16'd12;
            else if (raw_input[11]) get_priority_val = 16'd11;
            else if (raw_input[10]) get_priority_val = 16'd10;
            else if (raw_input[9])  get_priority_val = 16'd9;
            else if (raw_input[8])  get_priority_val = 16'd8;
            else if (raw_input[7])  get_priority_val = 16'd7;
            else if (raw_input[6])  get_priority_val = 16'd6;
            else if (raw_input[5])  get_priority_val = 16'd5;
            else if (raw_input[4])  get_priority_val = 16'd4;
            else if (raw_input[3])  get_priority_val = 16'd3;
            else if (raw_input[2])  get_priority_val = 16'd2;
            else if (raw_input[1])  get_priority_val = 16'd1;
            else                    get_priority_val = 16'd0;
        end
    endfunction

    // 1 Hz Timing LOgic
    reg [31:0] clk_div_ctr;
    wire one_sec_pulse = (clk_div_ctr == (SYS_CLK_FREQ - 1));

    always @(posedge clk) begin
        if (sys_reset) begin
            clk_div_ctr <= 32'd0;
        end else begin
            if (one_sec_pulse)
                clk_div_ctr <= 32'd0;
            else
                clk_div_ctr <= clk_div_ctr + 1;
        end
    end

    // Main State Implementation
    localparam ST_IDLE   = 1'b0;
    localparam ST_ACTIVE = 1'b1;

    reg current_state;
    reg [15:0] countdown_val;
    reg is_ready; // Flag to make sure all switches are zero before restarting

    // Calculate the input value from the switch register
    wire [15:0] input_val = get_priority_val(sw_reg_data[15:0]);

    always @(posedge clk) begin
        if (sys_reset) begin
            current_state <= ST_IDLE;
            countdown_val <= 16'd0;
            led_reg_data  <= 32'd0;
            is_ready      <= 1'b0; 
        end else begin
            
            // Ready the system for recountdown when all switches return to zero
            if (sw_reg_data[15:0] == 16'd0) begin
                is_ready <= 1'b1;
            end

            case (current_state)
                ST_IDLE: begin
                    led_reg_data <= 32'd0;
                    // Start if the system is ready and input value is not zero
                    if (is_ready && (input_val != 16'd0)) begin
                        countdown_val <= input_val;
                        current_state <= ST_ACTIVE;
                        is_ready      <= 1'b0; // Clear the is_ready flag
                    end
                end

                ST_ACTIVE: begin
                    // Display the current count on LEDs
                    led_reg_data <= {16'd0, countdown_val};
                    
                    if (one_sec_pulse) begin
                        if (countdown_val > 0) begin
                            countdown_val <= countdown_val - 1;
                        end else begin
                            current_state <= ST_IDLE;
                        end
                    end
                end
            endcase
        end
    end

    // 7 segment display controller 
    assign an = 4'b1110; // Only enable rightmost bit

    function [6:0] get_seg_pattern;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: get_seg_pattern = 7'b1000000; // 0
                4'h1: get_seg_pattern = 7'b1111001; // 1
                4'h2: get_seg_pattern = 7'b0100100; // 2
                4'h3: get_seg_pattern = 7'b0110000; // 3
                4'h4: get_seg_pattern = 7'b0011001; // 4
                4'h5: get_seg_pattern = 7'b0010010; // 5
                4'h6: get_seg_pattern = 7'b0000010; // 6
                4'h7: get_seg_pattern = 7'b1111000; // 7
                4'h8: get_seg_pattern = 7'b0000000; // 8
                4'h9: get_seg_pattern = 7'b0010000; // 9
                4'hA: get_seg_pattern = 7'b0001000; // A
                4'hB: get_seg_pattern = 7'b0000011; // B
                4'hC: get_seg_pattern = 7'b1000110; // C
                4'hD: get_seg_pattern = 7'b0100001; // D
                4'hE: get_seg_pattern = 7'b0000110; // E
                4'hF: get_seg_pattern = 7'b0001110; // F
                default: get_seg_pattern = 7'b1111111; // Off
            endcase
        end
    endfunction

    assign seg = get_seg_pattern(countdown_val[3:0]);

endmodule

module debouncer(
    input clk,
    input pbin,
    output reg pbout = 0  // Initialise to zero
    );

    parameter DELAY_COUNTS = 4; 
    reg [21:0] counter = 0;     
    reg sync_0 = 0, sync_1 = 0; 

    always @(posedge clk) begin
        sync_0 <= pbin;
        sync_1 <= sync_0;
    end

    always @(posedge clk) begin
        if (sync_1 == pbout) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == DELAY_COUNTS) begin
                pbout <= sync_1;
                counter <= 0;
            end
        end
    end
endmodule

module switches(
    input clk,
    input rst,
    input [15:0] btns,          
    input [31:0] writeData,     
    input writeEnable,          
    input readEnable,
    input [29:0] memAddress,    
    input [15:0] switches,      
    output reg [31:0] readData
    );

    always @(posedge clk) begin
        if (rst) begin
            readData <= 32'b0;
        end else begin

            
            if (readEnable)
                readData <= {16'h0000, switches};
            else
                readData <= 32'b0;
        end
    end
endmodule

module leds(
    input clk,
    input rst,
    input [31:0] writeData,
    input writeEnable,
    input readEnable,          
    input [29:0] memAddress,   
    output [31:0] readData,    
    output reg [15:0] leds     
    );

    
    assign readData = 32'b0;
    always @(posedge clk) begin
        if (rst) begin
            leds <= 16'b0;
        end else begin
            if (writeEnable) begin
                leds <= writeData[15:0];
            end
        end
    end
endmodule