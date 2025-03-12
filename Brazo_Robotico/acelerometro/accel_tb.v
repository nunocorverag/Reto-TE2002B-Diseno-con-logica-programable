`timescale 1ns/1ps

module accel_tb;

   // Señales de prueba
   reg ADC_CLK_10;
   reg MAX10_CLK1_50;
   reg MAX10_CLK2_50;
   reg [1:0] KEY;
   reg [9:0] SW;
   wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
   wire [9:0] LEDR;
   wire GSENSOR_CS_N;
   reg [2:1] GSENSOR_INT;
   wire GSENSOR_SCLK;
   wire GSENSOR_SDI;
   wire GSENSOR_SDO;
   
   // Instancia del módulo bajo prueba (DUT)
   accel ACCEL (
      .ADC_CLK_10(ADC_CLK_10),
      .MAX10_CLK1_50(MAX10_CLK1_50),
      .MAX10_CLK2_50(MAX10_CLK2_50),
      .HEX0(HEX0),
      .HEX1(HEX1),
      .HEX2(HEX2),
      .HEX3(HEX3),
      .HEX4(HEX4),
      .HEX5(HEX5),
      .KEY(KEY),
      .LEDR(LEDR),
      .SW(SW),
      .GSENSOR_CS_N(GSENSOR_CS_N),
      .GSENSOR_INT(GSENSOR_INT),
      .GSENSOR_SCLK(GSENSOR_SCLK),
      .GSENSOR_SDI(GSENSOR_SDI),
      .GSENSOR_SDO(GSENSOR_SDO)
   );
   
   // Generación de reloj
   always #10 MAX10_CLK1_50 = ~MAX10_CLK1_50; // Reloj de 50 MHz
   always #50 ADC_CLK_10 = ~ADC_CLK_10;       // Reloj de 10 MHz

   // Procedimiento de prueba
   initial begin
      // Inicialización
      MAX10_CLK1_50 = 0;
      ADC_CLK_10 = 0;
      MAX10_CLK2_50 = 0;
      KEY = 2'b11; // No presionado (activo bajo)
      SW = 10'b0000000000;
      GSENSOR_INT = 2'b00;
      
      // Reset
      #100 KEY[0] = 0; // Presionar reset
      #50 KEY[0] = 1;  // Liberar reset
      
      // Simular datos del acelerómetro
      #200 simulate_accel_data(16'h0123, 16'h0456, 16'h0789);
      #200 simulate_accel_data(16'h0A1B, 16'h0C2D, 16'h0E3F);
      
      // Finalizar simulación
      #1000; //$finish;
   end
   
   // Tarea para simular datos del acelerómetro
   task simulate_accel_data(input [15:0] x, input [15:0] y, input [15:0] z);
      begin
         force ACCEL.data_x = x;
         force ACCEL.data_y = y;
         force ACCEL.data_z = z;
         #50;
         release ACCEL.data_x;
         release ACCEL.data_y;
         release ACCEL.data_z;
      end
   endtask

endmodule