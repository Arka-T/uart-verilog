# UART TX/RX (Verilog) — Loopback Simulation

This repo contains a simple UART transmitter and receiver implemented in Verilog, verified in Vivado simulation using a loopback test (TX output connected to RX input).

## Files
- `uart_tx.v` — UART transmitter (start bit, 8 data bits LSB-first, stop bit)
- `uart_rx.v` — UART receiver (detect start, sample bits, validate stop, pulse valid)
- `baud_gen.v` — Baud tick generator (1 tick per bit time)
- `tb_uart.v` — Testbench: sends a byte and checks RX output

## Frame Format
- 1 start bit (0)
- 8 data bits (LSB first)
- 1 stop bit (1)

## Demo
Testbench transmits `0xB3` and expects the receiver to output `0xB3` with a `rx_valid` pulse.
