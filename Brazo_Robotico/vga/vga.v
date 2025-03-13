module vga(
    input MAX10_CLK1_50,    // Reloj de 50MHz de la placa
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
    
    // Instanciar carita feliz
    wire smiley_pixel;
    smiley_face smiley_inst(
        .x(counterX),
        .y(counterY),
        .pixel_on(smiley_pixel)
    );
    
    // Asignar colores (amarillo para la carita, negro para el fondo)
    assign VGA_R = inDisplayArea ? (smiley_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_G = inDisplayArea ? (smiley_pixel ? 4'hF : 4'h0) : 4'h0;
    assign VGA_B = inDisplayArea ? 4'h0 : 4'h0; // Sin azul para tener amarillo
    
endmodule