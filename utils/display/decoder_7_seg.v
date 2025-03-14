module decoder_7_seg(
    input [4:0] value,
    input enable,
    output reg [0:6] segments
);
    always @(*) begin
        if (!enable)
            segments = 7'b1111111;
        else begin
            case (value)
                5'h00: segments = 7'b0000001;  // 0
                5'h01: segments = 7'b1001111;  // 1
                5'h02: segments = 7'b0010010;  // 2
                5'h03: segments = 7'b0000110;  // 3
                5'h04: segments = 7'b1001100;  // 4
                5'h05: segments = 7'b0100100;  // 5
                5'h06: segments = 7'b0100000;  // 6
                5'h07: segments = 7'b0001111;  // 7
                5'h08: segments = 7'b0000000;  // 8
                5'h09: segments = 7'b0000100;  // 9
                5'h0A: segments = 7'b0001000;  // A
                5'h0B: segments = 7'b1100000;  // B
                5'h0C: segments = 7'b0110001;  // C
                5'h0D: segments = 7'b1000010;  // D
                5'h0E: segments = 7'b0110000;  // E
                5'h0F: segments = 7'b0111000;  // F
                5'h10: segments = 7'b1111110;  // -
                default: segments = 7'b1111111;
            endcase
        end
    end
endmodule
