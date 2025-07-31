`timescale 1ns / 1ps

module hermes_crossbar (
    input  [4:0]  data_av,        // Data available signals
    input  [15:0] data_in  [0:4], // Input data buses
    input  [4:0]  credit_i,       // Input credits
    input  [4:0]  sender,         // Sender control signals
    input  [4:0]  free,           // Port free indicators
    input  [2:0]  tab_in   [0:4], // Input routing tables
    input  [2:0]  tab_out  [0:4], // Output routing tables
    output [4:0]  tx,             // Transmission signals
    output [15:0] data_out [0:4], // Output data buses
    output [4:0]  data_ack        // Data acknowledge signals
);

// Port definitions
localparam EAST  = 0;
localparam WEST  = 1;
localparam NORTH = 2;
localparam SOUTH = 3;
localparam LOCAL = 4;

// LOCAL port connections
assign tx[LOCAL]       = (tab_out[LOCAL] == 3'b000 && !free[LOCAL]) ? data_av[EAST]  :
                         (tab_out[LOCAL] == 3'b001 && !free[LOCAL]) ? data_av[WEST]  :
                         (tab_out[LOCAL] == 3'b010 && !free[LOCAL]) ? data_av[NORTH] :
                         (tab_out[LOCAL] == 3'b011 && !free[LOCAL]) ? data_av[SOUTH] : 1'b0;

assign data_out[LOCAL] = (tab_out[LOCAL] == 3'b000 && !free[LOCAL]) ? data_in[EAST]  :
                         (tab_out[LOCAL] == 3'b001 && !free[LOCAL]) ? data_in[WEST]  :
                         (tab_out[LOCAL] == 3'b010 && !free[LOCAL]) ? data_in[NORTH] :
                         (tab_out[LOCAL] == 3'b011 && !free[LOCAL]) ? data_in[SOUTH] : 16'h0;

assign data_ack[LOCAL] = (tab_in[LOCAL] == 3'b000 && data_av[LOCAL]) ? credit_i[EAST]  :
                         (tab_in[LOCAL] == 3'b001 && data_av[LOCAL]) ? credit_i[WEST]  :
                         (tab_in[LOCAL] == 3'b010 && data_av[LOCAL]) ? credit_i[NORTH] :
                         (tab_in[LOCAL] == 3'b011 && data_av[LOCAL]) ? credit_i[SOUTH] : 1'b0;

// EAST port connections
assign tx[EAST]       = (tab_out[EAST] == 3'b001 && !free[EAST]) ? data_av[WEST]  :
                        (tab_out[EAST] == 3'b100 && !free[EAST]) ? data_av[LOCAL] : 1'b0;

assign data_out[EAST] = (tab_out[EAST] == 3'b001 && !free[EAST]) ? data_in[WEST]  :
                        (tab_out[EAST] == 3'b100 && !free[EAST]) ? data_in[LOCAL] : 16'h0;

assign data_ack[EAST] = (tab_in[EAST] == 3'b001 && data_av[EAST]) ? credit_i[WEST]  :
                        (tab_in[EAST] == 3'b010 && data_av[EAST]) ? credit_i[NORTH] :
                        (tab_in[EAST] == 3'b011 && data_av[EAST]) ? credit_i[SOUTH] :
                        (tab_in[EAST] == 3'b100 && data_av[EAST]) ? credit_i[LOCAL] : 1'b0;

// WEST port connections
assign tx[WEST]       = (tab_out[WEST] == 3'b000 && !free[WEST]) ? data_av[EAST]  :
                        (tab_out[WEST] == 3'b100 && !free[WEST]) ? data_av[LOCAL] : 1'b0;

assign data_out[WEST] = (tab_out[WEST] == 3'b000 && !free[WEST]) ? data_in[EAST]  :
                        (tab_out[WEST] == 3'b100 && !free[WEST]) ? data_in[LOCAL] : 16'h0;

assign data_ack[WEST] = (tab_in[WEST] == 3'b000 && data_av[WEST]) ? credit_i[EAST]  :
                        (tab_in[WEST] == 3'b010 && data_av[WEST]) ? credit_i[NORTH] :
                        (tab_in[WEST] == 3'b011 && data_av[WEST]) ? credit_i[SOUTH] :
                        (tab_in[WEST] == 3'b100 && data_av[WEST]) ? credit_i[LOCAL] : 1'b0;

// NORTH port connections
assign tx[NORTH]       = (tab_out[NORTH] == 3'b000 && !free[NORTH]) ? data_av[EAST]  :
                         (tab_out[NORTH] == 3'b001 && !free[NORTH]) ? data_av[WEST]  :
                         (tab_out[NORTH] == 3'b011 && !free[NORTH]) ? data_av[SOUTH] :
                         (tab_out[NORTH] == 3'b100 && !free[NORTH]) ? data_av[LOCAL] : 1'b0;

assign data_out[NORTH] = (tab_out[NORTH] == 3'b000 && !free[NORTH]) ? data_in[EAST]  :
                         (tab_out[NORTH] == 3'b001 && !free[NORTH]) ? data_in[WEST]  :
                         (tab_out[NORTH] == 3'b011 && !free[NORTH]) ? data_in[SOUTH] :
                         (tab_out[NORTH] == 3'b100 && !free[NORTH]) ? data_in[LOCAL] : 16'h0;

assign data_ack[NORTH] = (tab_in[NORTH] == 3'b011 && data_av[NORTH]) ? credit_i[SOUTH] :
                         (tab_in[NORTH] == 3'b100 && data_av[NORTH]) ? credit_i[LOCAL] : 1'b0;

// SOUTH port connections
assign tx[SOUTH]       = (tab_out[SOUTH] == 3'b000 && !free[SOUTH]) ? data_av[EAST]  :
                         (tab_out[SOUTH] == 3'b001 && !free[SOUTH]) ? data_av[WEST]  :
                         (tab_out[SOUTH] == 3'b010 && !free[SOUTH]) ? data_av[NORTH] :
                         (tab_out[SOUTH] == 3'b100 && !free[SOUTH]) ? data_av[LOCAL] : 1'b0;

assign data_out[SOUTH] = (tab_out[SOUTH] == 3'b000 && !free[SOUTH]) ? data_in[EAST]  :
                         (tab_out[SOUTH] == 3'b001 && !free[SOUTH]) ? data_in[WEST]  :
                         (tab_out[SOUTH] == 3'b010 && !free[SOUTH]) ? data_in[NORTH] :
                         (tab_out[SOUTH] == 3'b100 && !free[SOUTH]) ? data_in[LOCAL] : 16'h0;

assign data_ack[SOUTH] = (tab_in[SOUTH] == 3'b010 && data_av[SOUTH]) ? credit_i[NORTH] :
                         (tab_in[SOUTH] == 3'b100 && data_av[SOUTH]) ? credit_i[LOCAL] : 1'b0;

endmodule