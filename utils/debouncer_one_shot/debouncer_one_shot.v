// Combines a debouncer with a one shot logic

module debouncer_one_shot #(parameter INVERT_LOGIC = 0, DEBOUNCE_THRESHOLD = 5000)(
    input clk, signal,
    output signal_one_shot
);

wire debouncer_out;

debouncer #(.INVERT_LOGIC(INVERT_LOGIC), .DEBOUNCE_THRESHOLD(DEBOUNCE_THRESHOLD)) DEBOUNCER (
    .clk(clk),
    .debouncer_in(signal),
    .debouncer_out(debouncer_out)
);

one_shot ONE_SHOT(
    .clk(clk),
    .signal(debouncer_out),
    .signal_one_shot(signal_one_shot)
);

endmodule