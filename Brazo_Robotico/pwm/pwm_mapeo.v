module pwm_mapeo (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [7:0] angle_input, // Ángulo de entrada (0 a 180)
    output reg pwm_out
);

    // Parámetros del servo
    localparam SERVO_MIN = 500;  // Ancho de pulso mínimo (us)
    localparam SERVO_MAX = 2500; // Ancho de pulso máximo (us)
    localparam PWM_PERIOD = 20000; // Período PWM de 20 ms (50 Hz)

    // Escala el ángulo de entrada al rango del servo
    wire [15:0] scaled_angle = (angle_input * (SERVO_MAX - SERVO_MIN)) / 180 + SERVO_MIN;

    // Contador para generar la señal PWM
    reg [15:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            pwm_out <= 0;
        end else if (enable) begin
            if (counter < scaled_angle) begin
                pwm_out <= 1; // Pulso activo
            end else begin
                pwm_out <= 0; // Pulso inactivo
            end

            if (counter == PWM_PERIOD) begin // Reiniciar el contador después de 20 ms
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule