Très bien, tu veux un **README.md** stylé et clair pour ton projet UART. Voilà une version professionnelle mais simple à lire (et prête à coller sur GitHub) :

---

# 🛰️ UART Communication - VHDL Mini Project

## 📘 Overview

This project implements a **Universal Asynchronous Receiver-Transmitter (UART)** in **VHDL**.
It includes both the **transmitter (TX)** and **receiver (RX)** modules, along with a **testbench** for functional simulation.
The design allows data transmission through a serial interface with configurable **baud rate**, **clock frequency**, and **parity control**.

## ⚙️ Features

* Fully synthesizable UART design in VHDL
* Configurable parameters:

  * `CLK_FREQ` : System clock frequency
  * `BAUD_RATE` : Transmission speed
  * `PARITY_BIT` : `"none"`, `"even"`, or `"odd"`
* Supports **8-bit data** frames
* Detects **frame** and **parity errors**
* Includes a **loopback testbench** for simulation

## 🧠 Architecture

```
+------------------------+
|        UART.vhd        |
|------------------------|
|  TX Module  | RX Module|
+------------------------+

+------------------------+
|       UART_TB.vhd      |
|------------------------|
|  Generates CLK, RST    |
|  Sends data via TX     |
|  Receives via RX       |
|  Displays simulation   |
+------------------------+
```

## 🧪 Simulation

* The **testbench** sends ASCII characters through the UART transmitter and verifies correct reception via the receiver.
* You can observe signals such as `UART_TXD`, `UART_RXD`, `DIN`, and `DOUT` in your simulation tool (ModelSim, GHDL, Vivado, etc.).

## 🔁 Loopback Mode

To test full-duplex communication, the testbench connects:

```
UART_TXD => UART_RXD
```

This allows the transmitted data to be received internally for verification.

## 🚀 Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/<your-username>/uart-vhdl.git
   cd uart-vhdl
   ```
2. Open your VHDL simulation tool.
3. Compile:

   * `UART.vhd`
   * `UART_TB.vhd`
4. Run the simulation and observe signals on the waveform.

## 📡 Example Configuration

```vhdl
generic map (
    CLK_FREQ   => 50_000_000,
    BAUD_RATE  => 115200,
    PARITY_BIT => "none"
)
```
