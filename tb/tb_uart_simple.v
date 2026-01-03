`timescale 1ns/1ps

module tb_uart;

    reg clk = 0;
    reg rst = 1;

    // TX controls
    reg start = 0;
    reg [7:0] data_in = 8'h00;

    // Baud + TX
    wire baud_tick;
    wire tx_line;
    wire busy;
    wire done;

    // RX outputs
    wire [7:0] rx_data;
    wire rx_valid;

    // 50 MHz clock
    always #10 clk = ~clk;

    // Baud tick only while busy (simple and clean)
    baud_gen #(
        .CLK_HZ(50_000_000),
        .BAUD(115200)
    ) u_baud (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .baud_tick(baud_tick)
    );

    uart_tx u_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .start(start),
        .data_in(data_in),
        .tx_line(tx_line),
        .busy(busy),
        .done(done)
    );

    // LOOPBACK: RX reads the same wire TX drives
    uart_rx_simple u_rx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .rx_line(tx_line),
        .data_out(rx_data),
        .valid(rx_valid)
    );

    task send_byte(input [7:0] b);
    begin
        wait(!busy);
        @(posedge clk);
        data_in <= b;
        start   <= 1'b1;
        @(posedge clk);
        start   <= 1'b0;
    end
    endtask

    task expect_byte(input [7:0] b);
    begin
        wait(rx_valid);
        if (rx_data !== b) begin
            $display("FAIL: expected %h, got %h", b, rx_data);
            $fatal;
        end else begin
            $display("PASS: received %h", rx_data);
        end
    end
    endtask

    initial begin
        #200;
        rst = 0;
    
        // ONLY: 0xB3
        #200;
        send_byte(8'hB3);
        expect_byte(8'hB3);
    
        #2000;
        $display("DONE");
        $finish;
    end

endmodule
