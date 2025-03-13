module pwm_servos #(
    parameter FREQ = 25_000_000,          // Frecuencia del reloj
    parameter INVERT_INC = 1,             // Invertir lógica de incremento
    parameter INVERT_DEC = 1,             // Invertir lógica de decremento
    parameter INVERT_RST = 0,             // Invertir lógica de reset
    parameter DEBOUNCE_THRESHOLD = 5000,  // Umbral de debounce
    parameter MIN_DC = 25_000,            // Duty cycle mínimo
    parameter MAX_DC = 125_000,           // Duty cycle máximo
    parameter STEP = 10_000,              // Paso de incremento/decremento
    parameter TARGET_FREQ = 10            // Frecuencia PWM deseada
)(
    input clk, rst,                       // Entradas: reloj y reset
    input [9:0] x, y, z,                  // Coordenadas x, y, z (10 bits cada una)
    output reg pwm_servo1,                // Salida PWM Servo 1
    output reg pwm_servo2,                // Salida PWM Servo 2
    output reg pwm_servo3                 // Salida PWM Servo 3
);

    // Parámetros para el mapeo de coordenadas a duty cycle
    localparam COORD_MIN = 0;
    localparam COORD_MAX = 1023;
    localparam DC_MIN = 25_000;           // Duty cycle mínimo (0°)
    localparam DC_MAX = 125_000;          // Duty cycle máximo (180°)

    // Señales internas para los duty cycles mapeados
    reg [31:0] DC1, DC2, DC3;             // Duty cycles para cada servo
    reg [31:0] counter;                   // Contador de tiempo

    // Parámetros para calcular el período de la señal PWM
    localparam base_freq = FREQ;          // Frecuencia base del reloj
    localparam periodo = base_freq / TARGET_FREQ; // Cálculo del período

    // Mapeo de coordenadas a duty cycle para cada servo
    always @(*) begin
        DC1 = ((x - COORD_MIN) * (DC_MAX - DC_MIN)) / (COORD_MAX - COORD_MIN) + DC_MIN;
        DC2 = ((y - COORD_MIN) * (DC_MAX - DC_MIN)) / (COORD_MAX - COORD_MIN) + DC_MIN;
        DC3 = ((z - COORD_MIN) * (DC_MAX - DC_MIN)) / (COORD_MAX - COORD_MIN) + DC_MIN;
    end

    // Generación de la señal PWM para cada servo
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 32'd0;
            pwm_servo1 <= 1'b0;
            pwm_servo2 <= 1'b0;
            pwm_servo3 <= 1'b0;
        end else begin
            counter <= counter + 32'd1;

            // Reiniciar el contador al completar un período
            if (counter >= periodo)
                counter <= 32'd0;

            // Comparar con el duty cycle y generar las señales PWM
            pwm_servo1 <= (counter < DC1) ? 1'b1 : 1'b0;
            pwm_servo2 <= (counter < DC2) ? 1'b1 : 1'b0;
            pwm_servo3 <= (counter < DC3) ? 1'b1 : 1'b0;
        end
    end

endmodule