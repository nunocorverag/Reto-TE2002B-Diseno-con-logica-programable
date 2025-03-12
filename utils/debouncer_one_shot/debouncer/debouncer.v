/*
    debouncer.v

    Descripción:
    ------------
    Este módulo implementa un **debouncer digital**, eliminando el ruido y los rebotes 
    en señales mecánicas. Filtra la señal de entrada `debouncer_in` y 
    genera una salida estable `debouncer_out` solo cuando la entrada ha sido estable 
    por `DEBOUNCE_THRESHOLD` ciclos de reloj.

    Funcionamiento:
    ---------------
    - Usa el módulo `counter_debouncer` para contar ciclos de reloj.
    - Si la señal `debouncer_in` cambia antes de `DEBOUNCE_THRESHOLD`, el contador se reinicia.
    - Si `debouncer_in` se mantiene constante por `DEBOUNCE_THRESHOLD` ciclos, `debouncer_out` se actualiza.
*/


module debouncer #(parameter DEBOUNCE_THRESHOLD = 5000, INVERT_LOGIC = 0)(
	input clk, 					// Señal de reloj (sincroniza el debounce)
		  debouncer_in,			// Entrada (Señal Mecánica)
	output reg debouncer_out	// Salida limpia (Señal de entrada estable y sin rebotes)
);

// Señales internas
wire [ceillog2(DEBOUNCE_THRESHOLD) - 1: 0] counter_out; // Contador de estabilidad de la señal
wire counter_match;						  // Señal de estabilidad
wire debouncer_in_processed;
assign debouncer_in_processed = (INVERT_LOGIC) ? ~debouncer_in : debouncer_in; // Inversión de la lógica

// Instancia del contador que mide estabilidad de la señal de entrada
counter_debouncer #(.DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) CONTADOR_PARA_RATE(
	.clk(clk),
	.counter_out(counter_out),
	.counter_match(counter_match)
);

// Lógica del debounce
always @(posedge counter_match)
begin
	if(counter_match)
		debouncer_out <= debouncer_in_processed; 	// Actualiza la salida si la señal fue estable
	else
		debouncer_out <= debouncer_out; // Mantiene el estado actual
end

// Función para calcular el número de bits necesarios para el contador
function integer ceillog2;
	input integer data;
	integer i, result;
	begin
		for(i = 0; 2**i < data; i = i + 1)
			result = i + 1;
		ceillog2 = result;
	end
	
endfunction
endmodule