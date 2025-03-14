module vga(
    input MAX10_CLK1_50,    // Reloj de 50MHz de la placa
    input rst,              // Señal de reset
    input signed [10:0] x_coord,    // Coordenada X del PWM (-270 a 270)
    input signed [10:0] y_coord,    // Coordenada Y del PWM (-270 a 270)
    input signed [10:0] z_coord,    // Coordenada Z del PWM (-270 a 270)
    output hsync_out,
    output vsync_out,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B
);
    wire inDisplayArea;
    wire [9:0] counterX;
    wire [9:0] counterY;
    
    // Divisor de reloj para generar 25MHz
    reg clk_25 = 0;
    always @(posedge MAX10_CLK1_50)
        clk_25 <= ~clk_25;
    
    // Instanciar generador de sincronización
    hvsync_generator hvsync(
        .clk(clk_25),
        .vga_h_sync(hsync_out),
        .vga_v_sync(vsync_out),
        .counterX(counterX),
        .counterY(counterY),
        .inDisplayArea(inDisplayArea)
    );
    
    // Coordenadas con reset
    reg signed [10:0] x_display, y_display, z_display;
    
    // Lógica de reset para las coordenadas
    always @(posedge MAX10_CLK1_50 or posedge rst) begin
        if (rst) begin
            // Resetear coordenadas a 90 (posición central mecánica del servo)
            x_display <= 11'd90;
            y_display <= 11'd90;
            z_display <= 11'd90;
        end else begin
            // Actualizar coordenadas con los valores de entrada
            x_display <= x_coord;
            y_display <= y_coord;
            z_display <= z_coord;
        end
    end

    // ============================================================================
    // Lógica de signo y valor absoluto mejorada
    // ============================================================================
    wire is_negative_x = x_display[10];
    wire is_negative_y = y_display[10];
    wire is_negative_z = z_display[10];

    wire [10:0] abs_x = is_negative_x ? -x_display : x_display;
    wire [10:0] abs_y = is_negative_y ? -y_display : y_display;
    wire [10:0] abs_z = is_negative_z ? -z_display : z_display;
    
    // Extraer dígitos para X, Y y Z (0-270)
    wire [3:0] x_ones = abs_x % 10;
    wire [3:0] x_tens = (abs_x % 100) / 10;
    wire [3:0] x_hundreds = (abs_x % 1000) / 100;
    
    wire [3:0] y_ones = abs_y % 10;
    wire [3:0] y_tens = (abs_y % 100) / 10;
    wire [3:0] y_hundreds = (abs_y % 1000) / 100;
    
    wire [3:0] z_ones = abs_z % 10;
    wire [3:0] z_tens = (abs_z % 100) / 10;
    wire [3:0] z_hundreds = (abs_z % 1000) / 100;
    
    // Memoria ROM para dígitos (versión más grande 8x12)
    reg [7:0] digitMap [0:11][0:9]; // [fila][dígito]
    
    // Inicializar ROM con patrones de dígitos
    initial begin
        // Dígito 0
        digitMap[0][0] = 8'b00111100;
        digitMap[1][0] = 8'b01111110;
        digitMap[2][0] = 8'b11000011;
        digitMap[3][0] = 8'b11000011;
        digitMap[4][0] = 8'b11000011;
        digitMap[5][0] = 8'b11000011;
        digitMap[6][0] = 8'b11000011;
        digitMap[7][0] = 8'b11000011;
        digitMap[8][0] = 8'b11000011;
        digitMap[9][0] = 8'b11000011;
        digitMap[10][0] = 8'b01111110;
        digitMap[11][0] = 8'b00111100;
        
        // Dígito 1
        digitMap[0][1] = 8'b00011000;
        digitMap[1][1] = 8'b00111000;
        digitMap[2][1] = 8'b01111000;
        digitMap[3][1] = 8'b11011000;
        digitMap[4][1] = 8'b10011000;
        digitMap[5][1] = 8'b00011000;
        digitMap[6][1] = 8'b00011000;
        digitMap[7][1] = 8'b00011000;
        digitMap[8][1] = 8'b00011000;
        digitMap[9][1] = 8'b00011000;
        digitMap[10][1] = 8'b01111110;
        digitMap[11][1] = 8'b01111110;
        
        // Dígito 2
        digitMap[0][2] = 8'b00111100;
        digitMap[1][2] = 8'b01111110;
        digitMap[2][2] = 8'b11000011;
        digitMap[3][2] = 8'b10000011;
        digitMap[4][2] = 8'b00000110;
        digitMap[5][2] = 8'b00001100;
        digitMap[6][2] = 8'b00011000;
        digitMap[7][2] = 8'b00110000;
        digitMap[8][2] = 8'b01100000;
        digitMap[9][2] = 8'b11000000;
        digitMap[10][2] = 8'b11111111;
        digitMap[11][2] = 8'b11111111;
        
        // Dígito 3
        digitMap[0][3] = 8'b00111100;
        digitMap[1][3] = 8'b01111110;
        digitMap[2][3] = 8'b11000011;
        digitMap[3][3] = 8'b00000011;
        digitMap[4][3] = 8'b00000011;
        digitMap[5][3] = 8'b00111110;
        digitMap[6][3] = 8'b00111110;
        digitMap[7][3] = 8'b00000011;
        digitMap[8][3] = 8'b00000011;
        digitMap[9][3] = 8'b11000011;
        digitMap[10][3] = 8'b01111110;
        digitMap[11][3] = 8'b00111100;
        
        // Dígito 4
        digitMap[0][4] = 8'b00000110;
        digitMap[1][4] = 8'b00001110;
        digitMap[2][4] = 8'b00011110;
        digitMap[3][4] = 8'b00110110;
        digitMap[4][4] = 8'b01100110;
        digitMap[5][4] = 8'b11000110;
        digitMap[6][4] = 8'b11111111;
        digitMap[7][4] = 8'b11111111;
        digitMap[8][4] = 8'b00000110;
        digitMap[9][4] = 8'b00000110;
        digitMap[10][4] = 8'b00000110;
        digitMap[11][4] = 8'b00000110;
        
        // Dígito 5
        digitMap[0][5] = 8'b11111111;
        digitMap[1][5] = 8'b11111111;
        digitMap[2][5] = 8'b11000000;
        digitMap[3][5] = 8'b11000000;
        digitMap[4][5] = 8'b11000000;
        digitMap[5][5] = 8'b11111100;
        digitMap[6][5] = 8'b11111110;
        digitMap[7][5] = 8'b00000011;
        digitMap[8][5] = 8'b00000011;
        digitMap[9][5] = 8'b11000011;
        digitMap[10][5] = 8'b01111110;
        digitMap[11][5] = 8'b00111100;
        
        // Dígito 6
        digitMap[0][6] = 8'b00111100;
        digitMap[1][6] = 8'b01111110;
        digitMap[2][6] = 8'b11000011;
        digitMap[3][6] = 8'b11000000;
        digitMap[4][6] = 8'b11000000;
        digitMap[5][6] = 8'b11111100;
        digitMap[6][6] = 8'b11111110;
        digitMap[7][6] = 8'b11000011;
        digitMap[8][6] = 8'b11000011;
        digitMap[9][6] = 8'b11000011;
        digitMap[10][6] = 8'b01111110;
        digitMap[11][6] = 8'b00111100;
        
        // Dígito 7
        digitMap[0][7] = 8'b11111111;
        digitMap[1][7] = 8'b11111111;
        digitMap[2][7] = 8'b00000011;
        digitMap[3][7] = 8'b00000110;
        digitMap[4][7] = 8'b00001100;
        digitMap[5][7] = 8'b00011000;
        digitMap[6][7] = 8'b00110000;
        digitMap[7][7] = 8'b01100000;
        digitMap[8][7] = 8'b01100000;
        digitMap[9][7] = 8'b01100000;
        digitMap[10][7] = 8'b01100000;
        digitMap[11][7] = 8'b01100000;
        
        // Dígito 8
        digitMap[0][8] = 8'b00111100;
        digitMap[1][8] = 8'b01111110;
        digitMap[2][8] = 8'b11000011;
        digitMap[3][8] = 8'b11000011;
        digitMap[4][8] = 8'b11000011;
        digitMap[5][8] = 8'b01111110;
        digitMap[6][8] = 8'b01111110;
        digitMap[7][8] = 8'b11000011;
        digitMap[8][8] = 8'b11000011;
        digitMap[9][8] = 8'b11000011;
        digitMap[10][8] = 8'b01111110;
        digitMap[11][8] = 8'b00111100;
        
        // Dígito 9
        digitMap[0][9] = 8'b00111100;
        digitMap[1][9] = 8'b01111110;
        digitMap[2][9] = 8'b11000011;
        digitMap[3][9] = 8'b11000011;
        digitMap[4][9] = 8'b11000011;
        digitMap[5][9] = 8'b01111111;
        digitMap[6][9] = 8'b00111111;
        digitMap[7][9] = 8'b00000011;
        digitMap[8][9] = 8'b00000011;
        digitMap[9][9] = 8'b11000011;
        digitMap[10][9] = 8'b01111110;
        digitMap[11][9] = 8'b00111100;
    end
    
    // ROM para letras X, Y, Z y signo negativo (versión más grande 8x12)
    reg [7:0] letterMap [0:11][0:3]; // [fila][letra] - el índice 3 es para el signo negativo
    
    // Inicializar ROM con patrones de letras
    initial begin
        // Letra X
        letterMap[0][0] = 8'b11000011;
        letterMap[1][0] = 8'b11000011;
        letterMap[2][0] = 8'b11000011;
        letterMap[3][0] = 8'b01100110;
        letterMap[4][0] = 8'b00111100;
        letterMap[5][0] = 8'b00111100;
        letterMap[6][0] = 8'b00111100;
        letterMap[7][0] = 8'b00111100;
        letterMap[8][0] = 8'b01100110;
        letterMap[9][0] = 8'b11000011;
        letterMap[10][0] = 8'b11000011;
        letterMap[11][0] = 8'b11000011;
        
        // Letra Y
        letterMap[0][1] = 8'b11000011;
        letterMap[1][1] = 8'b11000011;
        letterMap[2][1] = 8'b11000011;
        letterMap[3][1] = 8'b11000011;
        letterMap[4][1] = 8'b01100110;
        letterMap[5][1] = 8'b00111100;
        letterMap[6][1] = 8'b00011000;
        letterMap[7][1] = 8'b00011000;
        letterMap[8][1] = 8'b00011000;
        letterMap[9][1] = 8'b00011000;
        letterMap[10][1] = 8'b00011000;
        letterMap[11][1] = 8'b00011000;
        
        // Letra Z
        letterMap[0][2] = 8'b11111111;
        letterMap[1][2] = 8'b11111111;
        letterMap[2][2] = 8'b00000011;
        letterMap[3][2] = 8'b00000110;
        letterMap[4][2] = 8'b00001100;
        letterMap[5][2] = 8'b00011000;
        letterMap[6][2] = 8'b00110000;
        letterMap[7][2] = 8'b01100000;
        letterMap[8][2] = 8'b11000000;
        letterMap[9][2] = 8'b11000000;
        letterMap[10][2] = 8'b11111111;
        letterMap[11][2] = 8'b11111111;
        
        // Signo negativo (-) - Diseño más destacado
        letterMap[0][3] = 8'b00000000;
        letterMap[1][3] = 8'b00000000;
        letterMap[2][3] = 8'b00000000;
        letterMap[3][3] = 8'b00000000;
        letterMap[4][3] = 8'b00000000;
        letterMap[5][3] = 8'b00000000;
        letterMap[6][3] = 8'b11111111;
        letterMap[7][3] = 8'b11111111;
        letterMap[8][3] = 8'b11111111;
        letterMap[9][3] = 8'b00000000;
        letterMap[10][3] = 8'b00000000;
        letterMap[11][3] = 8'b00000000;
    end
    
   // Parámetros para posicionamiento de texto
    parameter CHAR_WIDTH = 10;    // Ancho de caracter + espacio
    parameter CHAR_HEIGHT = 16;   // Alto de caracter + espacio
    parameter TEXT_X = 100;       // Posición X inicial
    parameter TEXT_Y_X = 100;     // Posición Y para X
    parameter TEXT_Y_Y = 150;     // Posición Y para Y
    parameter TEXT_Y_Z = 200;     // Posición Y para Z
    
    // Lógica para determinar si el pixel actual es parte de un caracter
    reg text_pixel;

    always @* begin
        text_pixel = 0;
        
        // Coordenada X
        if (counterY >= TEXT_Y_X && counterY < TEXT_Y_X + CHAR_HEIGHT - 4) begin
            // Letra X
            if (counterX >= TEXT_X && counterX < TEXT_X + CHAR_WIDTH - 2) begin
                if (counterX - TEXT_X < 8 && counterY - TEXT_Y_X < 12) begin
                    text_pixel = letterMap[counterY - TEXT_Y_X][0][7 - (counterX - TEXT_X)];
                end
            end
            // Signo negativo para X (siempre visible si es negativo)
            else if (is_negative_x && counterX >= TEXT_X + CHAR_WIDTH && counterX < TEXT_X + 2*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + CHAR_WIDTH) < 8 && counterY - TEXT_Y_X < 12) begin
                    text_pixel = letterMap[counterY - TEXT_Y_X][3][7 - (counterX - (TEXT_X + CHAR_WIDTH))];
                end
            end
            // Dígitos de X
            else if (counterX >= TEXT_X + (is_negative_x ? 2 : 1)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_x ? 3 : 2)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_x ? 2 : 1)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_X < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_X][x_hundreds][7 - (counterX - (TEXT_X + (is_negative_x ? 2 : 1)*CHAR_WIDTH))];
                end
            end
            else if (counterX >= TEXT_X + (is_negative_x ? 3 : 2)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_x ? 4 : 3)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_x ? 3 : 2)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_X < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_X][x_tens][7 - (counterX - (TEXT_X + (is_negative_x ? 3 : 2)*CHAR_WIDTH))];
                end
            end
            else if (counterX >= TEXT_X + (is_negative_x ? 4 : 3)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_x ? 5 : 4)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_x ? 4 : 3)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_X < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_X][x_ones][7 - (counterX - (TEXT_X + (is_negative_x ? 4 : 3)*CHAR_WIDTH))];
                end
            end
        end
        
        // Coordenada Y (similar a X, con ajustes para Y)
        if (counterY >= TEXT_Y_Y && counterY < TEXT_Y_Y + CHAR_HEIGHT - 4) begin
            // Letra Y
            if (counterX >= TEXT_X && counterX < TEXT_X + CHAR_WIDTH - 2) begin
                if (counterX - TEXT_X < 8 && counterY - TEXT_Y_Y < 12) begin
                    text_pixel = letterMap[counterY - TEXT_Y_Y][1][7 - (counterX - TEXT_X)];
                end
            end
            // Signo negativo para Y
            else if (is_negative_y && counterX >= TEXT_X + CHAR_WIDTH && counterX < TEXT_X + 2*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + CHAR_WIDTH) < 8 && counterY - TEXT_Y_Y < 12) begin
                    text_pixel = letterMap[counterY - TEXT_Y_Y][3][7 - (counterX - (TEXT_X + CHAR_WIDTH))];
                end
            end
            // Dígitos de Y
            else if (counterX >= TEXT_X + (is_negative_y ? 2 : 1)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_y ? 3 : 2)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_y ? 2 : 1)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_Y < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Y][y_hundreds][7 - (counterX - (TEXT_X + (is_negative_y ? 2 : 1)*CHAR_WIDTH))];
                end
            end
            else if (counterX >= TEXT_X + (is_negative_y ? 3 : 2)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_y ? 4 : 3)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_y ? 3 : 2)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_Y < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Y][y_tens][7 - (counterX - (TEXT_X + (is_negative_y ? 3 : 2)*CHAR_WIDTH))];
                end
            end
            else if (counterX >= TEXT_X + (is_negative_y ? 4 : 3)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_y ? 5 : 4)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_y ? 4 : 3)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_Y < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Y][y_ones][7 - (counterX - (TEXT_X + (is_negative_y ? 4 : 3)*CHAR_WIDTH))];
                end
            end
        end
        
        // Coordenada Z (similar a X e Y, con ajustes para Z)
        if (counterY >= TEXT_Y_Z && counterY < TEXT_Y_Z + CHAR_HEIGHT - 4) begin
            // Letra Z
            if (counterX >= TEXT_X && counterX < TEXT_X + CHAR_WIDTH - 2) begin
                if (counterX - TEXT_X < 8 && counterY - TEXT_Y_Z < 12) begin
                    text_pixel = letterMap[counterY - TEXT_Y_Z][2][7 - (counterX - TEXT_X)];
                end
            end
            // Signo negativo para Z
            else if (is_negative_z && counterX >= TEXT_X + CHAR_WIDTH && counterX < TEXT_X + 2*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + CHAR_WIDTH) < 8 && counterY - TEXT_Y_Z < 12) begin
                    text_pixel = letterMap[counterY - TEXT_Y_Z][3][7 - (counterX - (TEXT_X + CHAR_WIDTH))];
                end
            end
            // Dígitos de Z
            else if (counterX >= TEXT_X + (is_negative_z ? 2 : 1)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_z ? 3 : 2)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_z ? 2 : 1)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_Z < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Z][z_hundreds][7 - (counterX - (TEXT_X + (is_negative_z ? 2 : 1)*CHAR_WIDTH))];
                end
            end
            else if (counterX >= TEXT_X + (is_negative_z ? 3 : 2)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_z ? 4 : 3)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_z ? 3 : 2)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_Z < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Z][z_tens][7 - (counterX - (TEXT_X + (is_negative_z ? 3 : 2)*CHAR_WIDTH))];
                end
            end
            else if (counterX >= TEXT_X + (is_negative_z ? 4 : 3)*CHAR_WIDTH && 
                     counterX < TEXT_X + (is_negative_z ? 5 : 4)*CHAR_WIDTH - 2) begin
                if (counterX - (TEXT_X + (is_negative_z ? 4 : 3)*CHAR_WIDTH) < 8 && 
                    counterY - TEXT_Y_Z < 12) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Z][z_ones][7 - (counterX - (TEXT_X + (is_negative_z ? 4 : 3)*CHAR_WIDTH))];
                end
            end
        end
    end
    
    // Asignar colores VGA (blanco para texto, negro para fondo)
    assign VGA_R = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_G = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_B = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    
endmodule