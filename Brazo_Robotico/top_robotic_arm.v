module top_robotic_arm #(    
    parameter DATA_WIDTH = 30,
    parameter ADDRESS_WIDTH = 4,
    parameter FREQ_TRANSMIT = 1,
    // parameter MEMORY_SIZE = 2**(ADDRESS_WIDTH - 1),
    parameter INVERT_RST = 1,
    parameter INVERT_ROM_E = 1,
    parameter DEBOUNCE_THRESHOLD = 500_000, 
    parameter WIRE_SIZE = 4, 
    parameter SEGMENTOS = 7
) (
    input clk, rst, rom_e,
    output [0: SEGMENTOS - 1] D_unidades_x, D_decenas_x, D_centenas_x, // Display X
    output [0: SEGMENTOS - 1] D_unidades_y, D_decenas_y, D_centenas_y, // Display Y
    output [9:0] leds // Display Z
);

wire one_shot_rst, one_shot_rom_e;

wire [9:0] x_out, y_out, z_out;

debouncer_one_shot #(.INVERT_LOGIC(INVERT_RST), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_RST (
    .clk(clk),
    .signal(rst),
    .signal_one_shot(one_shot_rst)
);

debouncer_one_shot #(.INVERT_LOGIC(INVERT_ROM_E), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEB_ONE_SHOT_ROM_E (
    .clk(clk),
    .signal(rom_e),
    .signal_one_shot(one_shot_rom_e)
);


arm_position_memory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .FREQ_TRANSMIT(FREQ_TRANSMIT)
) ARM_POS_MEM (
    .clk(clk),
    .rst(one_shot_rst),
    .rom_e(one_shot_rom_e),
    .x_out(x_out),
    .y_out(y_out),
    .z_out(z_out)
);

// Asignar Z directamente a los LEDs
assign leds = z_out;

// Display para X
display_module #(.WIRE_SIZE(WIRE_SIZE), .SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH)) DISPLAY_X (
    .number(x_out),
    .D_unidades(D_unidades_x),
    .D_decenas(D_decenas_x),
    .D_centenas(D_centenas_x)
);

// Display para Y
display_module #(.WIRE_SIZE(WIRE_SIZE), .SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH)) DISPLAY_Y (
    .number(y_out),
    .D_unidades(D_unidades_y),
    .D_decenas(D_decenas_y),
    .D_centenas(D_centenas_y)
);
endmodule