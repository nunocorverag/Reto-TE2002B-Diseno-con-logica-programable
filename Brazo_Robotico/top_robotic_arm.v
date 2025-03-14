module top_robotic_arm #(    
    parameter DATA_WIDTH_MEM = 30, // cada posición de la memoria
    parameter DATA_WIDTH_DISPLAY = 10, // bits de los displays 
    parameter DATA_WIDTH_PWM = 10; // bits del pwm
    parameter ADDRESS_WIDTH = 4, // índice con el que se accede a la memoria
    parameter FREQ_TRANSMIT_MEM_DATA = 1, // frecuencia con la que se transmite la información de la memoria (velocidad)
    parameter INVERT_RST = 1, // lógica inversa para el botón
    parameter INVERT_ROM_LOAD_DATA = 1, // lógica inversa para el botón
    parameter DEBOUNCE_THRESHOLD = 500_000, // ciclos que se espera para contar
    parameter SEGMENTOS = 7 // displays
) (
    input rst, 
          load_rom_data, // botón cargar memoria
          select_source,  // select_source decide si usar memoria o acelerómetro
    output [0: SEGMENTOS - 1] HEX_0, HEX_1, HEX_2, HEX_3, HEX_4, HEX_5, // displays
    output [9:0] leds, // verificación del código

    //Acelerometer
    // - CLK
   input ADC_CLK_10, // reloj que convierte señales analógicas en valores digitales
   input MAX10_CLK1_50, // reloj (50MHz) de la FPGA
   // sensores
   output GSENSOR_CS_N, // habilitar el acelerometro
   input [2:1] GSENSOR_INT, // interrupciones para detectar el movimiento repentino
   output GSENSOR_SCLK, // sincronizar la comunicación con el acelerometro (SPI - Serial Peripheral Interface)
   inout GSENSOR_SDI, // FPGA manda señales y comandos (datos -> x, y y z) al acelerometro MOSI (Master Out, Slave In)
   inout GSENSOR_SDO, // FPGA recibe señales y comandos (datos -> x, y y z) del acelerometro MISO (Master In, Slave Out)

    // Salidas PWM para servos
    output pwm_servo1, // eje x
    output pwm_servo2, // eje y
    output pwm_servo3, // eje z
   
    // Salidas VGA
    output hsync_out, // horizontal_sync - indica una nueva línea en la pantalla
    output vsync_out, // verticar_sync - indica un nuevo cuadro (frame)
    output [3:0] VGA_R, // rojo
    output [3:0] VGA_G, // verde
    output [3:0] VGA_B // azul - color de pixeles

);

wire one_shot_rst, one_shot_load_rom_data;
wire [9:0] x_mem, y_mem, z_mem; // Datos de la memoria
wire [9:0] x_accel, y_accel, z_accel; // Datos del acelerómetro
wire [9:0] x_selected, y_selected, z_selected; // Datos después del multiplexor

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
    .DATA_WIDTH(DATA_WIDTH_MEM),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .FREQ_TRANSMIT(FREQ_TRANSMIT_MEM_DATA)
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

wire [9:0] leds_num;
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
        .TARGET_FREQ(10),            // Frecuencia PWM deseada
        .BIT_SIZE(DATA_WIDTH_PWM)
    ) PWM_SERVOS (
        .clk(MAX10_CLK1_50),        // Reloj principal
        .rst(one_shot_rst),         // Reset
        .x(x_selected),             // Coordenada X
        .y(y_selected),             // Coordenada Y
        .z(z_selected),             // Coordenada Z
        .pwm_servo1(pwm_servo1),    // Salida PWM Servo 1
        .pwm_servo2(pwm_servo2),    // Salida PWM Servo 2
        .pwm_servo3(pwm_servo3),     // Salida PWM Servo 3
        .leds_num(leds_num)
    );

// LEDs Debug
assign leds = leds_num;

// Instancia del módulo VGA para visualización
vga VGA_DISPLAY (
    .MAX10_CLK1_50(MAX10_CLK1_50),  // Reloj de 50MHz
    .x_coord(x_selected),           // Coordenada X seleccionada
    .y_coord(y_selected),           // Coordenada Y seleccionada
    .z_coord(z_selected),           // Coordenada Z seleccionada
    .hsync_out(hsync_out),          // Sincronización horizontal
    .vsync_out(vsync_out),          // Sincronización vertical
    .VGA_R(VGA_R),                  // Canal rojo
    .VGA_G(VGA_G),                  // Canal verde
    .VGA_B(VGA_B)                   // Canal azul
);

// Display para X
// display_module #(.SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH_DISPLAY)) DISPLAY_X (
//     .number(x_selected),
//     .HEX_3(HEX_3),
//     .HEX_4(HEX_4),
//     .HEX_5(HEX_5)
// );

// // Display para Y
// display_module #(.SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH_DISPLAY)) DISPLAY_Y (
//     .number(y_selected),
//     .HEX_0(HEX_0),
//     .HEX_1(HEX_1),
//     .HEX_2(HEX_2)
// );

display_module #(.SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH_DISPLAY)) DISPLAY (
    .number(x_selected),
    .is_signed(1),
    .HEX_0(HEX_0),
    .HEX_1(HEX_1),
    .HEX_2(HEX_2),
    .HEX_3(HEX_3),
    .HEX_4(HEX_4),
    .HEX_5(HEX_5)
);
endmodule
