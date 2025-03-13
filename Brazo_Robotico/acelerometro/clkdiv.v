// módulo de clk divider definir los pulsos de reloj, 
// reduce la frecuencia del clk para que el conteo sea visible.
module clkdiv #(parameter FREQ = 2) // definimos la frecuencia de 1,000 Hz.
													// NO puede haber una frecuencia que sea mayor que el CLK_FREQ.
(
	input clk,
			rst,
	output reg clk_div 
);

// parámetro local porque el reloj de la frecuencia siempre va a ser fijo de 50,000,000 Hz.
localparam CLK_FREQ = 50_000_000;

// parámetro local que sirve para que de manera automática se calcule el conteo de ciclos.
localparam COUNT_MAX = (CLK_FREQ / (2 * FREQ));

// auxiliares
reg [31:0] count;
// reg [ceilog(COUNT_MAX):0] count; 

// sirve para contar hasta 32, 50_000_000 millones de veces.
always @(posedge clk or posedge rst) // posedge es el blanco positivo que cambia de 0 a 1, 
// ponemos resete síncrono que no depende de la señal del reloj
    begin
        if(rst == 1) // se resetea con 1
            count <= 32'b0; // <= , sirve para asginar registros si se cumple la condición
        else if(count == CLK_FREQ - 1)
				count <= 32'b0;
		  else	
            count <= count +  1; // <= , sirve para asginar registros si se cumple la condición
    end

// sirve para actualizarse cada que llega a 32
always @(posedge clk or posedge rst)
	begin
		if(rst == 1)
			clk_div <= 1'b0;
		else if (count == COUNT_MAX - 1)
			clk_div <= ~clk_div; //
		else
			clk_div <= clk_div;
	end

endmodule