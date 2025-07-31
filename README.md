# Hermes Network-on-Chip (NoC) Router with UVM Verification Environment

## Project Description
This project provides a complete implementation and verification solution for a Hermes NoC router. The design features configurable data routing using XY routing algorithm with credit-based flow control, while the UVM testbench enables comprehensive verification with constrained-random testing, functional coverage, and scoreboard validation.

- bidirectional ports (East/West/North/South/Local)
- 16-flit FIFO buffers per port
- Header-based packet switching
- Deadlock-free routing
- Modular crossbar architecture

## Project Flow Summary
- **Data Reception**: Flits arrive at input ports and are stored in FIFO buffers
- **Header Processing**: Header flits are analyzed to determine destination coordinates
- **Routing Decision**: Switch control calculates output port using XY routing
- **Crossbar Configuration**: Connection paths are established between input/output ports
- **Data Transmission**: Flits traverse crossbar when credits are available
- **Flow Control**: Credit signals manage buffer availability between routers
