module hvsync_generator(
    input clk,
    output vga_h_sync,
    output vga_v_sync,
    output reg inDisplayArea,
    output reg [9:0] counterX,
    output reg [9:0] counterY
);
    reg vga_HS, vga_VS;

    wire CounterXmaxed = (counterX == 800); // 16 + 48 + 96 + 640
    wire CounterYmaxed = (counterY == 525); // 10 + 2 + 33 + 480

    always @(posedge clk)
    if (CounterXmaxed)
        counterX <= 0;
    else
        counterX <= counterX + 1;

    always @(posedge clk)
    begin
        if (CounterXmaxed)
        begin
            if (CounterYmaxed)
                counterY <= 0;
            else
                counterY <= counterY + 1;
        end
    end

    always @(posedge clk)
    begin
        vga_HS <= (counterX > (640 + 16) && (counterX < (640 + 16 + 96)));
        vga_VS <= (counterY > (480 + 10) && (counterY < (480 + 10 + 2)));
    end

    always @(posedge clk)
    begin
        inDisplayArea <= (counterX < 640) && (counterY < 480);
    end

    assign vga_h_sync = ~vga_HS;
    assign vga_v_sync = ~vga_VS;
endmodule
