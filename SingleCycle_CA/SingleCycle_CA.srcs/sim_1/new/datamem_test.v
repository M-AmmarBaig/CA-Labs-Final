`timescale 1ns / 1ps

// ============================================================
//  DataMemory - BUGGY version: uses address[8:0] directly
// ============================================================
module DataMemory_BUG (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] memory [0:511];

    // Pre-load known values so we can see what gets read back
    integer i;
    initial begin
        for (i = 0; i < 512; i = i + 1)
            memory[i] = i * 10;   // memory[0]=0, memory[1]=10, memory[2]=20 ...
    end

    always @(posedge clk) begin
        if (MemWrite)
            memory[address[8:0]] <= write_data;   // BUG: byte addr used as word index
    end
    always @(*) begin
        if (MemRead) read_data = memory[address[8:0]];
        else         read_data = 32'd0;
    end
endmodule

// ============================================================
//  DataMemory - FIXED version: uses address[10:2]  (÷4)
// ============================================================
module DataMemory_FIXED (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] memory [0:511];

    integer i;
    initial begin
        for (i = 0; i < 512; i = i + 1)
            memory[i] = i * 10;   // same initial values
    end

    wire [8:0] word_index = address[10:2];   // FIX: divide byte addr by 4

    always @(posedge clk) begin
        if (MemWrite)
            memory[word_index] <= write_data;
    end
    always @(*) begin
        if (MemRead) read_data = memory[word_index];
        else         read_data = 32'd0;
    end
endmodule

// ============================================================
//  Testbench
// ============================================================
module tb_DataMemory_compare;

    // Clock
    reg clk = 0;
    always #5 clk = ~clk;   // 10 ns period

    // Shared stimulus signals
    reg         MemWrite, MemRead;
    reg  [31:0] address, write_data;

    // Separate read-data outputs
    wire [31:0] rd_bug, rd_fix;

    // Instantiate both
    DataMemory_BUG  u_bug  (.clk(clk), .MemWrite(MemWrite), .MemRead(MemRead),
                             .address(address), .write_data(write_data),
                             .read_data(rd_bug));

    DataMemory_FIXED u_fix (.clk(clk), .MemWrite(MemWrite), .MemRead(MemRead),
                             .address(address), .write_data(write_data),
                             .read_data(rd_fix));

    // Helper task - read at a byte address and print both results
    task do_read;
        input [31:0] byte_addr;
        input [31:0] expected_word_index;
        begin
            address  = byte_addr;
            MemRead  = 1;
            MemWrite = 0;
            #1; // let combinational settle
            $display("--------------------------------------------------");
            $display("Byte address      : %0d  (0x%08h)", byte_addr, byte_addr);
            $display("Expected index    : memory[%0d]  => value = %0d",
                      expected_word_index, expected_word_index * 10);
            $display("[BUG]  address[8:0]  = %0d  => read_data = %0d  %s",
                      byte_addr[8:0], rd_bug,
                      (rd_bug == expected_word_index*10) ? "CORRECT" : "WRONG <---");
            $display("[FIX]  address[10:2] = %0d  => read_data = %0d  %s",
                      byte_addr[10:2], rd_fix,
                      (rd_fix == expected_word_index*10) ? "CORRECT" : "WRONG <---");
            #9; // rest of clock cycle
        end
    endtask

    // Helper task - write then read back
    task do_write_read;
        input [31:0] byte_addr;
        input [31:0] wdata;
        begin
            // Write on rising edge
            address    = byte_addr;
            write_data = wdata;
            MemWrite   = 1;
            MemRead    = 0;
            @(posedge clk); #1;
            MemWrite = 0;
            MemRead  = 1;
            #1;
            $display("--------------------------------------------------");
            $display("WRITE 0x%08h to byte address %0d, then read back:", wdata, byte_addr);
            $display("[BUG]  wrote to memory[%0d], reads memory[%0d] => %0d  %s",
                      byte_addr[8:0], byte_addr[8:0], rd_bug,
                      (rd_bug == wdata) ? "OK" : "MISMATCH <---");
            $display("[FIX]  wrote to memory[%0d], reads memory[%0d] => %0d  %s",
                      byte_addr[10:2], byte_addr[10:2], rd_fix,
                      (rd_fix == wdata) ? "OK" : "MISMATCH <---");
            #9;
        end
    endtask

    initial begin
        MemRead = 0; MemWrite = 0;
        address = 0; write_data = 0;
        #12;

        $display("==================================================");
        $display("  READ TEST - pre-loaded memory[i] = i*10        ");
        $display("==================================================");

        // Byte addr 0  => word index 0 => value 0
        do_read(32'd0,  32'd0);

        // Byte addr 4  => word index 1 => value 10
        // BUG reads memory[4]=40 instead of memory[1]=10
        do_read(32'd4,  32'd1);

        // Byte addr 8  => word index 2 => value 20
        // BUG reads memory[8]=80 instead
        do_read(32'd8,  32'd2);

        // Byte addr 12 => word index 3 => value 30
        do_read(32'd12, 32'd3);

        // Byte addr 40 => word index 10 => value 100
        // BUG reads memory[40]=400 instead
        do_read(32'd40, 32'd10);

        $display("");
        $display("==================================================");
        $display("  WRITE-THEN-READ TEST                           ");
        $display("==================================================");

        // Write 0xDEADBEEF to byte address 8
        // BUG: writes to memory[8], correct: writes to memory[2]
        do_write_read(32'd8, 32'hDEADBEEF);

        // Write 0xCAFEBABE to byte address 20
        // BUG: writes to memory[20], correct: writes to memory[5]
        do_write_read(32'd20, 32'hCAFEBABE);

        $display("==================================================");
        $display("  DONE");
        $display("==================================================");
        $finish;
    end

endmodule