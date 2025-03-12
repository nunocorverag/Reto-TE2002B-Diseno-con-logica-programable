`timescale 1ns/100ps

module debouncer_tb();

    // Parámetros
    parameter CLK_PERIOD = 20;   // Periodo del reloj en ns (50 MHz → 20 ns por ciclo)
    parameter N_MAX = 50;      // Número de ciclos para debounce

    // Señales de prueba
    reg clk;
    reg rst_a_p;
    reg debouncer_in;
    wire debouncer_out;

    // Instancia del módulo bajo prueba
    debouncer #(.N_MAX(N_MAX)) DUT (
        .clk(clk),
        .rst_a_p(rst_a_p),
        .debouncer_in(debouncer_in),
        .debouncer_out(debouncer_out)
    );

    // Generación del reloj (50 MHz → 20 ns por ciclo)
    always begin
        #(CLK_PERIOD/2) clk = ~clk;  // Invierte clk cada 10 ns (50 MHz)
    end

    // Procedimiento de prueba
    initial begin
        // Inicialización de señales
        clk = 0;
        rst_a_p = 1;     // Activar reset
        debouncer_in = 0;

        // Esperar unos ciclos y luego desactivar el reset
        #100;
        rst_a_p = 0;

        // Simular rebotes de un botón (rápidos cambios en la señal)
        #50 debouncer_in = 1;
        #30 debouncer_in = 0;
        #20 debouncer_in = 1;
        #10 debouncer_in = 0;
        #40 debouncer_in = 1; // Finalmente se mantiene en 1

        // Esperar suficiente tiempo para que el debounce procese
        #(N_MAX * CLK_PERIOD);
        
        // Simular que se suelta el botón con rebotes
        #50 debouncer_in = 0;
        #20 debouncer_in = 1;
        #30 debouncer_in = 0;
        #10 debouncer_in = 1;
        #40 debouncer_in = 0; // Finalmente se mantiene en 0

        // Esperar suficiente tiempo para que el debounce procese
        #(N_MAX * CLK_PERIOD);

        // Terminar la simulación
        $stop;
    end

endmodule