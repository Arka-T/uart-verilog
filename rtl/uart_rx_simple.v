`timescale 1ns/1ps

module uart_rx_simple #(
    parameter integer DATA_BITS = 8
)(
    input  wire                 clk,
    input  wire                 rst,        // active-high synchronous reset
    input  wire                 baud_tick,  // 1-cycle pulse per bit time
    input  wire                 rx_line,    // UART input line
    output reg  [DATA_BITS-1:0] data_out,   // received byte
    output reg                  valid       // 1-cycle pulse when byte ready
);

    // FSM states
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0] state;

    integer bit_idx;
    reg [DATA_BITS-1:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            bit_idx  <= 0;
            shreg    <= {DATA_BITS{1'b0}};
            data_out <= {DATA_BITS{1'b0}};
            valid    <= 1'b0;
        end else begin
            valid <= 1'b0; // default: pulse only when byte completes

            case (state)
                S_IDLE: begin
                    bit_idx <= 0;
                    // Wait for start bit (line goes low)
                    if (rx_line == 1'b0) begin
                        state <= S_START;
                    end
                end

                S_START: begin
                    // Confirm we're still in start bit at the next baud tick
                    if (baud_tick) begin
                        if (rx_line == 1'b0) begin
                            state   <= S_DATA;
                            bit_idx <= 0;
                        end else begin
                            // False start, go back to idle
                            state <= S_IDLE;
                        end
                    end
                end

                S_DATA: begin
                    // Sample one data bit per baud tick
                    if (baud_tick) begin
                        // UART is LSB first: store sampled bit into shreg[bit_idx]
                        shreg[bit_idx] <= rx_line;

                        if (bit_idx == DATA_BITS-1) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end

                S_STOP: begin
                    // On next baud tick, sample stop bit
                    if (baud_tick) begin
                        if (rx_line == 1'b1) begin
                            data_out <= shreg;
                            valid    <= 1'b1;   // byte received successfully
                        end
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
