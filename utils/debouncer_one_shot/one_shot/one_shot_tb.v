`timescale 1ns/100ps

module one_shot_tb();

    // Parámetros
    parameter CLK_PERIOD = 2;   // Periodo del reloj en ns (50 MHz → 20 ns por ciclo)
	 
	reg clk, button;
    wire button_one_shot;

    one_shot DUT(
    .clk(clk),
    .button(button),
    .button_one_shot(button_one_shot)
    );

	always begin
        #(CLK_PERIOD/2) clk = ~clk;  // Invierte clk cada 10 ns (50 MHz)
    end
	 
    initial begin
    // Inicializacion de señales
    clk = 0;
    button = 0;
    #10
    button = 1;
    #20
    button = 0;
    #5
    button = 1;
    #30
    button = 0;
    $stop;
    end

endmodule