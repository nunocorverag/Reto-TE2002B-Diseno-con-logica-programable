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
    input clk, rst, load_rom_data, select_source,  // select_source decide si usar memoria o acelerómetro
    output [0: SEGMENTOS - 1] D_unidades_x, D_decenas_x, D_centenas_x, // Display X
    output [0: SEGMENTOS - 1] D_unidades_y, D_decenas_y, D_centenas_y, // Display Y
    output [9:0] leds, // Display Z
    output pwm_servo1, // Salidas PWM para servos
    output pwm_servo2,
    output pwm_servo3
);

wire one_shot_rst, one_shot_load_rom_data;
wire [9:0] x_mem, y_mem, z_mem; // Datos de la memoria
wire [9:0] x_accel, y_accel, z_accel; // Datos del acelerómetro
wire [9:0] x_selected, y_selected, z_selected; // Datos después del multiplexor

// Debouncer para reset
debouncer_one_shot #(.INVERT_LOGIC(INVERT_RST), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_RST (
    .clk(clk),
    .signal(rst),
    .signal_one_shot(one_shot_rst)
);

// Debouncer para la carga de datos de la memoria
debouncer_one_shot #(.INVERT_LOGIC(INVERT_ROM_LOAD_DATA), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_LOAD_ROM_DATA (
    .clk(clk),
    .signal(load_rom_data),
    .signal_one_shot(one_shot_load_rom_data)
);

// Módulo de memoria
arm_position_memory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .FREQ_TRANSMIT(FREQ_TRANSMIT)
) ARM_POS_MEM (
    .clk(clk),
    .rst(one_shot_rst),
    .load_rom_data(one_shot_load_rom_data),
    .x_out(x_mem),
    .y_out(y_mem),
    .z_out(z_mem),
    .select_source(select_source)
);

// Módulo del acelerómetro (debes implementarlo)
// accelerometer_module ACCEL_SENSOR (
//     .clk(clk),
//     .rst(one_shot_rst),
//     .x_out(x_accel),
//     .y_out(y_accel),
//     .z_out(z_accel),
//     .select_source(select_source)
// );

// Multiplexor para seleccionar entre memoria y acelerómetro
assign x_selected = (select_source == 1'b1) ? x_accel : x_mem;
assign y_selected = (select_source == 1'b1) ? y_accel : y_mem;
assign z_selected = (select_source == 1'b1) ? z_accel : z_mem;

// Instancia del módulo PWM de control de servos
pwm_servos PWM_SERVOS (
    .clk(clk),
    .rst(one_shot_rst),
    .x(x_selected[9:3]),  // Tomar los 7 bits más significativos
    .y(y_selected[9:3]),  // Tomar los 7 bits más significativos
    .z(z_selected[9:3]),  // Tomar los 7 bits más significativos
    .pwm_servo1(pwm_servo1),
    .pwm_servo2(pwm_servo2),
    .pwm_servo3(pwm_servo3)
);

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
