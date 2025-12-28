`timescale 1ns/1ps

module baud_gen #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer BAUD   = 115200
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  baud_tick
);

    integer cnt;
    localparam integer DIV = CLK_HZ / BAUD;

    always @(posedge clk) begin
        if (rst) begin
            cnt       <= 0;
            baud_tick <= 1'b0;
        end else if (!enable) begin
            cnt       <= 0;
            baud_tick <= 1'b0;
        end else begin
            if (cnt == DIV - 1) begin
                cnt       <= 0;
                baud_tick <= 1'b1;
            end else begin
                cnt       <= cnt + 1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule