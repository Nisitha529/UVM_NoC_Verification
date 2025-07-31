`ifndef HEMPS_DEFAULTS_V
`define HEMPS_DEFAULTS_V

module hemps_defaults;

    // Constants
    localparam BL  = 0;
    localparam BC  = 1;
    localparam BR  = 2;
    localparam CL  = 3;
    localparam CC  = 4;
    localparam CRX = 5;
    localparam TL  = 6;
    localparam TC  = 7;
    localparam TR  = 8;

    localparam NPORT              = 5;
    localparam EAST               = 0;
    localparam WEST               = 1;
    localparam NORTH              = 2;
    localparam SOUTH              = 3;
    localparam LOCAL              = 4;
    localparam TAM_FLIT           = 16;
    localparam METADEFLIT         = TAM_FLIT / 2;
    localparam QUARTOFLIT         = TAM_FLIT / 4;
    localparam TAM_BUFFER         = 16;
    localparam TAM_BUFFER_DMNI    = 16;
    localparam TAM_POINTER        = 4;
    localparam NUMBER_PROCESSORS  = 9;
    localparam NUMBER_PROCESSORS_X= 3;
    localparam NUMBER_PROCESSORS_Y= 3;
    localparam NROT               = NUMBER_PROCESSORS;
    localparam MIN_X              = 0;
    localparam MIN_Y              = 0;
    localparam MAX_X              = NUMBER_PROCESSORS_X - 1;
    localparam MAX_Y              = NUMBER_PROCESSORS_Y - 1;
    localparam TAM_LINHA          = 2;

    // Functions

    function [2:0] conv_vector_3;
        input integer val;
        begin
            case (val)
                0: conv_vector_3 = 3'b000;
                1: conv_vector_3 = 3'b001;
                2: conv_vector_3 = 3'b010;
                3: conv_vector_3 = 3'b011;
                4: conv_vector_3 = 3'b100;
                5: conv_vector_3 = 3'b101;
                6: conv_vector_3 = 3'b110;
                7: conv_vector_3 = 3'b111;
                default: conv_vector_3 = 3'b000;
            endcase
        end
    endfunction

    function [3:0] conv_vector_char;
        input [8*2-1:0] str;
        input integer pos;
        reg [7:0] c;
        begin
            c = str[8*(TAM_LINHA - pos) +: 8];
            case (c)
                "0": conv_vector_char = 4'h0;
                "1": conv_vector_char = 4'h1;
                "2": conv_vector_char = 4'h2;
                "3": conv_vector_char = 4'h3;
                "4": conv_vector_char = 4'h4;
                "5": conv_vector_char = 4'h5;
                "6": conv_vector_char = 4'h6;
                "7": conv_vector_char = 4'h7;
                "8": conv_vector_char = 4'h8;
                "9": conv_vector_char = 4'h9;
                "A": conv_vector_char = 4'hA;
                "B": conv_vector_char = 4'hB;
                "C": conv_vector_char = 4'hC;
                "D": conv_vector_char = 4'hD;
                "E": conv_vector_char = 4'hE;
                "F": conv_vector_char = 4'hF;
                default: conv_vector_char = 4'h0;
            endcase
        end
    endfunction

    function [8*1:1] conv_hex;
        input integer val;
        begin
            case (val)
                0: conv_hex = "0";
                1: conv_hex = "1";
                2: conv_hex = "2";
                3: conv_hex = "3";
                4: conv_hex = "4";
                5: conv_hex = "5";
                6: conv_hex = "6";
                7: conv_hex = "7";
                8: conv_hex = "8";
                9: conv_hex = "9";
                10: conv_hex = "A";
                11: conv_hex = "B";
                12: conv_hex = "C";
                13: conv_hex = "D";
                14: conv_hex = "E";
                15: conv_hex = "F";
                default: conv_hex = "U";
            endcase
        end
    endfunction

    function [8*1:1] conv_string_4bits;
        input [3:0] val;
        begin
            conv_string_4bits = conv_hex(val);
        end
    endfunction

    function [8*2:1] conv_string_8bits;
        input [7:0] val;
        begin
            conv_string_8bits = {conv_string_4bits(val[7:4]), conv_string_4bits(val[3:0])};
        end
    endfunction

    function [8*4:1] conv_string_16bits;
        input [15:0] val;
        begin
            conv_string_16bits = {conv_string_8bits(val[15:8]), conv_string_8bits(val[7:0])};
        end
    endfunction

    function [8*8:1] conv_string_32bits;
        input [31:0] val;
        begin
            conv_string_32bits = {conv_string_16bits(val[31:16]), conv_string_16bits(val[15:0])};
        end
    endfunction

    function integer router_position;
        input integer router;
        integer column;
        begin
            column = router % NUMBER_PROCESSORS_X;
            if (router >= NUMBER_PROCESSORS - NUMBER_PROCESSORS_X) begin
                if (column == NUMBER_PROCESSORS_X - 1) router_position = TR;
                else if (column == 0)                router_position = TL;
                else                                 router_position = TC;
            end else if (router < NUMBER_PROCESSORS_X) begin
                if (column == NUMBER_PROCESSORS_X - 1) router_position = BR;
                else if (column == 0)                router_position = BL;
                else                                 router_position = BC;
            end else begin
                if (column == NUMBER_PROCESSORS_X - 1) router_position = CRX;
                else if (column == 0)                router_position = CL;
                else                                 router_position = CC;
            end
        end
    endfunction

    function [METADEFLIT-1:0] router_address;
        input integer router;
        reg [QUARTOFLIT-1:0] pos_x, pos_y;
        begin
            pos_x = router % NUMBER_PROCESSORS_X;
            pos_y = router / NUMBER_PROCESSORS_X;
            router_address = {pos_x, pos_y};
        end
    endfunction

    function [8*17:1] log_filename;
        input integer i;
        reg [8*1:1] xstr, ystr;
        begin
            xstr = conv_hex(i % NUMBER_PROCESSORS_X);
            ystr = conv_hex(i / NUMBER_PROCESSORS_X);
            log_filename = {"log/output", xstr, "x", ystr, ".txt"};
        end
    endfunction

endmodule

`endif
