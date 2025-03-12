/*
    one_ahot.v

    Descripción:
    ------------

    Este módulo implementa un **generador de pulso unico** (one shot) el cual a partir de señal de entrada.
    Genera un solo pulso de un ciclo de reloj cada vez de detecta una transicion de 0 a 1 en la señal de entrada.

    Funcionamiento:
    ---------------
    ´delay_signal´ variable auxiliar para almacenar cada ciclo de reloj
    ´x_or_signal_clk´ realiza una operacion XOR entre ´delay signal´ y la señal de reloj para detectar cambios en
    la señal de botón.
    ´signal_one_shot´ se activa solo si cuando hay un cambio de flanco positivo en ´signal´ y se cumple la condición del cambio entre
    la señal de reloj ´clk´ y la operacion XOR ´x_or_signal_clk´
*/

module one_shot(
    input clk, signal,
    output reg signal_one_shot
);

reg delay_signal;
reg x_or_signal_clk;

always @(posedge clk) 
begin
    delay_signal <= signal;
    x_or_signal_clk = delay_signal ^ clk;
    signal_one_shot = x_or_signal_clk & signal;
end

endmodule