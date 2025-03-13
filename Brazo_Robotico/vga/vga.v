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
    
    // Función para calcular la distancia al cuadrado desde un punto a una línea
    function [19:0] dist_to_line_squared;
        input [9:0] x, y;         // Punto a evaluar
        input [9:0] x1, y1;       // Punto inicial de la línea
        input [9:0] x2, y2;       // Punto final de la línea
        reg [19:0] num, denom;    // Elementos de la fórmula
        reg [19:0] t;             // Parámetro de la línea (0-1)
        reg [9:0] px, py;         // Punto proyectado
        begin
            // Calcular numerador y denominador para t
            denom = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
            
            if (denom == 0) begin
                // Si los puntos son iguales, calcula la distancia al punto
                dist_to_line_squared = (x-x1)*(x-x1) + (y-y1)*(y-y1);
            end else begin
                // Calcular t (parámetro de la línea)
                num = (x-x1)*(x2-x1) + (y-y1)*(y2-y1);
                
                if (num <= 0) begin
                    // Antes del inicio de la línea
                    dist_to_line_squared = (x-x1)*(x-x1) + (y-y1)*(y-y1);
                end else if (num >= denom) begin
                    // Después del final de la línea
                    dist_to_line_squared = (x-x2)*(x-x2) + (y-y2)*(y-y2);
                end else begin
                    // Proyección cae en la línea
                    t = (num * 100) / denom; // Escalar para evitar división de punto flotante
                    px = x1 + ((x2-x1) * t) / 100;
                    py = y1 + ((y2-y1) * t) / 100;
                    dist_to_line_squared = (x-px)*(x-px) + (y-py)*(y-py);
                end
            end
        end
    endfunction
    
    // Función para dibujar la letra X redondeada y rellenita
    function is_letter_x;
        input [9:0] x_pos, y_pos; // Posición base de la letra
        input [9:0] x, y;         // Punto a evaluar
        reg [9:0] width, height;  // Dimensiones de la letra
        reg [19:0] dist1, dist2;  // Distancias a las diagonales
        reg [3:0] thickness;      // Grosor de los trazos
        begin
            width = 20;
            height = 25;
            thickness = 3;
            
            // Comprobar si está dentro del bounding box
            if (x >= x_pos && x <= x_pos + width && y >= y_pos && y <= y_pos + height) begin
                // Calcular distancias a las dos diagonales
                dist1 = dist_to_line_squared(x, y, x_pos, y_pos, x_pos + width, y_pos + height);
                dist2 = dist_to_line_squared(x, y, x_pos, y_pos + height, x_pos + width, y_pos);
                
                // Si está cerca de alguna de las diagonales, dibujar el pixel
                is_letter_x = (dist1 <= thickness*thickness) || (dist2 <= thickness*thickness);
            end else begin
                is_letter_x = 0;
            end
        end
    endfunction
    
    // Función para dibujar la letra Y redondeada y rellenita
    function is_letter_y;
        input [9:0] x_pos, y_pos; // Posición base de la letra
        input [9:0] x, y;         // Punto a evaluar
        reg [9:0] width, height;  // Dimensiones de la letra
        reg [19:0] dist1, dist2, dist3; // Distancias a los trazos
        reg [3:0] thickness;      // Grosor de los trazos
        begin
            width = 20;
            height = 25;
            thickness = 3;
            
            // Comprobar si está dentro del bounding box
            if (x >= x_pos && x <= x_pos + width && y >= y_pos && y <= y_pos + height) begin
                // Rama superior izquierda
                dist1 = dist_to_line_squared(x, y, x_pos, y_pos, x_pos + width/2, y_pos + height/2);
                
                // Rama superior derecha
                dist2 = dist_to_line_squared(x, y, x_pos + width, y_pos, x_pos + width/2, y_pos + height/2);
                
                // Tallo central
                dist3 = dist_to_line_squared(x, y, x_pos + width/2, y_pos + height/2, x_pos + width/2, y_pos + height);
                
                // Si está cerca de alguna de las líneas, dibujar el pixel
                is_letter_y = (dist1 <= thickness*thickness) || 
                              (dist2 <= thickness*thickness) || 
                              (dist3 <= thickness*thickness);
            end else begin
                is_letter_y = 0;
            end
        end
    endfunction
    
    // Función para dibujar la letra Z redondeada y rellenita
    function is_letter_z;
        input [9:0] x_pos, y_pos; // Posición base de la letra
        input [9:0] x, y;         // Punto a evaluar
        reg [9:0] width, height;  // Dimensiones de la letra
        reg [19:0] dist1, dist2, dist3; // Distancias a los trazos
        reg [3:0] thickness;      // Grosor de los trazos
        begin
            width = 20;
            height = 25;
            thickness = 3;
            
            // Comprobar si está dentro del bounding box
            if (x >= x_pos && x <= x_pos + width && y >= y_pos && y <= y_pos + height) begin
                // Línea superior
                dist1 = dist_to_line_squared(x, y, x_pos, y_pos, x_pos + width, y_pos);
                
                // Línea diagonal
                dist2 = dist_to_line_squared(x, y, x_pos + width, y_pos, x_pos, y_pos + height);
                
                // Línea inferior
                dist3 = dist_to_line_squared(x, y, x_pos, y_pos + height, x_pos + width, y_pos + height);
                
                // Si está cerca de alguna de las líneas, dibujar el pixel
                is_letter_z = (dist1 <= thickness*thickness) || 
                              (dist2 <= thickness*thickness) || 
                              (dist3 <= thickness*thickness);
            end else begin
                is_letter_z = 0;
            end
        end
    endfunction
    
    // Función para dibujar dígitos con estilo redondeado
    function is_digit;
        input [9:0] x_pos, y_pos; // Posición base del dígito
        input [3:0] digit;        // Dígito a dibujar (0-9)
        input [9:0] x, y;         // Punto a evaluar
        reg [9:0] width, height;  // Dimensiones del dígito
        reg [9:0] cx, cy, radius; // Centro y radio para formas circulares
        reg [19:0] dist_sq;       // Distancia al cuadrado
        reg [3:0] thickness;      // Grosor de los trazos
        begin
            width = 16;
            height = 24;
            thickness = 3;
            
            // Verificar si está dentro del bounding box del dígito
            if (x >= x_pos && x <= x_pos + width && y >= y_pos && y <= y_pos + height) begin
                case (digit)
                    0: begin // Dígito 0 (óvalo)
                        cx = x_pos + width/2;
                        cy = y_pos + height/2;
                        
                        // Distancia escalada al centro (para crear un óvalo)
                        dist_sq = ((x-cx)*(x-cx)*4/3) + ((y-cy)*(y-cy));
                        
                        // Anillo con grosor
                        radius = width/2;
                        is_digit = (dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                  (dist_sq <= radius*radius);
                    end
                    
                    1: begin // Dígito 1 (línea vertical con serifa)
                        // Línea vertical
                        dist_sq = dist_to_line_squared(x, y, x_pos + width/2, y_pos, x_pos + width/2, y_pos + height);
                        
                        // Serifa superior
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, x_pos + width/4, y_pos, x_pos + width/2, y_pos);
                        
                        // Base
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, x_pos + width/4, y_pos + height, x_pos + 3*width/4, y_pos + height);
                        
                        is_digit = (dist_sq <= thickness*thickness);
                    end
                    
                    2: begin // Dígito 2
                        // Arco superior
                        if (y <= y_pos + height/3) begin
                            cx = x_pos + width/2;
                            cy = y_pos + height/3;
                            radius = width/2;
                            dist_sq = ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                            
                            if ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                (dist_sq <= radius*radius) && 
                                (y <= cy)) begin
                                is_digit = 1;
                            end else begin
                                // Línea diagonal central
                                dist_sq = dist_to_line_squared(x, y, 
                                         x_pos + width, y_pos + height/3,
                                         x_pos, y_pos + 2*height/3);
                                         
                                // Línea inferior
                                dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                         dist_to_line_squared(x, y, 
                                         x_pos, y_pos + height,
                                         x_pos + width, y_pos + height);
                                
                                is_digit = (dist_sq <= thickness*thickness);
                            end
                        end else begin
                            // Línea diagonal central
                            dist_sq = dist_to_line_squared(x, y, 
                                     x_pos + width, y_pos + height/3,
                                     x_pos, y_pos + 2*height/3);
                                     
                            // Línea inferior
                            dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                     dist_to_line_squared(x, y, 
                                     x_pos, y_pos + height,
                                     x_pos + width, y_pos + height);
                            
                            is_digit = (dist_sq <= thickness*thickness);
                        end
                    end
                    
                    3: begin // Dígito 3 (dos semicírculos)
                        // Semicírculo superior
                        cx = x_pos + width/2;
                        cy = y_pos + height/3;
                        radius = width/2;
                        dist_sq = ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                        
                        if ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                            (dist_sq <= radius*radius) && 
                            (x >= cx)) begin
                            is_digit = 1;
                        end else begin
                            // Semicírculo inferior
                            cy = y_pos + 2*height/3;
                            dist_sq = ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                            
                            is_digit = ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                       (dist_sq <= radius*radius) && 
                                       (x >= cx));
                        end
                    end
                    
                    4: begin // Dígito 4
                        // Línea vertical derecha
                        dist_sq = dist_to_line_squared(x, y, 
                                 x_pos + 3*width/4, y_pos,
                                 x_pos + 3*width/4, y_pos + height);
                                 
                        // Línea vertical izquierda (parte superior)
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, 
                                 x_pos + width/4, y_pos,
                                 x_pos + width/4, y_pos + height/2);
                                 
                        // Línea horizontal
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, 
                                 x_pos, y_pos + height/2,
                                 x_pos + width, y_pos + height/2);
                        
                        is_digit = (dist_sq <= thickness*thickness);
                    end
                    
                    5: begin // Dígito 5
                        // Línea superior
                        dist_sq = dist_to_line_squared(x, y, 
                                 x_pos, y_pos,
                                 x_pos + width, y_pos);
                                 
                        // Línea vertical izquierda (parte superior)
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, 
                                 x_pos, y_pos,
                                 x_pos, y_pos + height/2);
                                 
                        // Línea media
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, 
                                 x_pos, y_pos + height/2,
                                 x_pos + width, y_pos + height/2);
                                 
                        // Semicírculo inferior
                        if (dist_sq <= thickness*thickness) begin
                            is_digit = 1;
                        end else begin
                            cx = x_pos + width/2;
                            cy = y_pos + 3*height/4;
                            radius = width/2;
                            dist_sq = ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                            
                            is_digit = ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                       (dist_sq <= radius*radius) && 
                                       (x >= cx || y >= cy));
                        end
                    end
                    
                    6: begin // Dígito 6
                        // Línea vertical izquierda
                        dist_sq = dist_to_line_squared(x, y, 
                                 x_pos, y_pos,
                                 x_pos, y_pos + 2*height/3);
                                 
                        // Círculo inferior
                        cx = x_pos + width/2;
                        cy = y_pos + 3*height/4;
                        radius = width/2;
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                        
                        is_digit = ((dist_sq <= thickness*thickness) || 
                                   ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                    (dist_sq <= radius*radius)));
                    end
                    
                    7: begin // Dígito 7
                        // Línea superior
                        dist_sq = dist_to_line_squared(x, y, 
                                 x_pos, y_pos,
                                 x_pos + width, y_pos);
                                 
                        // Línea diagonal
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 dist_to_line_squared(x, y, 
                                 x_pos + width, y_pos,
                                 x_pos + width/3, y_pos + height);
                        
                        is_digit = (dist_sq <= thickness*thickness);
                    end
                    
                    8: begin // Dígito 8 (dos círculos)
                        // Círculo superior
                        cx = x_pos + width/2;
                        cy = y_pos + height/3;
                        radius = width/2;
                        dist_sq = ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                        
                        // Círculo inferior
                        if ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                            (dist_sq <= radius*radius)) begin
                            is_digit = 1;
                        end else begin
                            cy = y_pos + 2*height/3;
                            dist_sq = ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                            
                            is_digit = ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                       (dist_sq <= radius*radius));
                        end
                    end
                    
                    9: begin // Dígito 9
                        // Línea vertical derecha
                        dist_sq = dist_to_line_squared(x, y, 
                                 x_pos + width, y_pos + height/3,
                                 x_pos + width, y_pos + height);
                                 
                        // Círculo superior
                        cx = x_pos + width/2;
                        cy = y_pos + height/4;
                        radius = width/2;
                        dist_sq = (dist_sq <= thickness*thickness) ? dist_sq : 
                                 ((x-cx)*(x-cx)) + ((y-cy)*(y-cy));
                        
                        is_digit = ((dist_sq <= thickness*thickness) || 
                                   ((dist_sq >= (radius-thickness)*(radius-thickness)) && 
                                    (dist_sq <= radius*radius)));
                    end
                    
                    default: is_digit = 0;
                endcase
            end else begin
                is_digit = 0;
            end
        end
    endfunction
    
    // Definir ubicaciones para las etiquetas y valores
    parameter LABEL_X = 130;
    parameter LABEL_Y = 100;
    parameter SPACING = 80;
    
    // Dibujar etiquetas X, Y, Z
    wire draw_x_label = is_letter_x(LABEL_X, LABEL_Y, counterX, counterY);
    wire draw_y_label = is_letter_y(LABEL_X, LABEL_Y + SPACING, counterX, counterY);
    wire draw_z_label = is_letter_z(LABEL_X, LABEL_Y + 2*SPACING, counterX, counterY);
    
    // Dibujar valores de coordenadas
    wire draw_x_value = 
        is_digit(LABEL_X + 50, LABEL_Y, x_hundreds, counterX, counterY) ||
        is_digit(LABEL_X + 80, LABEL_Y, x_tens, counterX, counterY) ||
        is_digit(LABEL_X + 110, LABEL_Y, x_ones, counterX, counterY);
    
    wire draw_y_value = 
        is_digit(LABEL_X + 50, LABEL_Y + SPACING, y_hundreds, counterX, counterY) ||
        is_digit(LABEL_X + 80, LABEL_Y + SPACING, y_tens, counterX, counterY) ||
        is_digit(LABEL_X + 110, LABEL_Y + SPACING, y_ones, counterX, counterY);
    
    wire draw_z_value = 
        is_digit(LABEL_X + 50, LABEL_Y + 2*SPACING, z_hundreds, counterX, counterY) ||
        is_digit(LABEL_X + 80, LABEL_Y + 2*SPACING, z_tens, counterX, counterY) ||
        is_digit(LABEL_X + 110, LABEL_Y + 2*SPACING, z_ones, counterX, counterY);
    
    // Título "COORDENADAS PWM"
    function is_title_text;
        input [9:0] x, y;
        begin
            // Implementación simplificada: rectángulo con esquinas redondeadas
            is_title_text = (x >= 220 && x <= 420 && y >= 40 && y <= 60) &&
                           (x < 225 || x > 415 || y < 45 || y > 55 || 
                            ((x-225)*(x-225) + (y-45)*(y-45) <= 25) ||
                            ((x-415)*(x-415) + (y-45)*(y-45) <= 25) ||
                            ((x-225)*(x-225) + (y-55)*(y-55) <= 25) ||
                            ((x-415)*(x-415) + (y-55)*(y-55) <= 25));
        end
    endfunction
    
    wire draw_title = is_title_text(counterX, counterY);
    
    // Combinar todos los elementos de texto
    wire text_pixel = draw_x_label || draw_y_label || draw_z_label ||
                      draw_x_value || draw_y_value || draw_z_value ||
                      draw_title;
    
    // Asignar salidas de color (fondo negro, texto blanco)
    assign VGA_R = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_G = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_B = inDisplayArea ? (text_pixel ? 4'hF : 4'h0) : 4'h0;
    
endmodule