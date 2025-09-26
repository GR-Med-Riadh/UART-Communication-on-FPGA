# FPGA UART Communication Project

A modular FPGA-based implementation of UART (Universal Asynchronous Receiver/Transmitter) for serial communication.**

##📌 Overview

This project implements a **UART communication protocol** on an FPGA, enabling serial data transmission and reception between digital devices. UART is widely used due to its simplicity, low cost, and flexibility in embedded systems.

### Key Features
- **Asynchronous Communication**: No shared clock required between devices.
- **Modular Design**: Separate modules for clock division, transmission, reception, and debugging.
- **Configurable Baud Rate**: Supports standard baud rates (e.g., 9600, 115200).
- **Error Detection**: Includes parity and framing error checks.
- **Debugging Support**: Uses Vivado's **System ILA** for real-time signal monitoring.

## 📊 UART Protocol Overview

### Data Frame Format
Each UART transmission is organized into a **frame** with the following components:

1. Start Bit (1 bit): Logic `0`, signaling the start of transmission.
2. Data Bits (5–9 bits): Typically 8 bits, transmitted LSB first.
3. Parity Bit (1 bit, optional): For error detection (even, odd, or none).
4. Stop Bit(s) (1–2 bits): Logic `1`, marking the end of the frame.

