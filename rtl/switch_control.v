`timescale 1ns / 1ps

module switch_control (
    input         clock,
    input         reset,
    input  [4:0]  h,
    output [4:0]  ack_h,
    input  [7:0]  address,
    input  [15:0] data [0:4],
    input  [4:0]  sender,
    output [4:0]  free,
    output [2:0]  mux_in [0:4],
    output [2:0]  mux_out [0:4]
);

// State definitions
localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, 
           S4 = 4, S5 = 5, S6 = 6, S7 = 7;

// Port definitions
localparam LOCAL = 0, EAST = 1, WEST = 2, NORTH = 3, SOUTH = 4;

// Internal signals
reg [2:0] ES, PES;
reg [2:0] sel, prox;
reg [2:0] incoming;
reg [15:0] header;
reg [2:0] dirx, diry;
reg [3:0] lx, ly, tx, ty;
reg [4:0] auxfree;
reg [2:0] source [0:4];
reg [4:0] sender_ant;
reg [4:0] ack_h_reg;

// Assign outputs
assign ack_h = ack_h_reg;
assign free  = auxfree;
assign mux_in = source;

// Request detection
wire ask = |h;

// Next port selection
always @(*) begin
    case (sel)
        LOCAL: prox = h[EAST]  ? EAST  : 
                      h[WEST]  ? WEST  : 
                      h[NORTH] ? NORTH : 
                      h[SOUTH] ? SOUTH : LOCAL;
                      
        EAST:  prox = h[WEST]  ? WEST  : 
                      h[NORTH] ? NORTH : 
                      h[SOUTH] ? SOUTH : 
                      h[LOCAL] ? LOCAL : EAST;
                      
        WEST:  prox = h[NORTH] ? NORTH : 
                      h[SOUTH] ? SOUTH : 
                      h[LOCAL] ? LOCAL : 
                      h[EAST]  ? EAST  : WEST;
                      
        NORTH: prox = h[SOUTH] ? SOUTH : 
                      h[LOCAL] ? LOCAL : 
                      h[EAST]  ? EAST  : 
                      h[WEST]  ? WEST  : NORTH;
                      
        SOUTH: prox = h[LOCAL] ? LOCAL : 
                      h[EAST]  ? EAST  : 
                      h[WEST]  ? WEST  : 
                      h[NORTH] ? NORTH : SOUTH;
    endcase
end

// Address processing
assign lx = address[7:4];
assign ly = address[3:0];

// State machine transition
always @(*) begin
    case (ES)
        S0: PES = S1;
        S1: PES = ask ? S2 : S1;
        S2: PES = S3;
        S3: begin
            if (lx == tx && ly == ty && auxfree[LOCAL]) PES = S4;
            else if (lx != tx && auxfree[dirx])         PES = S5;
            else if (lx == tx && ly != ty && auxfree[diry]) PES = S6;
            else                                        PES = S1;
        end
        S4, S5, S6: PES = S7;
        S7:         PES = S1;
        default:    PES = S1;
    endcase
end

// Main state machine and routing logic
always @(posedge clock or posedge reset) begin
    if (reset) begin
        ES         <= S0;
        sel        <= 0;
        ack_h_reg  <= 0;
        auxfree    <= 5'b11111;
        sender_ant <= 0;
        mux_out    <= 32'd0;
        source     <= 32'd0;
    end
    else begin
        ES <= PES;
        header <= data[incoming];
        tx <= header[15:12];
        ty <= header[11:8];
        
        // Direction calculation
        dirx <= (lx > tx) ? WEST : EAST;
        diry <= (ly < ty) ? SOUTH : NORTH;

        case (ES)
            S1: ack_h_reg <= 0;
            
            S2: begin
                sel <= prox;
                incoming <= prox;
            end
            
            S4: begin  // Local port connection
                source[incoming] <= LOCAL;
                mux_out[LOCAL] <= incoming;
                auxfree[LOCAL] <= 0;
                ack_h_reg[sel] <= 1;
            end
            
            S5: begin  // East/West connection
                source[incoming] <= dirx;
                mux_out[dirx] <= incoming;
                auxfree[dirx] <= 0;
                ack_h_reg[sel] <= 1;
            end
            
            S6: begin  // North/South connection
                source[incoming] <= diry;
                mux_out[diry] <= incoming;
                auxfree[diry] <= 0;
                ack_h_reg[sel] <= 1;
            end
            
            default: ack_h_reg[sel] <= 0;
        endcase

        // Track sender status to free ports
        sender_ant <= sender;
        
        if (sender[LOCAL] == 0 && sender_ant[LOCAL] == 1) 
            auxfree[source[LOCAL]] <= 1;
        if (sender[EAST]  == 0 && sender_ant[EAST]  == 1) 
            auxfree[source[EAST]]  <= 1;
        if (sender[WEST]  == 0 && sender_ant[WEST]  == 1) 
            auxfree[source[WEST]]  <= 1;
        if (sender[NORTH] == 0 && sender_ant[NORTH] == 1) 
            auxfree[source[NORTH]] <= 1;
        if (sender[SOUTH] == 0 && sender_ant[SOUTH] == 1) 
            auxfree[source[SOUTH]] <= 1;
    end
end

endmodule