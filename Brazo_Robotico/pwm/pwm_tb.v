module pwm_tb();
    reg clk;
    reg rst;
    reg [9:0] x, y, z;
    wire pwm_servo1, pwm_servo2, pwm_servo3;

    // Instancia del módulo pwm_servos
    pwm_servos uut (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .z(z),
        .pwm_servo1(pwm_servo1),
        .pwm_servo2(pwm_servo2),
        .pwm_servo3(pwm_servo3)
    );

    // Generación de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Reloj de 10 ns (100 MHz)
    end

    // Inicialización y pruebas
    initial begin
        rst = 1;
        x = 10'd0;
        y = 10'd0;
        z = 10'd0;
        #100;
        rst = 0;
        #100;
        x = 10'd512; // Valor medio (512)
        y = 10'd512;
        z = 10'd512;
        #100000; // Espera para observar el PWM
        $stop;
    end
endmodule