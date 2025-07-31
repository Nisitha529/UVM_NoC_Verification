`timescale 1ns / 1ps

module hermes_buffer (
    input        clock,
    input        reset,
    input        clock_rx,
    input        rx,
    input [15:0] data_in,
    output       credit_o,
    output       h,
    input        ack_h,
    output       data_av,
    output [15:0] data,
    input        data_ack,
    output       sender
);

// State definitions
localparam S_INIT       = 0;
localparam S_PAYLOAD    = 1;
localparam S_SENDHEADER = 2;
localparam S_HEADER     = 3;
localparam S_END        = 4;
localparam S_END2       = 5;

// Buffer parameters
localparam TAM_BUFFER  = 16;
localparam TAM_POINTER = 4;

// Internal signals
reg [3:0] EA;
reg [15:0] buff [0:TAM_BUFFER-1];
reg [TAM_POINTER-1:0] first, last;
reg tem_espaco;
reg [15:0] counter_flit;
reg h_reg, data_av_reg, sender_reg;

// Continuous assignments
assign credit_o = tem_espaco;
assign h        = h_reg;
assign data_av  = data_av_reg;
assign sender   = sender_reg;
assign data     = buff[first];

// Buffer space management
always @(posedge clock_rx or posedge reset) begin
    if (reset) begin
        tem_espaco <= 1'b1;
    end
    else begin
        tem_espaco <= ~((first == 0 && last == TAM_BUFFER-1) || (first == last+1));
    end
end

// Write pointer management
always @(negedge clock_rx or posedge reset) begin
    if (reset) begin
        last <= 0;
    end
    else if (tem_espaco && rx) begin
        buff[last] <= data_in;
        last <= (last == TAM_BUFFER-1) ? 0 : last + 1;
    end
end

// Main state machine
always @(posedge clock or posedge reset) begin
    if (reset) begin
        counter_flit <= 0;
        h_reg       <= 0;
        data_av_reg <= 0;
        sender_reg  <= 0;
        first       <= 0;
        EA          <= S_INIT;
    end
    else begin
        case (EA)
            S_INIT: begin
                counter_flit <= 0;
                h_reg       <= 0;
                data_av_reg <= 0;
                sender_reg  <= 0;
                
                if (first != last) begin
                    h_reg <= 1'b1;
                    EA    <= S_HEADER;
                end
            end
            
            S_HEADER: begin
                if (ack_h) begin
                    EA          <= S_SENDHEADER;
                    h_reg       <= 1'b0;
                    data_av_reg <= 1'b1;
                    sender_reg  <= 1'b1;
                end
            end
            
            S_SENDHEADER: begin
                if (data_ack) begin
                    first <= (first == TAM_BUFFER-1) ? 0 : first + 1;
                    data_av_reg <= (first+1 != last);
                    EA <= S_PAYLOAD;
                end
            end
            
            S_PAYLOAD: begin
                if (data_ack) begin
                    if (counter_flit != 16'h0001) begin
                        counter_flit <= (counter_flit == 0) ? buff[first] : counter_flit - 1;
                        first <= (first == TAM_BUFFER-1) ? 0 : first + 1;
                        data_av_reg <= (first+1 != last);
                    end
                    else begin
                        first <= (first == TAM_BUFFER-1) ? 0 : first + 1;
                        data_av_reg <= 1'b0;
                        sender_reg  <= 1'b0;
                        EA <= S_END;
                    end
                end
                else if (first != last) begin
                    data_av_reg <= 1'b1;
                end
            end
            
            S_END:  EA <= S_END2;
            S_END2: EA <= S_INIT;
        endcase
    end
end

endmodule