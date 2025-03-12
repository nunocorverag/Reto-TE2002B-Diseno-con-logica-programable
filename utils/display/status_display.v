module status_display(
    input incorrect, done,
    output reg [0:6] HEX_0, HEX_1, HEX_2, HEX_3, HEX_4, HEX_5
);
    always @(*) 
        begin
            if(done == 1)
                begin
                    if(incorrect == 1)
                        begin
                            HEX_5 = 7'b1111111;
                            HEX_4 = 7'b0110000;
                            HEX_3 = 7'b1111010;
                            HEX_2 = 7'b1111010; 
                            HEX_1 = 7'b1100010;
                            HEX_0 = 7'b1111010; 
                        end
                    else
                        begin
                            HEX_5 = 7'b1111111;
                            HEX_4 = 7'b1111111;
                            HEX_3 = 7'b1000010;
                            HEX_2 = 7'b0000001;
                            HEX_1 = 7'b0001001;
                            HEX_0 = 7'b0110000;
                        end
                end
            else
                begin
                    HEX_5 = 7'b1111111;
                    HEX_4 = 7'b1111111;
                    HEX_3 = 7'b1111111;
                    HEX_2 = 7'b1111111;
                    HEX_1 = 7'b1111111;
                    HEX_0 = 7'b1111111;
                end
        end
endmodule