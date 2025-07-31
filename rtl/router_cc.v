`timescale 1ns / 1ps

module router_cc #(
    parameter [7:0] address = 8'h11  // Default router address
)(
    input         clock,
    input         reset,
    input  [4:0]  clock_rx,
    input  [4:0]  rx,
    input  [15:0] data_in [0:4],
    output [4:0]  credit_o,
    output [4:0]  clock_tx,
    output [4:0]  tx,
    output [15:0] data_out [0:4],
    input  [4:0]  credit_i
);

// Internal signals
wire [4:0]  h, ack_h, data_av, sender, free, data_ack;
wire [15:0] data [0:4];
wire [2:0]  mux_in [0:4], mux_out [0:4];

// Port definitions
localparam EAST  = 0;
localparam WEST  = 1;
localparam NORTH = 2;
localparam SOUTH = 3;
localparam LOCAL = 4;

// Input buffer instantiation
hermes_buffer feast (
    .clock(clock),
    .reset(reset),
    .data_in(data_in[EAST]),
    .rx(rx[EAST]),
    .h(h[EAST]),
    .ack_h(ack_h[EAST]),
    .data_av(data_av[EAST]),
    .data(data[EAST]),
    .sender(sender[EAST]),
    .clock_rx(clock_rx[EAST]),
    .data_ack(data_ack[EAST]),
    .credit_o(credit_o[EAST])
);

hermes_buffer fwest (
    .clock(clock),
    .reset(reset),
    .data_in(data_in[WEST]),
    .rx(rx[WEST]),
    .h(h[WEST]),
    .ack_h(ack_h[WEST]),
    .data_av(data_av[WEST]),
    .data(data[WEST]),
    .sender(sender[WEST]),
    .clock_rx(clock_rx[WEST]),
    .data_ack(data_ack[WEST]),
    .credit_o(credit_o[WEST])
);

hermes_buffer fnorth (
    .clock(clock),
    .reset(reset),
    .data_in(data_in[NORTH]),
    .rx(rx[NORTH]),
    .h(h[NORTH]),
    .ack_h(ack_h[NORTH]),
    .data_av(data_av[NORTH]),
    .data(data[NORTH]),
    .sender(sender[NORTH]),
    .clock_rx(clock_rx[NORTH]),
    .data_ack(data_ack[NORTH]),
    .credit_o(credit_o[NORTH])
);

hermes_buffer fsouth (
    .clock(clock),
    .reset(reset),
    .data_in(data_in[SOUTH]),
    .rx(rx[SOUTH]),
    .h(h[SOUTH]),
    .ack_h(ack_h[SOUTH]),
    .data_av(data_av[SOUTH]),
    .data(data[SOUTH]),
    .sender(sender[SOUTH]),
    .clock_rx(clock_rx[SOUTH]),
    .data_ack(data_ack[SOUTH]),
    .credit_o(credit_o[SOUTH])
);

hermes_buffer flocal (
    .clock(clock),
    .reset(reset),
    .data_in(data_in[LOCAL]),
    .rx(rx[LOCAL]),
    .h(h[LOCAL]),
    .ack_h(ack_h[LOCAL]),
    .data_av(data_av[LOCAL]),
    .data(data[LOCAL]),
    .sender(sender[LOCAL]),
    .clock_rx(clock_rx[LOCAL]),
    .data_ack(data_ack[LOCAL]),
    .credit_o(credit_o[LOCAL])
);

// Switch control unit
switch_control switch_control (
    .clock(clock),
    .reset(reset),
    .h(h),
    .ack_h(ack_h),
    .address(address),
    .data(data),
    .sender(sender),
    .free(free),
    .mux_in(mux_in),
    .mux_out(mux_out)
);

// Crossbar fabric
hermes_crossbar crossBar (
    .data_av(data_av),
    .data_in(data),
    .data_ack(data_ack),
    .sender(sender),
    .free(free),
    .tab_in(mux_in),
    .tab_out(mux_out),
    .tx(tx),
    .data_out(data_out),
    .credit_i(credit_i)
);

// Clock distribution
assign clock_tx = {5{clock}};

endmodule