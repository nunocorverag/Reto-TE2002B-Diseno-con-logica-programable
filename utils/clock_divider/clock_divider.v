// Cual es la limitante de este clock divider
// Que solo puede dividir con multiplos, o sea que va a dividir clk_freq entre los multiplos de la frecuencia
// Si necesitamos una frecuencia de 20 megas, solo podemos hacer o 16 o 25 por los multiplos de 4 y 5
module clock_divider #(parameter FREQ = 1_000)
(
	input clk,
	output reg clk_div 
);

// Frecuencia de operacion
localparam CLK_FREQ = 50_000_000;
localparam COUNT_MAX = (CLK_FREQ / (2*FREQ));

reg [31:0] count = 0;

always @(posedge clk)
    begin
        if(count == (COUNT_MAX - 1))
			count <= 0;
		else	
            count <= count +  1;
    end

always @(posedge clk)
	begin
		if(count == COUNT_MAX - 1)
			clk_div <= ~clk_div;
		else
			clk_div <= clk_div;
	end

endmodule