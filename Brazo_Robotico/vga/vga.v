module vga(
    input MAX10_CLK1_50,    // Reloj de 50MHz de la placa
    input [9:0] x_coord,    // Coordenada X del PWM (0-1023)
    input [9:0] y_coord,    // Coordenada Y del PWM (0-1023)
    input [9:0] z_coord,    // Coordenada Z del PWM (0-1023)
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
    
    // Extraer dígitos para X, Y y Z (0-999)
    wire [3:0] x_hundreds = (x_coord % 1000) / 100;
    wire [3:0] x_tens = (x_coord % 100) / 10;
    wire [3:0] x_ones = x_coord % 10;
    
    wire [3:0] y_hundreds = (y_coord % 1000) / 100;
    wire [3:0] y_tens = (y_coord % 100) / 10;
    wire [3:0] y_ones = y_coord % 10;
    
    wire [3:0] z_hundreds = (z_coord % 1000) / 100;
    wire [3:0] z_tens = (z_coord % 100) / 10;
    wire [3:0] z_ones = z_coord % 10;
    
    // Memoria ROM simple para dígitos (versión minimalista 3x5)
    reg [2:0] digitMap [0:4][0:9]; // [fila][dígito]
    
    // Inicializar ROM con patrones de dígitos
    initial begin
        // Dígito 0
        digitMap[0][0] = 3'b111;
        digitMap[1][0] = 3'b101;
        digitMap[2][0] = 3'b101;
        digitMap[3][0] = 3'b101;
        digitMap[4][0] = 3'b111;
        
        // Dígito 1
        digitMap[0][1] = 3'b010;
        digitMap[1][1] = 3'b110;
        digitMap[2][1] = 3'b010;
        digitMap[3][1] = 3'b010;
        digitMap[4][1] = 3'b111;
        
        // Dígito 2
        digitMap[0][2] = 3'b111;
        digitMap[1][2] = 3'b001;
        digitMap[2][2] = 3'b111;
        digitMap[3][2] = 3'b100;
        digitMap[4][2] = 3'b111;
        
        // Dígito 3
        digitMap[0][3] = 3'b111;
        digitMap[1][3] = 3'b001;
        digitMap[2][3] = 3'b111;
        digitMap[3][3] = 3'b001;
        digitMap[4][3] = 3'b111;
        
        // Dígito 4
        digitMap[0][4] = 3'b101;
        digitMap[1][4] = 3'b101;
        digitMap[2][4] = 3'b111;
        digitMap[3][4] = 3'b001;
        digitMap[4][4] = 3'b001;
        
        // Dígito 5
        digitMap[0][5] = 3'b111;
        digitMap[1][5] = 3'b100;
        digitMap[2][5] = 3'b111;
        digitMap[3][5] = 3'b001;
        digitMap[4][5] = 3'b111;
        
        // Dígito 6
        digitMap[0][6] = 3'b111;
        digitMap[1][6] = 3'b100;
        digitMap[2][6] = 3'b111;
        digitMap[3][6] = 3'b101;
        digitMap[4][6] = 3'b111;
        
        // Dígito 7
        digitMap[0][7] = 3'b111;
        digitMap[1][7] = 3'b001;
        digitMap[2][7] = 3'b010;
        digitMap[3][7] = 3'b010;
        digitMap[4][7] = 3'b010;
        
        // Dígito 8
        digitMap[0][8] = 3'b111;
        digitMap[1][8] = 3'b101;
        digitMap[2][8] = 3'b111;
        digitMap[3][8] = 3'b101;
        digitMap[4][8] = 3'b111;
        
        // Dígito 9
        digitMap[0][9] = 3'b111;
        digitMap[1][9] = 3'b101;
        digitMap[2][9] = 3'b111;
        digitMap[3][9] = 3'b001;
        digitMap[4][9] = 3'b111;
    end
    
    // Memoria ROM simple para letras X, Y, Z (versión minimalista 3x5)
    reg [2:0] letterMap [0:4][0:2]; // [fila][letra]
    
    // Inicializar ROM con patrones de letras
    initial begin
        // Letra X
        letterMap[0][0] = 3'b101;
        letterMap[1][0] = 3'b101;
        letterMap[2][0] = 3'b010;
        letterMap[3][0] = 3'b101;
        letterMap[4][0] = 3'b101;
        
        // Letra Y
        letterMap[0][1] = 3'b101;
        letterMap[1][1] = 3'b101;
        letterMap[2][1] = 3'b111;
        letterMap[3][1] = 3'b010;
        letterMap[4][1] = 3'b010;
        
        // Letra Z
        letterMap[0][2] = 3'b111;
        letterMap[1][2] = 3'b001;
        letterMap[2][2] = 3'b010;
        letterMap[3][2] = 3'b100;
        letterMap[4][2] = 3'b111;
    end
    
    // Parámetros para posicionamiento de texto
    parameter DIGIT_WIDTH = 4;  // Ancho de dígito + 1 espacio
    parameter DIGIT_HEIGHT = 6; // Alto de dígito + 1 espacio
    parameter TEXT_X = 100;     // Posición X inicial
    parameter TEXT_Y_X = 100;   // Posición Y para X
    parameter TEXT_Y_Y = 150;   // Posición Y para Y
    parameter TEXT_Y_Z = 200;   // Posición Y para Z
    
    // Lógica para determinar si el pixel actual es parte de un caracter
    reg text_pixel;
    
    always @* begin
        text_pixel = 0;
        
        // Coordenada X
        if (counterY >= TEXT_Y_X && counterY < TEXT_Y_X + DIGIT_HEIGHT - 1) begin
            // Letra X
            if (counterX >= TEXT_X && counterX < TEXT_X + DIGIT_WIDTH - 1) begin
                if (counterX - TEXT_X < 3 && counterY - TEXT_Y_X < 5) begin
                    text_pixel = letterMap[counterY - TEXT_Y_X][0][counterX - TEXT_X];
                end
            end
            // Espacio después de la letra
            else if (counterX >= TEXT_X + DIGIT_WIDTH - 1 && counterX < TEXT_X + 2*DIGIT_WIDTH - 1) begin
                // No dibujar nada (espacio)
            end
            // Dígitos de X
            else if (counterX >= TEXT_X + 2*DIGIT_WIDTH - 1 && counterX < TEXT_X + 3*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 2*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_X < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_X][x_hundreds][counterX - (TEXT_X + 2*DIGIT_WIDTH - 1)];
                end
            end
            else if (counterX >= TEXT_X + 3*DIGIT_WIDTH - 1 && counterX < TEXT_X + 4*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 3*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_X < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_X][x_tens][counterX - (TEXT_X + 3*DIGIT_WIDTH - 1)];
                end
            end
            else if (counterX >= TEXT_X + 4*DIGIT_WIDTH - 1 && counterX < TEXT_X + 5*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 4*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_X < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_X][x_ones][counterX - (TEXT_X + 4*DIGIT_WIDTH - 1)];
                end
            end
        end
        
        // Coordenada Y
        if (counterY >= TEXT_Y_Y && counterY < TEXT_Y_Y + DIGIT_HEIGHT - 1) begin
            // Letra Y
            if (counterX >= TEXT_X && counterX < TEXT_X + DIGIT_WIDTH - 1) begin
                if (counterX - TEXT_X < 3 && counterY - TEXT_Y_Y < 5) begin
                    text_pixel = letterMap[counterY - TEXT_Y_Y][1][counterX - TEXT_X];
                end
            end
            // Espacio después de la letra
            else if (counterX >= TEXT_X + DIGIT_WIDTH - 1 && counterX < TEXT_X + 2*DIGIT_WIDTH - 1) begin
                // No dibujar nada (espacio)
            end
            // Dígitos de Y
            else if (counterX >= TEXT_X + 2*DIGIT_WIDTH - 1 && counterX < TEXT_X + 3*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 2*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_Y < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Y][y_hundreds][counterX - (TEXT_X + 2*DIGIT_WIDTH - 1)];
                end
            end
            else if (counterX >= TEXT_X + 3*DIGIT_WIDTH - 1 && counterX < TEXT_X + 4*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 3*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_Y < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Y][y_tens][counterX - (TEXT_X + 3*DIGIT_WIDTH - 1)];
                end
            end
            else if (counterX >= TEXT_X + 4*DIGIT_WIDTH - 1 && counterX < TEXT_X + 5*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 4*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_Y < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Y][y_ones][counterX - (TEXT_X + 4*DIGIT_WIDTH - 1)];
                end
            end
        end
        
        // Coordenada Z
        if (counterY >= TEXT_Y_Z && counterY < TEXT_Y_Z + DIGIT_HEIGHT - 1) begin
            // Letra Z
            if (counterX >= TEXT_X && counterX < TEXT_X + DIGIT_WIDTH - 1) begin
                if (counterX - TEXT_X < 3 && counterY - TEXT_Y_Z < 5) begin
                    text_pixel = letterMap[counterY - TEXT_Y_Z][2][counterX - TEXT_X];
                end
            end
            // Espacio después de la letra
            else if (counterX >= TEXT_X + DIGIT_WIDTH - 1 && counterX < TEXT_X + 2*DIGIT_WIDTH - 1) begin
                // No dibujar nada (espacio)
            end
            // Dígitos de Z
            else if (counterX >= TEXT_X + 2*DIGIT_WIDTH - 1 && counterX < TEXT_X + 3*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 2*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_Z < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Z][z_hundreds][counterX - (TEXT_X + 2*DIGIT_WIDTH - 1)];
                end
            end
            else if (counterX >= TEXT_X + 3*DIGIT_WIDTH - 1 && counterX < TEXT_X + 4*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 3*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_Z < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Z][z_tens][counterX - (TEXT_X + 3*DIGIT_WIDTH - 1)];
                end
            end
            else if (counterX >= TEXT_X + 4*DIGIT_WIDTH - 1 && counterX < TEXT_X + 5*DIGIT_WIDTH - 1) begin
                if (counterX - (TEXT_X + 4*DIGIT_WIDTH - 1) < 3 && counterY - TEXT_Y_Z < 5) begin
                    text_pixel = digitMap[counterY - TEXT_Y_Z][z_ones][counterX - (TEXT_X + 4*DIGIT_WIDTH - 1)];
                end
            end
        end
    end
    
    // Asignar colores VGA (blanco para texto, azul oscuro para fondo)
    assign VGA_R = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_G = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_B = inDisplayArea ? (text_pixel ? 4'hF : 4'h2) : 4'h0;
    
endmodule