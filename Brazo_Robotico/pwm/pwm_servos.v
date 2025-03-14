module pwm_servos #(
    parameter FREQ = 25_000_000,          // Frecuencia del reloj
    parameter INVERT_INC = 1,             // Invertir lógica de incremento
    parameter INVERT_DEC = 1,             // Invertir lógica de decremento
    parameter INVERT_RST = 0,             // Invertir lógica de reset
    parameter DEBOUNCE_THRESHOLD = 5000,  // Umbral de debounce
    parameter MIN_DC = 25_000,            // Duty cycle mínimo
    parameter MAX_DC = 125_000,           // Duty cycle máximo
    parameter STEP = 10_000,              // Paso de incremento/decremento
    parameter TARGET_FREQ = 10,           // Frecuencia PWM deseada
    parameter BIT_SIZE = 10               // Tamaño de bits de entrada
)(
    input clk, rst,                       // Entradas: reloj y reset
    input signed [BIT_SIZE-1:0] x, y, z,  // Coordenadas x, y, z (11 bits con signo)
    output reg pwm_servo1,                // Salida PWM Servo 1
    output reg pwm_servo2,                // Salida PWM Servo 2
    output reg pwm_servo3,                 // Salida PWM Servo 3
    output reg [9:0] leds_num
);
    // Parámetros para el mapeo de coordenadas a duty cycle
    localparam COORD_MIN = -270;          // Valor mínimo de coordenada
    localparam COORD_MAX = 270;           // Valor máximo de coordenada
    localparam COORD_RESET = 90;          // Valor de reset (posición central mecánica = 90°)
    
    // Parámetros para el duty cycle
    localparam DC_MIN = 25_000;           // Duty cycle mínimo (-270°)
    localparam DC_MID = 75_000;           // Duty cycle medio (90°)
    localparam DC_MAX = 125_000;          // Duty cycle máximo (270°)
    
    // Señales internas para los duty cycles mapeados
    reg [31:0] DC1, DC2, DC3;             // Duty cycles para cada servo
    reg [31:0] counter;                   // Contador de tiempo
    
    // Parámetros para calcular el período de la señal PWM
    localparam base_freq = FREQ;          // Frecuencia base del reloj
    localparam periodo = base_freq / TARGET_FREQ; // Cálculo del período
    
    // Lógica de signo y valor absoluto para X
    parameter is_signed = 1'b1;           // Definir que siempre manejamos números con signo
    wire is_negative_x = is_signed & (x[BIT_SIZE-1] == 1'b1);
    wire [BIT_SIZE-1:0] abs_x = is_negative_x ? -x : x;
    
    // Lógica de signo y valor absoluto para Y
    wire is_negative_y = is_signed & (y[BIT_SIZE-1] == 1'b1);
    wire [BIT_SIZE-1:0] abs_y = is_negative_y ? -y : y;
    
    // Lógica de signo y valor absoluto para Z
    wire is_negative_z = is_signed & (z[BIT_SIZE-1] == 1'b1);
    wire [BIT_SIZE-1:0] abs_z = is_negative_z ? -z : z;
    
    // Función para convertir ángulo a duty cycle
    function [31:0] angle_to_duty;
        input signed [31:0] angle;
        input is_neg;
        reg signed [31:0] limited_angle;
        reg signed [31:0] abs_angle;
        begin
            // Usar el valor absoluto pre-calculado y el signo
            abs_angle = angle;
            
            // Limitar el ángulo al rango permitido
            limited_angle = (abs_angle > COORD_MAX) ? COORD_MAX : abs_angle;
            
            // Mapeo lineal considerando que 90° es la posición central (DC_MID)
            if (is_neg) begin
                // Para ángulos negativos (hasta -270°)
                angle_to_duty = DC_MID - ((DC_MID - DC_MIN) * limited_angle) / COORD_MAX;
                leds_num = 10'b1111100000;
            end else begin
                // Para ángulos positivos (hasta 270°)
                angle_to_duty = DC_MID + ((DC_MAX - DC_MID) * limited_angle) / COORD_MAX;
                leds_num = 10'b0000011111;
            end
        end
    endfunction
    
    // Mapeo de coordenadas a duty cycle para cada servo
    always @(*) begin
        // Convertir cada coordenada a su correspondiente duty cycle
        DC1 = angle_to_duty(abs_x, is_negative_x);
        // DC2 = angle_to_duty(abs_y, is_negative_y);
        // DC3 = angle_to_duty(abs_z, is_negative_z);
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
            // pwm_servo2 <= (counter < DC2) ? 1'b1 : 1'b0;
            // pwm_servo3 <= (counter < DC3) ? 1'b1 : 1'b0;
        end
    end
endmodule