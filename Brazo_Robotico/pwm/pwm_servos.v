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
    input signed [10:0] x, y, z,          // Coordenadas x, y, z (11 bits con signo)
    output reg pwm_servo1,                // Salida PWM Servo 1
    output reg pwm_servo2,                // Salida PWM Servo 2
    output reg pwm_servo3                 // Salida PWM Servo 3
);
    // Parámetros para el mapeo de coordenadas a duty cycle
    localparam COORD_MIN = -270;          // Valor mínimo de coordenada
    localparam COORD_MAX = 270;           // Valor máximo de coordenada
    localparam COORD_RESET = 90;          // Valor de reset (posición central mecánica = 90°)
    
    // Parámetros para el duty cycle
    // Nota: Ajustamos el mapeo para que la posición 0 grados corresponda al duty cycle medio
    localparam DC_MIN = 25_000;           // Duty cycle mínimo (-270°)
    localparam DC_MID = 75_000;           // Duty cycle medio (0°)
    localparam DC_MAX = 125_000;          // Duty cycle máximo (270°)
    
    // Señales internas para los duty cycles mapeados
    reg [31:0] DC1, DC2, DC3;             // Duty cycles para cada servo
    reg [31:0] counter;                   // Contador de tiempo
    
    // Parámetros para calcular el período de la señal PWM
    localparam base_freq = FREQ;          // Frecuencia base del reloj
    localparam periodo = base_freq / TARGET_FREQ; // Cálculo del período
    
    // Señales para procesamiento de valores con signo
    wire is_negative_x = (x[10] == 1'b1);
    wire is_negative_y = (y[10] == 1'b1);
    wire is_negative_z = (z[10] == 1'b1);
    
    wire [10:0] abs_x = is_negative_x ? -x : x;
    wire [10:0] abs_y = is_negative_y ? -y : y;
    wire [10:0] abs_z = is_negative_z ? -z : z;
    
    // Función para convertir ángulo a duty cycle (de -270° a 270° hacia DC_MIN a DC_MAX)
    function [31:0] angle_to_duty;
        input signed [31:0] angle;
        reg signed [31:0] limited_angle;
        begin
            // Limitar el ángulo al rango permitido
            limited_angle = (angle < COORD_MIN) ? COORD_MIN : 
                           ((angle > COORD_MAX) ? COORD_MAX : angle);
            
            // Mapeo lineal considerando que 90° es la posición central (DC_MID)
            if (limited_angle < 90) begin
                // Para ángulos de -270° a 90°
                angle_to_duty = DC_MID - ((DC_MID - DC_MIN) * (90 - limited_angle)) / (90 - COORD_MIN);
            end else begin
                // Para ángulos de 90° a 270°
                angle_to_duty = DC_MID + ((DC_MAX - DC_MID) * (limited_angle - 90)) / (COORD_MAX - 90);
            end
        end
    endfunction
    
    // Mapeo de coordenadas a duty cycle para cada servo
    always @(*) begin
        // Convertir cada coordenada a su correspondiente duty cycle
        DC1 = angle_to_duty(x);
        DC2 = angle_to_duty(y);
        DC3 = angle_to_duty(z);
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