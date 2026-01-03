# UART TX/RX (Verilog) – Loopback Simulation

This repository contains a UART transmitter and receiver implementations written in Verilog,
verified in Vivado behavioral simulation using a loopback test
(TX output connected to RX input).

## Files

- `uart_tx.v` – UART transmitter  
  (1 start bit, 8 data bits LSB-first, 1 stop bit)

- `uart_rx_simple.v` – Simple UART receiver  
  (detect start bit, sample bits on baud tick, validate stop bit, pulse valid)

- `uart_rx_os16.v` – Oversampled UART receiver (16×)  
  (mid-bit sampling for improved noise and clock mismatch tolerance)

- `baud_gen.v` – Baud / oversample tick generator

- `tb_uart_simple.v` – Testbench for simple UART RX

- `tb_uart_os16.v` – Testbench for oversampled UART RX

## Frame Format

- 1 start bit (0)
- 8 data bits (LSB first)
- 1 stop bit (1)

## Demo

Testbenches transmit byte `0xB3` and expect the receiver to output `0xB3`
with a `valid` pulse.
