module top_robotic_arm #(    
    parameter DATA_WIDTH = 30,
    parameter ADDRESS_WIDTH = 4,
    parameter FREQ_TRANSMIT = 1,
    parameter INVERT_RST = 1,
    parameter INVERT_ROM_LOAD_DATA = 1,
    parameter DEBOUNCE_THRESHOLD = 500_000, 
    parameter WIRE_SIZE = 4, 
    parameter SEGMENTOS = 7
) (
    input rst, load_rom_data, select_source,  // select_source decide si usar memoria o acelerómetro
    output [0: SEGMENTOS - 1] D_unidades_x, D_decenas_x, D_centenas_x, // Display X
    output [0: SEGMENTOS - 1] D_unidades_y, D_decenas_y, D_centenas_y, // Display Y
    output [9:0] leds, // Display Z

    //Acelerometer
    // - CLK
   input ADC_CLK_10,
   input MAX10_CLK1_50,
   input MAX10_CLK2_50,

   output GSENSOR_CS_N,
   input [2:1] GSENSOR_INT,
   output GSENSOR_SCLK,
   inout GSENSOR_SDI,
   inout GSENSOR_SDO, 

// Salidas PWM para servos
    output pwm_servo1, 
    output pwm_servo2,
    output pwm_servo3,
 // Nuevas salidas VGA
    output vga_h_sync,
    output vga_v_sync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b

);

wire one_shot_rst, one_shot_load_rom_data;
wire [9:0] x_mem, y_mem, z_mem; // Datos de la memoria
wire [9:0] x_accel, y_accel, z_accel; // Datos del acelerómetro
wire [9:0] x_selected, y_selected, z_selected; // Datos después del multiplexor

// Señales para VGA
wire inDisplayArea;
wire [9:0] counterX;
wire [9:0] counterY;
wire coord_pixel;
reg clk_25 = 0;

always @(posedge MAX10_CLK1_50)
    clk_25 <= ~clk_25;

// Debouncer para reset
debouncer_one_shot #(.INVERT_LOGIC(INVERT_RST), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_RST (
    .clk(MAX10_CLK1_50),
    .signal(rst),
    .signal_one_shot(one_shot_rst)
);

// Debouncer para la carga de datos de la memoria
debouncer_one_shot #(.INVERT_LOGIC(INVERT_ROM_LOAD_DATA), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_LOAD_ROM_DATA (
    .clk(MAX10_CLK1_50),
    .signal(load_rom_data),
    .signal_one_shot(one_shot_load_rom_data)
);

// Módulo de memoria
arm_position_memory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .FREQ_TRANSMIT(FREQ_TRANSMIT)
) ARM_POS_MEM (
    .clk(MAX10_CLK1_50),
    .rst(one_shot_rst),
    .load_rom_data(one_shot_load_rom_data),
    .x_out(x_mem),
    .y_out(y_mem),
    .z_out(z_mem),
    .select_source(select_source)
);

accel ACCEL_SENSOR (
    .ADC_CLK_10(ADC_CLK_10),
    .MAX10_CLK1_50(MAX10_CLK1_50),
    .MAX10_CLK2_50(MAX10_CLK2_50),
    .rst(rst),
    .GSENSOR_CS_N(GSENSOR_CS_N),
    .GSENSOR_INT(GSENSOR_INT),
    .GSENSOR_SCLK(GSENSOR_SCLK),
    .GSENSOR_SDI(GSENSOR_SDI),
    .GSENSOR_SDO(GSENSOR_SDO),
    .x_out(x_accel),
    .y_out(y_accel),
    .z_out(z_accel)
);

// Multiplexor para seleccionar entre memoria y acelerómetro
assign x_selected = (select_source == 1'b1) ? x_accel : x_mem;
assign y_selected = (select_source == 1'b1) ? y_accel : y_mem;
assign z_selected = (select_source == 1'b1) ? z_accel : z_mem;

// Instancia del módulo PWM de control de servos
    pwm_servos #(
        .FREQ(25_000_000),          // Frecuencia del reloj
        .INVERT_INC(1),             // Invertir lógica de incremento
        .INVERT_DEC(1),             // Invertir lógica de decremento
        .INVERT_RST(0),             // Invertir lógica de reset
        .DEBOUNCE_THRESHOLD(5000),  // Umbral de debounce
        .MIN_DC(25_000),            // Duty cycle mínimo
        .MAX_DC(125_000),           // Duty cycle máximo
        .STEP(10_000),              // Paso de incremento/decremento
        .TARGET_FREQ(10)            // Frecuencia PWM deseada
    ) PWM_SERVOS (
        .clk(MAX10_CLK1_50),        // Reloj principal
        .rst(one_shot_rst),         // Reset
        .x(x_selected),             // Coordenada X
        .y(y_selected),             // Coordenada Y
        .z(z_selected),             // Coordenada Z
        .pwm_servo1(pwm_servo1),    // Salida PWM Servo 1
        .pwm_servo2(pwm_servo2),    // Salida PWM Servo 2
        .pwm_servo3(pwm_servo3)     // Salida PWM Servo 3
    );

// Instancia del generador de sincronización VGA
hvsync_generator hvsync (
    .clk(clk_25),
    .vga_h_sync(vga_h_sync),
    .vga_v_sync(vga_v_sync),
    .counterX(counterX),
    .counterY(counterY),
    .inDisplayArea(inDisplayArea)
);

// Instancia del módulo para mostrar coordenadas
coord_display coord_display_inst (
    .x(x_selected),
    .y(y_selected),
    .z(z_selected),
    .counterX(counterX),
    .counterY(counterY),
    .pixel_on(coord_pixel)
);

// Asignación de colores VGA
assign vga_r = inDisplayArea ? (coord_pixel ? 4'hF : 4'h1) : 4'h0;
assign vga_g = inDisplayArea ? (coord_pixel ? 4'hF : 4'h1) : 4'h0;
assign vga_b = inDisplayArea ? (coord_pixel ? 4'hF : 4'h3) : 4'h0;

// Asignar Z directamente a los LEDs
assign leds = z_selected;

// Display para X
display_module #(.WIRE_SIZE(WIRE_SIZE), .SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH)) DISPLAY_X (
    .number(x_selected),
    .D_unidades(D_unidades_x),
    .D_decenas(D_decenas_x),
    .D_centenas(D_centenas_x)
);

// Display para Y
display_module #(.WIRE_SIZE(WIRE_SIZE), .SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH)) DISPLAY_Y (
    .number(y_selected),
    .D_unidades(D_unidades_y),
    .D_decenas(D_decenas_y),
    .D_centenas(D_centenas_y)
);
endmodule
