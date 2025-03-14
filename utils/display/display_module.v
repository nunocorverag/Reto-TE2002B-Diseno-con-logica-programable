module display_module #(
    parameter SEGMENTOS = 7, 
    BIT_SIZE = 20
)(
    input signed [BIT_SIZE-1:0] number,
    input is_signed,  // 1 = habilitar signo
    output [0:SEGMENTOS-1] HEX_0,  // Unidades
    output [0:SEGMENTOS-1] HEX_1,  // Decenas
    output [0:SEGMENTOS-1] HEX_2,  // Centenas
    output [0:SEGMENTOS-1] HEX_3,  // Millares
    output [0:SEGMENTOS-1] HEX_4,  // Decenas de millar
    output [0:SEGMENTOS-1] HEX_5   // Centenas de millar o signo (-)
);

// ============================================================================
// Lógica de signo y valor absoluto
// ============================================================================
wire is_negative = is_signed & (number[BIT_SIZE-1] == 1'b1);
wire [BIT_SIZE-1:0] abs_number = is_negative ? -number : number;

// ============================================================================
// Extracción de dígitos (absolutos)
// ============================================================================
wire [3:0] digit [5:0];
assign digit[0] = abs_number % 10;          // Unidades
assign digit[1] = (abs_number / 10) % 10;   // Decenas
assign digit[2] = (abs_number / 100) % 10;  // Centenas
assign digit[3] = (abs_number / 1000) % 10; // Millares
assign digit[4] = (abs_number / 10000) % 10;// Decenas de millar
assign digit[5] = (abs_number / 100000) % 10; // Centenas de millar

// ============================================================================
// Determinar el último dígito significativo (para posicionar el signo)
// ============================================================================
wire [2:0] last_significant_digit;
assign last_significant_digit = (digit[5] != 0) ? 3'd5 :
                               (digit[4] != 0) ? 3'd4 :
                               (digit[3] != 0) ? 3'd3 :
                               (digit[2] != 0) ? 3'd2 :
                               (digit[1] != 0) ? 3'd1 : 3'd0;

// ============================================================================
// Lógica para habilitación de displays
// ============================================================================
wire enable_0 = 1'b1; // Siempre activo
wire enable_1 = (digit[1] != 0) || (digit[2] != 0) || (digit[3] != 0) || (digit[4] != 0) || (digit[5] != 0);
wire enable_2 = (digit[2] != 0) || (digit[3] != 0) || (digit[4] != 0) || (digit[5] != 0);
wire enable_3 = (digit[3] != 0) || (digit[4] != 0) || (digit[5] != 0);
wire enable_4 = (digit[4] != 0) || (digit[5] != 0);
wire enable_5 = (digit[5] != 0);

// ============================================================================
// Lógica para mostrar el signo negativo
// ============================================================================
// Posición del signo: una posición a la izquierda del dígito más significativo
wire [2:0] sign_position = last_significant_digit + 3'd1;

// Verificar si el signo debe mostrarse en cada display
wire show_sign_0 = is_negative && (sign_position == 3'd0);
wire show_sign_1 = is_negative && (sign_position == 3'd1);
wire show_sign_2 = is_negative && (sign_position == 3'd2);
wire show_sign_3 = is_negative && (sign_position == 3'd3);
wire show_sign_4 = is_negative && (sign_position == 3'd4);
wire show_sign_5 = is_negative && (sign_position == 3'd5);

// ============================================================================
// Decoders con supresión de ceros a la izquierda y signo dinámico
// ============================================================================
decoder_7_seg DISPLAY_0 (
    .value(show_sign_0 ? 5'h10 : digit[0]),  // 5'h10 es el código para "-"
    .segments(HEX_0), 
    .enable(enable_0)
);

decoder_7_seg DISPLAY_1 (
    .value(show_sign_1 ? 5'h10 : digit[1]), 
    .segments(HEX_1), 
    .enable(enable_1 | show_sign_1)
);

decoder_7_seg DISPLAY_2 (
    .value(show_sign_2 ? 5'h10 : digit[2]), 
    .segments(HEX_2), 
    .enable(enable_2 | show_sign_2)
);

decoder_7_seg DISPLAY_3 (
    .value(show_sign_3 ? 5'h10 : digit[3]), 
    .segments(HEX_3), 
    .enable(enable_3 | show_sign_3)
);

decoder_7_seg DISPLAY_4 (
    .value(show_sign_4 ? 5'h10 : digit[4]), 
    .segments(HEX_4), 
    .enable(enable_4 | show_sign_4)
);

decoder_7_seg DISPLAY_5 (
    .value(show_sign_5 ? 5'h10 : digit[5]), 
    .segments(HEX_5),
    .enable(enable_5 | show_sign_5)
);

endmodule