`timescale 1ns / 1ps



module AddressDecoder (
    input  wire        readEnable,
    input  wire        writeEnable,
    input  wire [9:0]  address,
    output wire        DataMemWrite,
    output wire        DataMemRead,
    output wire        LEDWrite,
    output wire        SwitchReadEnable
);
    wire DataMemSelect = (address[9:8] == 2'b00);
    wire LEDSelect     = (address[9:8] == 2'b01);
    wire SwitchSelect  = (address[9:8] == 2'b10);

    assign DataMemWrite     = DataMemSelect & writeEnable;
    assign DataMemRead      = DataMemSelect & readEnable;
    assign LEDWrite         = LEDSelect     & writeEnable;
    assign SwitchReadEnable = SwitchSelect  & readEnable;
endmodule


module DataMemory (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [8:0]  address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] mem [0:511];

    integer idx;
    initial begin
        for (idx = 0; idx < 512; idx = idx + 1)
            mem[idx] = 32'h0000_0000;
    end

    always @(posedge clk) begin
        if (MemWrite)
            mem[address] <= write_data;
    end

    assign read_data = MemRead ? mem[address] : 32'h0000_0000;
endmodule


module debouncer (
    input      clk,
    input      pbin,
    output reg pbout
);
    reg [15:0] count;
    reg        pb_sync_0, pb_sync_1;

    initial begin
        pbout     = 1'b0;
        count     = 16'd0;
        pb_sync_0 = 1'b0;
        pb_sync_1 = 1'b0;
    end

    always @(posedge clk) begin
        pb_sync_0 <= pbin;
        pb_sync_1 <= pb_sync_0;
        if (pb_sync_1 == pbout)
            count <= 16'd0;
        else begin
            count <= count + 1'b1;
            if (count == 16'hFFFF)
                pbout <= ~pbout;
        end
    end
endmodule


module switches (
    input             clk,
    input             rst,
    input  [15:0]     btns,
    input  [31:0]     writeData,
    input             writeEnable,
    input             readEnable,
    input  [29:0]     memAddress,
    input  [15:0]     switches,
    output reg [31:0] readData
);
    initial readData = 32'd0;

    always @(posedge clk) begin
        if (rst)
            readData <= 32'd0;
        else if (readEnable)
            readData <= {16'd0, switches};
        else
            readData <= 32'd0;
    end
endmodule



module leds (
    input             clk,
    input             rst,
    input  [31:0]     writeData,
    input             writeEnable,
    input             readEnable,
    input  [29:0]     memAddress,
    output reg [31:0] readData,
    output reg [15:0] leds
);
    initial begin
        readData = 32'd0;
        leds     = 16'd0;
    end

    always @(posedge clk) begin
        if (rst) begin
            leds     <= 16'd0;
            readData <= 32'd0;
        end else if (writeEnable) begin
            leds <= writeData[15:0];
        end
    end
endmodule


module addressDecoderTop (
    input  wire  clk,
    input  wire  rst,
    input  wire [15:0] switches,
    output wire [15:0] leds,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire    dp
);

   
    wire clean_rst;
    debouncer u_deb (
        .clk   (clk),
        .pbin  (rst),
        .pbout (clean_rst)
    );


    reg  [31:0] cpu_address;
    reg         cpu_readEnable;
    reg         cpu_writeEnable;
    reg  [31:0] cpu_writeData;
    wire [31:0] cpu_readData;

   
    wire DataMemWrite, DataMemRead, LEDWrite, SwitchReadEnable;

    AddressDecoder u_dec (
        .readEnable       (cpu_readEnable),
        .writeEnable      (cpu_writeEnable),
        .address          (cpu_address[9:0]),
        .DataMemWrite     (DataMemWrite),
        .DataMemRead      (DataMemRead),
        .LEDWrite         (LEDWrite),
        .SwitchReadEnable (SwitchReadEnable)
    );

 
    wire [31:0] dataMemReadData;

    DataMemory u_mem (
        .clk        (clk),
        .MemWrite   (DataMemWrite),
        .MemRead    (DataMemRead),
        .address    (cpu_address[8:0]),
        .write_data (cpu_writeData),
        .read_data  (dataMemReadData)
    );


    leds u_leds (
        .clk         (clk),
        .rst         (clean_rst),
        .writeData   (cpu_writeData),
        .writeEnable (LEDWrite),
        .readEnable  (1'b0),
        .memAddress  (30'd0),
        .readData    (),
        .leds        (leds)
    );

 
    wire [31:0] switchReadData;

    switches u_sw (
        .clk         (clk),
        .rst         (clean_rst),
        .btns        (16'd0),
        .writeData   (32'd0),
        .writeEnable (1'b0),
        .readEnable  (SwitchReadEnable),
        .memAddress  (30'd0),
        .switches    (switches),
        .readData    (switchReadData)
    );


    assign cpu_readData = DataMemRead      ? dataMemReadData :
                          SwitchReadEnable ? switchReadData  :
                                             32'h0000_0000;


    localparam [1:0] S_IDLE = 2'd0,
                     S_ACT  = 2'd1,
                     S_HOLD = 2'd2;


    reg [1:0]  last_mode;


    wire [1:0] mode = switches[15:14];
    
    // NEED TO BE COMPLETED

endmodule