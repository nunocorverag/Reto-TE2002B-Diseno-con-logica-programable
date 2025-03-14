module arm_position_memory #(
    // 30 bits for X(10), Y(10) y Z(10)
    parameter DATA_WIDTH = 30, //tamaño de los datos de la mem
    parameter ADDRESS_WIDTH = 4,
    parameter FREQ_TRANSMIT = 1_000  // Frecuencia deseada en Hz

) (
    input clk, rst, load_rom_data, select_source,
    output reg [9:0] x_out, y_out, z_out
);

localparam MEMORY_SIZE = 2**(ADDRESS_WIDTH); // 2 ^ 4 = 16 posiciones

reg [DATA_WIDTH-1:0] ARM_POSITIONS [0:MEMORY_SIZE-1];

initial begin
    $readmemb("arm_commands.bin", ARM_POSITIONS);
end

reg [ADDRESS_WIDTH-1:0] counter;
reg counter_en;

localparam CLK_FREQ = 50_000_000;
localparam DELAY_COUNT = (CLK_FREQ / (2 * FREQ_TRANSMIT)); // Cálculo automático del contador de retardo
reg [31:0] delay_counter; // Contador para manejar el retardo

// FSM states
reg [1:0] state;
localparam IDLE = 2'b00;
localparam WAIT_DELAY = 2'b01;
localparam TRANSMIT = 2'b10;
localparam DONE = 2'b11;

always @(posedge clk or posedge rst) begin
    if (rst == 1'b1) begin
        counter <= 0;
        counter_en <= 0;
        delay_counter <= 0;
        x_out <= 0;
        y_out <= 0;
        z_out <= 0;
        state <= IDLE;
    end 
    else begin
        case (state)
            IDLE: begin
                if ((load_rom_data == 1'b1) & (select_source == 1'b0)) begin
                    counter <= 0;
                    counter_en <= 1;
                    delay_counter <= 0;
                    state <= TRANSMIT;
                end
            end
            
            TRANSMIT: begin
                if (counter_en == 1'b1) begin
                    // Separar los 30 bits en X, Y y Z
                    x_out <= ARM_POSITIONS[counter][29:20]; 
                    y_out <= ARM_POSITIONS[counter][19:10]; 
                    z_out <= ARM_POSITIONS[counter][9:0];

                    state <= WAIT_DELAY; // Pasar al estado de espera
                end
            end

            WAIT_DELAY: begin
                if (delay_counter < DELAY_COUNT) begin
                    delay_counter <= delay_counter + 1;
                end
                else begin
                    delay_counter <= 0;
                    if (counter < MEMORY_SIZE - 1) begin
                        counter <= counter + 1;
                        state <= TRANSMIT;
                    end
                    else begin
                        counter_en <= 0;
                        state <= DONE;
                    end
                end
            end
            
            DONE: begin
                if (load_rom_data == 1'b1) begin
                    counter <= 0;
                    counter_en <= 1;
                    delay_counter <= 0;
                    state <= TRANSMIT;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule
