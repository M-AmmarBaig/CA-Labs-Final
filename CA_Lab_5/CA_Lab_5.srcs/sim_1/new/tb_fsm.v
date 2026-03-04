
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2026 04:06:18 PM
// Design Name: 
// Module Name: tb_fsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_fsm();
    reg clk;
    reg rst_btn_in;
    reg [15:0] sw_in;
    wire [15:0] led_out;

    // Instantiate the top module
    top uut (
        .clk(clk),
        .rst_btn_in(rst_btn_in),
        .sw_in(sw_in),
        .led_out(led_out)
    );

    // Generate 100 MHz clock (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_btn_in = 0;
        sw_in = 16'b0;

        // 1. Assert physical reset for 15ms to pass the debouncer threshold
        $display("Asserting reset (Waiting 15ms for debouncer)...");
        rst_btn_in = 1;
        #200; 
        
        // De-assert reset and wait another 15ms for the debouncer to clear
        rst_btn_in = 0;
        #200; 
        $display("Reset cleared. FSM should be in IDLE state.");

        // 2. Test Case 1: Standard Countdown
        $display("Starting countdown from 4...");
        sw_in = 16'd4;
        #20; // Allow FSM to capture the state
        sw_in = 16'd0; // Return switches to zero

        // Wait for FSM to count down to 0 
        // (This happens very fast since it drops 1 per clock cycle)
        #200;

        // 3. Test Case 2: Reset Mid-Countdown
        $display("Starting countdown from 15...");
        sw_in = 16'd15;
        #50; // Let it count down for a few cycles
        sw_in = 16'd0;
        
        $display("Pressing reset mid-count (Waiting 15ms for debouncer)...");
        rst_btn_in = 1;
        #200; // Must wait 15ms for the debouncer to pass the reset to the FSM
        rst_btn_in = 0;
        #200; 

        $display("Simulation complete.");
        $finish;
    end
endmodule
