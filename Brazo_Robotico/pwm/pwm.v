module pwm #(
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
    input pb_inc, pb_dec, clk, rst, // Entradas: botones de incremento/decremento, reloj y reset
    output reg pwm_out,             // Salida PWM generada
    output reg [9:0] leds           // LEDs para indicar el estado
);

// Declaración de señales internas
wire clk_div; // Señal de reloj dividido
wire one_shot_pb_inc, one_shot_pb_dec, one_shot_rst; // Señales de pulso único para los botones

// Registros para almacenar valores internos
reg [31:0] DC; // Duty cycle actual
reg [31:0] counter; // Contador de tiempo

// Parámetros para calcular el período de la señal PWM
localparam base_freq = FREQ;              // Frecuencia base del reloj
localparam periodo = base_freq / TARGET_FREQ; // Cálculo del período

// Eliminación de rebotes y generación de un solo pulso para los botones
// Se usa un debouncer con un generador de pulso único

debouncer_one_shot #(.INVERT_LOGIC(INVERT_RST), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_RST (
    .clk(clk),
    .signal(rst),
    .signal_one_shot(one_shot_rst)
);

debouncer_one_shot #(.INVERT_LOGIC(INVERT_INC), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_PB_INC (
    .clk(clk),
    .signal(pb_inc),
    .signal_one_shot(one_shot_pb_inc)
);

debouncer_one_shot #(.INVERT_LOGIC(INVERT_DEC), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_PB_DEC (
    .clk(clk),
    .signal(pb_dec),
    .signal_one_shot(one_shot_pb_dec)
);

// Reducción de la frecuencia del reloj
clock_divider #(.FREQ(FREQ)) CLOCK_DIVIDER (
    .clk(clk),
    .rst(one_shot_rst),
    .clk_div(clk_div)
);

// Control del duty cycle y actualización de LEDs
always @(posedge clk_div or posedge one_shot_rst) 
begin
    if (one_shot_rst)
    begin
        DC <= 75_000; // Posición inicial en 90°
        leds <= 10'b0000000100; // Encender LED indicativo de reset
    end 
    else 
    begin
        if (one_shot_pb_dec) // Si se presiona decremento
        begin
            if (DC > MIN_DC) 
                DC <= DC - STEP; // Reducir el duty cycle
            leds <= 10'b0000000010; // Indicar acción con LED (reducción)
        end
        else if (one_shot_pb_inc) // Si se presiona incremento
        begin
            if (DC < MAX_DC) 
                DC <= DC + STEP; // Aumentar el duty cycle
            leds <= 10'b0000000001; // Indicar acción con LED (aumento)
        end
    end
end

// Generación de la señal PWM
always @(posedge clk or posedge one_shot_rst)
begin
    if (one_shot_rst)
    begin
        counter <= 32'd0;
        pwm_out <= 1'b0;
    end
    else 
    begin
        counter <= counter + 32'd1;
        
        // Reiniciar el contador al completar un período
        if (counter >= periodo)
            counter <= 32'd0;
        
        // Comparar con el duty cycle y generar la señal PWM
        if (counter < DC)
            pwm_out <= 1'b1;
        else
            pwm_out <= 1'b0;
    end
end

endmodule
