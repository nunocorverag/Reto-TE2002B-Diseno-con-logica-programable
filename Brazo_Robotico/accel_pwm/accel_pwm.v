module accel_pwm (
   //////////// CLOCK //////////
   input 		          		ADC_CLK_10,
   input 		          		MAX10_CLK1_50,
   input 		          		MAX10_CLK2_50,

   //////////// SEG7 //////////
   output		     [7:0]		HEX0,
   output		     [7:0]		HEX1,
   output		     [7:0]		HEX2,
   output		     [7:0]		HEX3,
   output		     [7:0]		HEX4,
   output		     [7:0]		HEX5,

   //////////// KEY //////////
   input 		     [1:0]		KEY,

   //////////// LED //////////
   output		     [9:0]		LEDR,

   //////////// SW //////////
   input 		     [9:0]		SW,

   //////////// Accelerometer ports //////////
   output		          		GSENSOR_CS_N,
   input 		     [2:1]		GSENSOR_INT,
   output		          		GSENSOR_SCLK,
   inout 		          		GSENSOR_SDI,
   inout 		          		GSENSOR_SDO,
   
   //////////// Servo Motors (GPIO) //////////
   output                      SERVO_X,
   output                      SERVO_Y,
   output                      SERVO_Z
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

//===== Phase-locked Loop (PLL) instantiation
PLL ip_inst (
   .inclk0 ( MAX10_CLK1_50 ),
   .c0 ( clk ),                 // 25 MHz, phase   0 degrees
   .c1 ( spi_clk ),             //  2 MHz, phase   0 degrees
   .c2 ( spi_clk_out )          //  2 MHz, phase 270 degrees
);

//===== Instantiation of the spi_control module
spi_control #(     // parameters
      .SPI_CLK_FREQ   (SPI_CLK_FREQ),
      .UPDATE_FREQ    (UPDATE_FREQ))
   spi_ctrl (      // port connections
      .reset_n    (reset_n),
      .clk        (clk),
      .spi_clk    (spi_clk),
      .spi_clk_out(spi_clk_out),
      .data_update(data_update),
      .data_x     (data_x),
      .data_y     (data_y),
      .data_z     (data_z),
      .SPI_SDI    (GSENSOR_SDI),
      .SPI_SDO    (GSENSOR_SDO),
      .SPI_CSN    (GSENSOR_CS_N),
      .SPI_CLK    (GSENSOR_SCLK),
      .interrupt  (GSENSOR_INT)
);

// Pressing KEY0 freezes the accelerometer's output
assign reset_n = KEY[0];

// auxiliares para el reset y el clk_2_hz
wire rst_n = !reset_n;
wire clk_2_hz;

clkdiv #(.FREQ(1_000_000)) DIVISOR_REFRESH
(
    .clk(MAX10_CLK1_50),
    .rst(rst_n),
    .clk_div(clk_2_hz)
);

// registro auxiliar para guardar los data_x, data_y, data_z
reg [15:0] data_x_reg, data_y_reg, data_z_reg;

// Escala para convertir datos del acelerómetro a valores PWM
// Asumimos que el rango del acelerómetro es ±2000
wire [31:0] servo_x_dc, servo_y_dc, servo_z_dc;

// Mapeo de los valores del acelerómetro a los rangos de PWM
// Rango típico para servos: 25,000 a 125,000 (1ms a 2ms @ 50Hz)
assign servo_x_dc = 75000 + ((data_x_reg * 50000) / 2000);
assign servo_y_dc = 75000 + ((data_y_reg * 50000) / 2000);
assign servo_z_dc = 75000 + ((data_z_reg * 50000) / 2000);

// Actualización de los registros a frecuencia controlada
always @(posedge clk_2_hz)
begin
    data_x_reg <= data_x;
    data_y_reg <= data_y;
    data_z_reg <= data_z;
end

// Instanciación de los módulos PWM para cada servo
pwm #(
    .FREQ(25_000_000),          // Frecuencia del reloj (25MHz)
    .INVERT_INC(1),
    .INVERT_DEC(1),
    .INVERT_RST(0),
    .DEBOUNCE_THRESHOLD(5000),
    .MIN_DC(25_000),            // 1ms para 0 grados
    .MAX_DC(125_000),           // 2ms para 180 grados
    .STEP(10_000),
    .TARGET_FREQ(50)            // 50Hz para servos estándar
) PWM_SERVO_X (
    .pb_inc(SW[1]),             // Usar switches como botones para control manual
    .pb_dec(SW[0]),
    .clk(clk),                  // Reloj de 25MHz
    .rst(rst_n),
    .pwm_out(SERVO_X),
    .leds(LEDR[9:0])
);

// Control para servo Y
pwm #(
    .FREQ(25_000_000),
    .INVERT_INC(1),
    .INVERT_DEC(1),
    .INVERT_RST(0),
    .DEBOUNCE_THRESHOLD(5000),
    .MIN_DC(25_000),
    .MAX_DC(125_000),
    .STEP(10_000),
    .TARGET_FREQ(50)
) PWM_SERVO_Y (
    .pb_inc(SW[3]),
    .pb_dec(SW[2]),
    .clk(clk),
    .rst(rst_n),
    .pwm_out(SERVO_Y),
    .leds()                     // No conectamos los LEDs para este servo
);

// Control para servo Z
pwm #(
    .FREQ(25_000_000),
    .INVERT_INC(1),
    .INVERT_DEC(1),
    .INVERT_RST(0),
    .DEBOUNCE_THRESHOLD(5000),
    .MIN_DC(25_000),
    .MAX_DC(125_000),
    .STEP(10_000),
    .TARGET_FREQ(50)
) PWM_SERVO_Z (
    .pb_inc(SW[5]),
    .pb_dec(SW[4]),
    .clk(clk),
    .rst(rst_n),
    .pwm_out(SERVO_Z),
    .leds()                     // No conectamos los LEDs para este servo
);

// Visualización de datos en los displays de 7 segmentos
// axuliares para almacenar las conversiones de unidades, decenas y centenas
wire [3:0] unidades_x = data_x_reg % 10;
wire [3:0] decenas_x = (data_x_reg / 10) % 10;
wire [3:0] centenas_x = data_x_reg / 100;

wire [3:0] unidades_y = data_y_reg % 10;
wire [3:0] decenas_y = (data_y_reg / 10) % 10;
wire [3:0] centenas_y = data_y_reg / 100;

// 7-segment displays
seg7 s0 ( .in(unidades_x), .display(HEX0) );
seg7 s1 ( .in(decenas_x), .display(HEX1) );
seg7 s2 ( .in(centenas_x), .display(HEX2) );
seg7 s3 ( .in(unidades_y), .display(HEX3) );
seg7 s4 ( .in(decenas_y), .display(HEX4) );
seg7 s5 ( .in(centenas_y), .display(HEX5) );

// Mostrar datos Z en LEDs cuando no están siendo usados por el PWM
//assign LEDR = data_z_reg[9:0];

endmodule