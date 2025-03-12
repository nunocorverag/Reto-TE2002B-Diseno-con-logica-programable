module arm_position_memory #(
    // 30 bits for X(10), Y(10) y Z(10)
    parameter DATA_WIDTH = 30,
    parameter ADDRESS_WIDTH = 8,
    parameter MEMORY_SIZE = 2**(ADDRESS_WIDTH) // 2 ^ 8 = 256 posiciones
) (
    input clk, rst, rom_e,
    output reg [DATA_WIDTH-1:0] greater_num,
    output reg [ADDRESS_WIDTH-1:0] greater_num_address
);

reg [DATA_WIDTH-1:0] CAM_MEMORY [0:MEMORY_SIZE-1];

initial begin
    $readmemh("arm_commands.hex", CAM_MEMORY);
end

reg [ADDRESS_WIDTH-1:0] counter;
reg counter_en;
reg process_done;

// FSM states
reg [1:0] state;
localparam IDLE = 2'b00;
localparam SCANNING = 2'b01;
localparam DONE = 2'b10;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        greater_num <= 0;
        greater_num_address <= 0;
        counter <= 0;
        counter_en <= 0;
        process_done <= 0;
        state <= IDLE;
    end 
    else begin
        case (state)
            IDLE: begin
                if (rom_e) begin
                    greater_num <= 0;
                    counter <= 0;
                    counter_en <= 1;
                    process_done <= 0;
                    state <= SCANNING;
                end
            end
            
            SCANNING: begin
                if (counter_en) begin
                    if (CAM_MEMORY[counter] > greater_num) begin
                        greater_num <= CAM_MEMORY[counter];
                        greater_num_address <= counter;
                    end
                    
                    if (counter < MEMORY_SIZE - 1) begin
                        counter <= counter + 1;
                    end
                    else begin
                        counter_en <= 0;
                        process_done <= 1;
                        state <= DONE;
                    end
                end
            end
            
            DONE: begin
                if (rom_e) begin
                    greater_num <= 0;
                    counter <= 0;
                    counter_en <= 1;
                    process_done <= 0;
                    state <= SCANNING;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end


endmodule