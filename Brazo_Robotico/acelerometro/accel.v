//===========================================================================
// accel.v
//
// Template module to get the DE10-Lite's accelerator working very quickly.
//
//
//===========================================================================

module accel (
   //////////// CLOCK //////////
   input 		          		ADC_CLK_10, 
   input 		          		MAX10_CLK1_50,

   //////////// RST //////////
   input 		     		rst,

   //////////// Accelerometer ports //////////
   output		          		GSENSOR_CS_N,
   input 		     [2:1]		GSENSOR_INT,
   output		          		GSENSOR_SCLK,
   inout 		          		GSENSOR_SDI,
   inout 		          		GSENSOR_SDO,

   //////////// X, Y, Z Outputs //////////
   output [9:0] x_out,
   output [9:0] y_out,
   output [9:0] z_out
   );

//===== Declarations
// parámetros
localparam SPI_CLK_FREQ  = 200;  // SPI Clock (Hz)
localparam UPDATE_FREQ   = 1;    // Sampling frequency (Hz)

// auxiliares de clks and reset
wire reset_n;
wire clk, spi_clk, spi_clk_out;

// output data
wire data_update;
wire [15:0] data_x, data_y, data_z;

//===== Phase-locked Loop (PLL) instantiation. Code was copied from a module
//      produced by Quartus' IP Catalog tool.
// ----- toma el reloj de MAX10_CLK1_50 y produce 3 relojes derivados 
// Este módulo maneja la comunicación SPI con el acelerómetro y obtiene los valores de data_x, data_y y data_z.
PLL ip_inst (
   .inclk0 ( MAX10_CLK1_50 ),
   .c0 ( clk ),                 // reljo de 25 MHz- sincroniza la lógica principal del sistema (procesamiento de datos del accel)
   .c1 ( spi_clk ),             // reloj de 2 MHz - usa la frecuencia de comunicación del SPI con el accel para asegurar 
                                // que el accel siga el ritmo de comunicación con la FPGA 
   .c2 ( spi_clk_out )          // reloj de 2 MHz desfase de 270 grados - mueestre los datos del GSENSOR_SD0 para las lecturas precisas
);

//===== Instantiation of the spi_control module which provides the logic to 
//      interface to the accelerometer.
// -----
spi_control #(     // parameters
      .SPI_CLK_FREQ   (SPI_CLK_FREQ), // frecuencia para el spi_clk
      .UPDATE_FREQ    (UPDATE_FREQ))  // frecuencia de muestreo
   spi_ctrl (      // port connections
      .reset_n    (reset_n), 
      .clk        (clk), 
      .spi_clk    (spi_clk), // reloj del SPI de 2 MHz para la comunicación con el accel
      .spi_clk_out(spi_clk_out), // reloj desfasado de 2 MHz para la sincronización 
      .data_update(data_update), // pulso de indicaciones de datos nuevos (bandera)
      .data_x     (data_x), // posiciones x
      .data_y     (data_y), // posiciones y
		.data_z		(data_z), // posiciones z
      .SPI_SDI    (GSENSOR_SDI), // MOSI enviar datos al accel
      .SPI_SDO    (GSENSOR_SDO), // MISO recibir datos del accel
      .SPI_CSN    (GSENSOR_CS_N), // chip select - se activa cuando el SPI se comunica con el accel
      .SPI_CLK    (GSENSOR_SCLK), // señal de reloj SPI - sincroniza la transferencia de datos
      .interrupt  (GSENSOR_INT) // interrupciones del SPI del accel
);

//===== Main block
//      To make the module do something visible, the 16-bit data_x is 
//      displayed on four of the HEX displays in hexadecimal format.

// Pressing KEY0 freezes the accelerometer's output
assign reset_n = rst; // si se mantiene presionado el botón 0, la cuenta de los displays se congela

// auxiliares para el reset y el clk_div
wire rst_n = !reset_n;
wire clk_div;

clock_divider #(.FREQ(5)) DIVISOR_REFRESH // FREQ -> para que cambie 5 veces por segundo
(
	.clk(MAX10_CLK1_50),
	.clk_div(clk_div)
);

// registro auxiliar para guardar los data_x, data_y, data_z
reg [15:0] data_x_reg, data_y_reg, data_z_reg;

always @(posedge clk_div)
	begin
		data_x_reg <= data_x;
		data_y_reg <= data_y;
		data_z_reg <= data_z;
	end

assign x_out = data_x_reg[9:0]; // Extrae X
assign y_out = data_y_reg[9:0]; // Extrae Y
assign z_out = data_z_reg[9:0]; // Extrae Z

endmodule