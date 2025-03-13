module pwm_servo_control (
    input wire clk,        // Reloj principal
    input wire rst,        // Reset
    input wire [6:0] x,    // Coordenada X de 7 bits
    input wire [6:0] y,    // Coordenada Y de 7 bits
    input wire [6:0] z,    // Coordenada Z de 7 bits
    output wire pwm_servo1,// Salida PWM Servo 1
    output wire pwm_servo2,// Salida PWM Servo 2
    output wire pwm_servo3 // Salida PWM Servo 3
);

    // Módulos PWM para cada servo
    pwm_servo servo1 (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),    // Siempre habilitado
        .angle_input(x),  // Entrada directa de 7 bits
        .pwm_out(pwm_servo1)
    );

    pwm_servo servo2 (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),    // Siempre habilitado
        .angle_input(y),  // Entrada directa de 7 bits
        .pwm_out(pwm_servo2)
    );

    pwm_servo servo3 (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),    // Siempre habilitado
        .angle_input(z),  // Entrada directa de 7 bits
        .pwm_out(pwm_servo3)
    );

endmodule