`timescale 1ns/1ps

module tb_uart;

    reg clk = 0;
    reg rst = 1;

    // UART controls
    reg start = 0;
    reg [7:0] data_in = 8'h00;

    wire baud_tick;
    wire tx_line;
    wire busy;
    wire done;

    // 50 MHz clock => 20 ns period
    always #10 clk = ~clk;

    // Generate baud_tick only while busy (clean pulses per byte)
    baud_gen #(
        .CLK_HZ(50_000_000),
        .BAUD(115200)
    ) u_baud (
        .clk(clk),
        .rst(rst),
        .enable(busy),
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

    // Task to request transmit of one byte
    task send_byte(input [7:0] b);
    begin
        @(posedge clk);
        data_in <= b;
        start   <= 1'b1;
        @(posedge clk);
        start   <= 1'b0;
    end
    endtask

    initial begin
        // reset
        #200;
        rst = 0;

        // send two bytes
        #200;
        send_byte(8'hA5);

        // wait until done
        wait(done);

        #200;
        send_byte(8'h3C);

        wait(done);

        #2000;
        $finish;
    end

endmodule
