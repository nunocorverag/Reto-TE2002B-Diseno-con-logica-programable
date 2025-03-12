module top_robotic_arm #(    
    parameter DATA_WIDTH = 16,
    parameter ADDRESS_WIDTH = 9,
    // parameter MEMORY_SIZE = 2**(ADDRESS_WIDTH - 1),
    parameter INVERT_RST = 1,
    parameter INVERT_ROM_E = 1,
    parameter DEBOUNCE_THRESHOLD = 500_000, 
    parameter WIRE_SIZE = 4, 
    parameter SEGMENTOS = 7
) (
    input clk, rst, rom_e,
    output [0: SEGMENTOS - 1] D_decenas, D_unidades, D_centenas, D_millares, D_decenas_millares, D_centenas_millares,
    output [9:0] leds
);

wire one_shot_rst, one_shot_rom_e;

wire [DATA_WIDTH-1:0] greater_num_wire;
wire [ADDRESS_WIDTH-1:0] greater_num_address_wire;

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
    .ADDRESS_WIDTH(ADDRESS_WIDTH)
) ARM_POS_MEM (
    .clk(clk),
    .rst(one_shot_rst),
    .rom_e(one_shot_rom_e),
    .greater_num(greater_num_wire),
    .greater_num_address(greater_num_address_wire)
);

assign leds = greater_num_address_wire;

display_module #(.WIRE_SIZE(WIRE_SIZE), .SEGMENTOS(SEGMENTOS), .BIT_SIZE(DATA_WIDTH)) DISPLAY_MODULE (
    .number(greater_num_wire),
    .D_unidades(D_unidades),
    .D_decenas(D_decenas),
    .D_centenas(D_centenas),
    .D_millares(D_millares),
    .D_decenas_millares(D_decenas_millares),
    .D_centenas_millares(D_centenas_millares)
);

endmodule