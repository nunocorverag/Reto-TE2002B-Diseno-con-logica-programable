

module display_module #(parameter WIRE_SIZE = 4, SEGMENTOS = 7, BIT_SIZE = 20)(
    input [BIT_SIZE - 1:0] number,
    output [0: SEGMENTOS - 1] D_decenas, D_unidades, D_centenas, D_millares, D_decenas_millares, D_centenas_millares
);

// Separacion del numero binario en digitos individuales
wire [WIRE_SIZE - 1:0] unidades_wire;
wire [WIRE_SIZE - 1:0] decenas_wire;
wire [WIRE_SIZE - 1:0] centenas_wire;
wire [WIRE_SIZE - 1:0] millares_wire;
wire [WIRE_SIZE - 1:0] decenas_millares_wire;
wire [WIRE_SIZE - 1:0] centenas_millares_wire;

assign unidades_wire = number % 10;
assign decenas_wire = number % 100 / 10;
assign centenas_wire = number % 1000 / 100;
assign millares_wire = number % 10000 / 1000;
assign decenas_millares_wire = number % 100000 / 10000;
assign centenas_millares_wire = number / 100000;

// Instancias del decoder de 7 segmentos para cada display
decoder_7_seg DISPLAY_U (
    .decoder_in(unidades_wire),
    .decoder_out(D_unidades)
);

decoder_7_seg DISPLAY_D (
    .decoder_in(decenas_wire),
    .decoder_out(D_decenas)
);

decoder_7_seg DISPLAY_C (
    .decoder_in(centenas_wire),
    .decoder_out(D_centenas)
);

decoder_7_seg DISPLAY_M (
    .decoder_in(millares_wire),
    .decoder_out(D_millares)
);

decoder_7_seg DISPLAY_DM (
    .decoder_in(decenas_millares_wire),
    .decoder_out(D_decenas_millares)
);

decoder_7_seg DISPLAY_CM (
    .decoder_in(centenas_millares_wire),
    .decoder_out(D_centenas_millares)
);


endmodule