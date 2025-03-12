module decoder_7_seg(
    input [3:0] decoder_in,
    output reg [0:6] decoder_out
);
    // Segun el caso, cambiara la salida del display y sera interpretada por este
    always @(*) 
        begin
            case (decoder_in)
                0: decoder_out = 1;
                1: decoder_out = 7'h4F;
                4'h2: decoder_out = 7'h12;
                4'h3: decoder_out = 7'h06;
                4'h4: decoder_out = 7'h4C;
                4'h5: decoder_out = 7'h24;
                4'h6: decoder_out = 7'h20;
                4'h7: decoder_out = 7'h0F;
                4'h8: decoder_out = 0;
                4'h9: decoder_out = 7'h04;
                4'hA: decoder_out = 7'h08;
                4'hB: decoder_out = 7'h60;
                4'hC: decoder_out = 7'h31;
                4'hD: decoder_out = 7'h42;
                4'hE: decoder_out = 7'h30;
                4'hF: decoder_out = 7'h38;
                default: decoder_out = 7'hFF;
            endcase
        end
endmodule