`timescale 1ns/1ps

module uart_rx_os16 #(
    parameter integer DATA_BITS   = 8,
    parameter integer OVERSAMPLE  = 16,  // typical UART oversampling
    parameter integer MID_SAMPLE  = 8    // sample at middle of bit (OVERSAMPLE/2)
)(
    input  wire                 clk,
    input  wire                 rst,       // active-high synchronous reset
    input  wire                 os_tick,   // 1-cycle pulse at BAUD*OVERSAMPLE
    input  wire                 rx_line,   // UART input line

    output reg  [DATA_BITS-1:0] data_out,
    output reg                  valid,     // 1-cycle pulse when byte ready
    output reg                  framing_error
);

    // States
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0] state;

    reg [$clog2(OVERSAMPLE):0] os_cnt;   // counts oversample ticks within a bit
    integer bit_idx;

    reg [DATA_BITS-1:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            state         <= S_IDLE;
            os_cnt        <= 0;
            bit_idx       <= 0;
            shreg         <= {DATA_BITS{1'b0}};
            data_out      <= {DATA_BITS{1'b0}};
            valid         <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            valid <= 1'b0; // pulse only when a byte completes

            if (os_tick) begin
                case (state)

                    // -------------------------
                    // IDLE: wait for start edge
                    // -------------------------
                    S_IDLE: begin
                        os_cnt        <= 0;
                        bit_idx       <= 0;
                        framing_error <= 1'b0;

                        // Start bit begins when line goes low
                        if (rx_line == 1'b0) begin
                            state  <= S_START;
                            os_cnt <= 0;
                        end
                    end

                    // ---------------------------------------
                    // START: sample start bit in the MIDDLE
                    // ---------------------------------------
                    S_START: begin
                        if (os_cnt == MID_SAMPLE-1) begin
                            // mid-bit sample: should still be 0
                            if (rx_line == 1'b0) begin
                                state   <= S_DATA;
                                bit_idx <= 0;
                                os_cnt  <= 0;
                            end else begin
                                // false start
                                state <= S_IDLE;
                            end
                        end else begin
                            os_cnt <= os_cnt + 1;
                        end
                    end

                    // ---------------------------------------
                    // DATA: sample each data bit in the middle
                    // ---------------------------------------
                    S_DATA: begin
                        if (os_cnt == OVERSAMPLE-1) begin
                            os_cnt <= 0;
                        end else begin
                            os_cnt <= os_cnt + 1;
                        end

                        // sample in the middle of bit time
                        if (os_cnt == MID_SAMPLE-1) begin
                            // UART is LSB-first
                            shreg[bit_idx] <= rx_line;

                            if (bit_idx == DATA_BITS-1) begin
                                state <= S_STOP;
                            end else begin
                                bit_idx <= bit_idx + 1;
                            end
                        end
                    end

                    // ---------------------------------------
                    // STOP: sample stop bit in the middle
                    // ---------------------------------------
                    S_STOP: begin
                        if (os_cnt == MID_SAMPLE-1) begin
                            if (rx_line == 1'b1) begin
                                data_out <= shreg;
                                valid    <= 1'b1;
                            end else begin
                                framing_error <= 1'b1;
                            end
                            state  <= S_IDLE;
                            os_cnt <= 0;
                        end else begin
                            os_cnt <= os_cnt + 1;
                        end
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

endmodule
