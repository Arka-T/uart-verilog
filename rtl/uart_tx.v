`timescale 1ns/1ps

module uart_tx #(
    parameter integer DATA_BITS = 8
)(
    input  wire                  clk,
    input  wire                  rst,       // active-high synchronous reset
    input  wire                  baud_tick, // 1-cycle pulse per bit time
    input  wire                  start,     // 1-cycle request to send
    input  wire [DATA_BITS-1:0]  data_in,   // byte to send
    output reg                   tx_line,   // UART output line
    output reg                   busy,      // 1 while sending
    output reg                   done       // 1-cycle pulse when finished
);

    // FSM states
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0] state;

    reg [DATA_BITS-1:0] shreg;   // shift register holding data
    integer bit_idx;             // which bit we're sending (0..7)

    always @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            tx_line <= 1'b1;     // idle is HIGH
            busy    <= 1'b0;
            done    <= 1'b0;
            shreg   <= {DATA_BITS{1'b0}};
            bit_idx <= 0;
        end else begin
            done <= 1'b0; // default: done is only a pulse

            case (state)
                S_IDLE: begin
                    tx_line <= 1'b1;
                    busy    <= 1'b0;
                    bit_idx <= 0;

                    if (start) begin
                        // latch data at start
                        shreg   <= data_in;
                        busy    <= 1'b1;
                        state   <= S_START;
                    end
                end

                S_START: begin
                    // hold START bit until next baud_tick
                    tx_line <= 1'b0;
                    busy    <= 1'b1;

                    if (baud_tick) begin
                        state <= S_DATA;
                    end
                end

                S_DATA: begin
                    busy    <= 1'b1;
                    tx_line <= shreg[0]; // send LSB first

                    if (baud_tick) begin
                        // shift right to expose next bit
                        shreg <= {1'b0, shreg[DATA_BITS-1:1]};

                        if (bit_idx == DATA_BITS-1) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end

                S_STOP: begin
                    busy    <= 1'b1;
                    tx_line <= 1'b1; // STOP bit is HIGH

                    if (baud_tick) begin
                        state <= S_IDLE;
                        busy  <= 1'b0;
                        done  <= 1'b1; // pulse: finished sending
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
