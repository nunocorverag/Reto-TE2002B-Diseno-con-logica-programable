module coord_display(
    input [9:0] x,          // Coordenada X del PWM (0-1023)
    input [9:0] y,          // Coordenada Y del PWM (0-1023)
    input [9:0] z,          // Coordenada Z del PWM (0-1023)
    input [9:0] counterX,   // Posición X actual del escaneo VGA
    input [9:0] counterY,   // Posición Y actual del escaneo VGA
    output reg pixel_on     // Señal que indica si el píxel debe estar encendido
);
    
    // Posiciones para la visualización de texto
    localparam TEXT_X = 100;        // Posición X inicial del texto
    localparam TEXT_Y_X = 100;      // Posición Y para la coordenada X
    localparam TEXT_Y_Y = 150;      // Posición Y para la coordenada Y
    localparam TEXT_Y_Z = 200;      // Posición Y para la coordenada Z
    localparam CHAR_WIDTH = 8;      // Ancho de cada caracter
    localparam CHAR_HEIGHT = 12;    // Alto de cada caracter
    
    // Variables para determinar qué dígito estamos dibujando
    reg [3:0] current_digit;
    reg drawing_text;
    reg [7:0] digit_pattern;
    reg [7:0] letter_pattern;
    reg [2:0] row_index;
    reg [2:0] col_index;
    
    // Función para obtener el patrón de los dígitos (simplificado para mostrar en pantalla)
    function [7:0] get_digit_pattern;
        input [3:0] digit;
        input [2:0] row;  // Fila dentro del dígito (0-7)
        begin
            case(digit)
                4'd0: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00111100;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b01100110;
                        3'd3: get_digit_pattern = 8'b01100110;
                        3'd4: get_digit_pattern = 8'b01100110;
                        3'd5: get_digit_pattern = 8'b01100110;
                        3'd6: get_digit_pattern = 8'b01100110;
                        3'd7: get_digit_pattern = 8'b00111100;
                    endcase
                end
                4'd1: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00011000;
                        3'd1: get_digit_pattern = 8'b00111000;
                        3'd2: get_digit_pattern = 8'b01111000;
                        3'd3: get_digit_pattern = 8'b00011000;
                        3'd4: get_digit_pattern = 8'b00011000;
                        3'd5: get_digit_pattern = 8'b00011000;
                        3'd6: get_digit_pattern = 8'b00011000;
                        3'd7: get_digit_pattern = 8'b01111110;
                    endcase
                end
                4'd2: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00111100;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b00000110;
                        3'd3: get_digit_pattern = 8'b00001100;
                        3'd4: get_digit_pattern = 8'b00011000;
                        3'd5: get_digit_pattern = 8'b00110000;
                        3'd6: get_digit_pattern = 8'b01100000;
                        3'd7: get_digit_pattern = 8'b01111110;
                    endcase
                end
                4'd3: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00111100;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b00000110;
                        3'd3: get_digit_pattern = 8'b00111100;
                        3'd4: get_digit_pattern = 8'b00000110;
                        3'd5: get_digit_pattern = 8'b00000110;
                        3'd6: get_digit_pattern = 8'b01100110;
                        3'd7: get_digit_pattern = 8'b00111100;
                    endcase
                end
                4'd4: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00001100;
                        3'd1: get_digit_pattern = 8'b00011100;
                        3'd2: get_digit_pattern = 8'b00101100;
                        3'd3: get_digit_pattern = 8'b01001100;
                        3'd4: get_digit_pattern = 8'b01111110;
                        3'd5: get_digit_pattern = 8'b00001100;
                        3'd6: get_digit_pattern = 8'b00001100;
                        3'd7: get_digit_pattern = 8'b00001100;
                    endcase
                end
                4'd5: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b01111110;
                        3'd1: get_digit_pattern = 8'b01100000;
                        3'd2: get_digit_pattern = 8'b01100000;
                        3'd3: get_digit_pattern = 8'b01111100;
                        3'd4: get_digit_pattern = 8'b00000110;
                        3'd5: get_digit_pattern = 8'b00000110;
                        3'd6: get_digit_pattern = 8'b01100110;
                        3'd7: get_digit_pattern = 8'b00111100;
                    endcase
                end
                4'd6: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00111100;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b01100000;
                        3'd3: get_digit_pattern = 8'b01111100;
                        3'd4: get_digit_pattern = 8'b01100110;
                        3'd5: get_digit_pattern = 8'b01100110;
                        3'd6: get_digit_pattern = 8'b01100110;
                        3'd7: get_digit_pattern = 8'b00111100;
                    endcase
                end
                4'd7: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b01111110;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b00000110;
                        3'd3: get_digit_pattern = 8'b00001100;
                        3'd4: get_digit_pattern = 8'b00011000;
                        3'd5: get_digit_pattern = 8'b00011000;
                        3'd6: get_digit_pattern = 8'b00011000;
                        3'd7: get_digit_pattern = 8'b00011000;
                    endcase
                end
                4'd8: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00111100;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b01100110;
                        3'd3: get_digit_pattern = 8'b00111100;
                        3'd4: get_digit_pattern = 8'b01100110;
                        3'd5: get_digit_pattern = 8'b01100110;
                        3'd6: get_digit_pattern = 8'b01100110;
                        3'd7: get_digit_pattern = 8'b00111100;
                    endcase
                end
                4'd9: begin
                    case(row)
                        3'd0: get_digit_pattern = 8'b00111100;
                        3'd1: get_digit_pattern = 8'b01100110;
                        3'd2: get_digit_pattern = 8'b01100110;
                        3'd3: get_digit_pattern = 8'b01100110;
                        3'd4: get_digit_pattern = 8'b00111110;
                        3'd5: get_digit_pattern = 8'b00000110;
                        3'd6: get_digit_pattern = 8'b01100110;
                        3'd7: get_digit_pattern = 8'b00111100;
                    endcase
                end
                default: get_digit_pattern = 8'b00000000;
            endcase
        end
    endfunction
    
    // Función para mostrar letras
    function [7:0] get_letter_pattern;
        input [7:0] letter;
        input [2:0] row;
        begin
            case(letter)
                "X": begin
                    case(row)
                        3'd0: get_letter_pattern = 8'b01100110;
                        3'd1: get_letter_pattern = 8'b01100110;
                        3'd2: get_letter_pattern = 8'b00111100;
                        3'd3: get_letter_pattern = 8'b00111100;
                        3'd4: get_letter_pattern = 8'b00111100;
                        3'd5: get_letter_pattern = 8'b01100110;
                        3'd6: get_letter_pattern = 8'b01100110;
                        3'd7: get_letter_pattern = 8'b01100110;
                    endcase
                end
                "Y": begin
                    case(row)
                        3'd0: get_letter_pattern = 8'b01100110;
                        3'd1: get_letter_pattern = 8'b01100110;
                        3'd2: get_letter_pattern = 8'b01100110;
                        3'd3: get_letter_pattern = 8'b00111100;
                        3'd4: get_letter_pattern = 8'b00011000;
                        3'd5: get_letter_pattern = 8'b00011000;
                        3'd6: get_letter_pattern = 8'b00011000;
                        3'd7: get_letter_pattern = 8'b00011000;
                    endcase
                end
                "Z": begin
                    case(row)
                        3'd0: get_letter_pattern = 8'b01111110;
                        3'd1: get_letter_pattern = 8'b00000110;
                        3'd2: get_letter_pattern = 8'b00001100;
                        3'd3: get_letter_pattern = 8'b00011000;
                        3'd4: get_letter_pattern = 8'b00110000;
                        3'd5: get_letter_pattern = 8'b01100000;
                        3'd6: get_letter_pattern = 8'b01111110;
                        3'd7: get_letter_pattern = 8'b00000000;
                    endcase
                end
                ":": begin
                    case(row)
                        3'd0: get_letter_pattern = 8'b00000000;
                        3'd1: get_letter_pattern = 8'b00011000;
                        3'd2: get_letter_pattern = 8'b00011000;
                        3'd3: get_letter_pattern = 8'b00000000;
                        3'd4: get_letter_pattern = 8'b00000000;
                        3'd5: get_letter_pattern = 8'b00011000;
                        3'd6: get_letter_pattern = 8'b00011000;
                        3'd7: get_letter_pattern = 8'b00000000;
                    endcase
                end
                default: get_letter_pattern = 8'b00000000;
            endcase
        end
    endfunction
    
    // Lógica para dibujar las coordenadas
    always @* begin
        pixel_on = 1'b0;  // Por defecto, el píxel está apagado
        row_index = 0;
        col_index = 0;
        digit_pattern = 0;
        letter_pattern = 0;
        
        // Dibujar coordenada X
        if (counterY >= TEXT_Y_X && counterY < TEXT_Y_X + CHAR_HEIGHT) begin
            row_index = counterY - TEXT_Y_X;
            
            // Letra X:
            if (counterX >= TEXT_X && counterX < TEXT_X + CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X);
                letter_pattern = get_letter_pattern("X", row_index);
                pixel_on = letter_pattern[col_index];
            end
            // Dos puntos
            else if (counterX >= TEXT_X + CHAR_WIDTH && counterX < TEXT_X + 2*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - CHAR_WIDTH);
                letter_pattern = get_letter_pattern(":", row_index);
                pixel_on = letter_pattern[col_index];
            end
            // Dígitos de la coordenada X
            else if (counterX >= TEXT_X + 3*CHAR_WIDTH && counterX < TEXT_X + 4*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 3*CHAR_WIDTH);
                digit_pattern = get_digit_pattern(x / 100, row_index);
                pixel_on = digit_pattern[col_index];
            end
            else if (counterX >= TEXT_X + 4*CHAR_WIDTH && counterX < TEXT_X + 5*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 4*CHAR_WIDTH);
                digit_pattern = get_digit_pattern((x / 10) % 10, row_index);
                pixel_on = digit_pattern[col_index];
            end
            else if (counterX >= TEXT_X + 5*CHAR_WIDTH && counterX < TEXT_X + 6*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 5*CHAR_WIDTH);
                digit_pattern = get_digit_pattern(x % 10, row_index);
                pixel_on = digit_pattern[col_index];
            end
        end
        
        // Dibujar coordenada Y
        else if (counterY >= TEXT_Y_Y && counterY < TEXT_Y_Y + CHAR_HEIGHT) begin
            row_index = counterY - TEXT_Y_Y;
            
            // Letra Y:
            if (counterX >= TEXT_X && counterX < TEXT_X + CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X);
                letter_pattern = get_letter_pattern("Y", row_index);
                pixel_on = letter_pattern[col_index];
            end
            // Dos puntos
            else if (counterX >= TEXT_X + CHAR_WIDTH && counterX < TEXT_X + 2*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - CHAR_WIDTH);
                letter_pattern = get_letter_pattern(":", row_index);
                pixel_on = letter_pattern[col_index];
            end
            // Dígitos de la coordenada Y
            else if (counterX >= TEXT_X + 3*CHAR_WIDTH && counterX < TEXT_X + 4*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 3*CHAR_WIDTH);
                digit_pattern = get_digit_pattern(y / 100, row_index);
                pixel_on = digit_pattern[col_index];
            end
            else if (counterX >= TEXT_X + 4*CHAR_WIDTH && counterX < TEXT_X + 5*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 4*CHAR_WIDTH);
                digit_pattern = get_digit_pattern((y / 10) % 10, row_index);
                pixel_on = digit_pattern[col_index];
            end
            else if (counterX >= TEXT_X + 5*CHAR_WIDTH && counterX < TEXT_X + 6*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 5*CHAR_WIDTH);
                digit_pattern = get_digit_pattern(y % 10, row_index);
                pixel_on = digit_pattern[col_index];
            end
        end
        
        // Dibujar coordenada Z
        else if (counterY >= TEXT_Y_Z && counterY < TEXT_Y_Z + CHAR_HEIGHT) begin
            row_index = counterY - TEXT_Y_Z;
            
            // Letra Z:
            if (counterX >= TEXT_X && counterX < TEXT_X + CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X);
                letter_pattern = get_letter_pattern("Z", row_index);
                pixel_on = letter_pattern[col_index];
            end
            // Dos puntos
            else if (counterX >= TEXT_X + CHAR_WIDTH && counterX < TEXT_X + 2*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - CHAR_WIDTH);
                letter_pattern = get_letter_pattern(":", row_index);
                pixel_on = letter_pattern[col_index];
            end
            // Dígitos de la coordenada Z
            else if (counterX >= TEXT_X + 3*CHAR_WIDTH && counterX < TEXT_X + 4*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 3*CHAR_WIDTH);
                digit_pattern = get_digit_pattern(z / 100, row_index);
                pixel_on = digit_pattern[col_index];
            end
            else if (counterX >= TEXT_X + 4*CHAR_WIDTH && counterX < TEXT_X + 5*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 4*CHAR_WIDTH);
                digit_pattern = get_digit_pattern((z / 10) % 10, row_index);
                pixel_on = digit_pattern[col_index];
            end
            else if (counterX >= TEXT_X + 5*CHAR_WIDTH && counterX < TEXT_X + 6*CHAR_WIDTH) begin
                col_index = 7 - (counterX - TEXT_X - 5*CHAR_WIDTH);
                digit_pattern = get_digit_pattern(z % 10, row_index);
                pixel_on = digit_pattern[col_index];
            end
        end
    end
endmodule