module vga(
    input MAX10_CLK1_50,       // Reloj de 50MHz de la placa
    input [9:0] x_coord,       // Coordenada X del PWM (0-1023)
    input [9:0] y_coord,       // Coordenada Y del PWM (0-1023)
    input [9:0] z_coord,       // Coordenada Z del PWM (0-1023)
    output hsync_out,          // Sincronización horizontal VGA
    output vsync_out,          // Sincronización vertical VGA
    output [3:0] VGA_R,        // Canal rojo VGA
    output [3:0] VGA_G,        // Canal verde VGA
    output [3:0] VGA_B         // Canal azul VGA
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
    
    // Wire para señales de píxeles
    wire smiley_pixel;
    wire coord_pixel;
    
    // Instanciar carita feliz (mantenemos tu módulo existente)
    smiley_face smiley_inst(
        .x(counterX),
        .y(counterY),
        .pixel_on(smiley_pixel)
    );
    
    // Instanciar visualizador de coordenadas
    coord_display coord_display_inst(
        .x(x_coord),
        .y(y_coord),
        .z(z_coord),
        .counterX(counterX),
        .counterY(counterY),
        .pixel_on(coord_pixel)
    );
    
    // Asignar colores VGA
    // Si estamos dibujando coordenadas: blanco
    // Si estamos dibujando la carita: amarillo
    // Fondo: azul oscuro
    assign VGA_R = inDisplayArea ? 
                   (coord_pixel ? 4'hF : 
                    (smiley_pixel ? 4'hF : 4'h1)) : 4'h0;
    
    assign VGA_G = inDisplayArea ? 
                   (coord_pixel ? 4'hF : 
                    (smiley_pixel ? 4'hF : 4'h1)) : 4'h0;
    
    assign VGA_B = inDisplayArea ? 
                   (coord_pixel ? 4'hF : 
                    (smiley_pixel ? 4'h0 : 4'h3)) : 4'h0;
    
endmodule