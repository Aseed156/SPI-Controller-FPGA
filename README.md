# FPGA SPI Controller (VHDL)

## Overview
This project implements a **custom SPI Master Controller in VHDL** designed for FPGA-based systems.  
It enables reliable serial communication with SPI-compatible devices such as LCDs, sensors, ADC/DACs, and external memory modules.

The design is optimized for **synthesizable FPGA deployment**, modular integration, and deterministic timing behavior.

## Features
- SPI Master mode implementation
- Configurable:
  - Clock polarity (CPOL)
  - Clock phase (CPHA)
  - SPI clock divider
  - Data width (8bit support)
- FSM-based transaction control
- Full-duplex communication (MOSI + MISO)
- Chip Select (CS) control logic
- Busy/Done handshake signaling
- Synchronous design for FPGA synthesis
- Modular and reusable architecture

## Architecture

### FSM Controller
Controls SPI transaction flow:
- IDLE
- LOAD DATA
- ASSERT CS
- SHIFT DATA
- SAMPLE DATA
- DONE

### Clock Divider
Generates SPI clock from system clock using programmable division logic.

### Shift Registers
#### TX Shift Register
- Converts parallel input data into serial MOSI stream

#### RX Shift Register
- Captures serial MISO data and converts it into parallel output

### Control Logic
Handles:
- Bit counter
- Edge selection (rising/falling based on CPOL/CPHA)
- Transfer completion detection
- CS timing control

## Interface Signals

## Inputs
- `clk` : System clock
- `reset` : Active reset signal
- `start` : Start SPI transfer
- `mosi_data_in` : Parallel data to transmit
- `spi_clk_div` : Clock divider setting

## Outputs
- `miso_data_out` : Received parallel data
- `busy` : High during active transfer
- `done` : Pulse when transfer completes

## SPI Lines
- `SCLK` : SPI clock output
- `MOSI` : Master Out Slave In
- `MISO` : Master In Slave Out
- `CS` : Chip select (active low)

## Usage
1. Instantiate SPI controller in your top module.
2. Provide system clock and reset.
3. Load data into transmit register.
4. Assert `start` signal.
5. Wait for `done` flag.

## Applications
- FPGA-based LCD interfacing (ILI9341, ST7735, etc.)
- Sensor communication (temperature, IMU, ADCs)
- Flash / EEPROM access
- Embedded system peripheral integration

## Design Notes
- Fully synchronous FSM design
- Designed for FPGA synthesis (Quartus / Vivado compatible)
- Timing-safe shift operations aligned with SPI mode configuration

## Future Improvements
- DMA-style burst transfers
- FIFO buffer integration
- Multi-slave SPI support
- Higher throughput optimization

## Author
Aseed Faisal  
Computer Engineering Student  
FPGA / Embedded Systems / VLSI Enthusiast
