class hermes_packet_t extends uvm_sequence_item;
    `uvm_object_utils(hermes_packet_t)

    // Parameters
    parameter half_flit    = hermes_pkg::FLIT_WIDTH / 2;
    parameter quarter_flit = hermes_pkg::FLIT_WIDTH / 4;

    // Packet size types and weights
    typedef enum { SMALL, MED, LARGE } packet_size_t;
    rand packet_size_t p_size;
    bit [4:0] w_small = 20;
    bit [4:0] w_med    = 5;
    bit [4:0] w_large  = 1;

    // Packet data
    rand bit [hermes_pkg::FLIT_WIDTH-1:0] payload[];
    rand bit [quarter_flit-1:0]           x, y;
    rand bit [7:0]                        header;

    // Port tracking
    bit [3:0] oport = -1;  // Output port where captured
    bit [3:0] dport = -1;  // Driver port where inserted

    // Packet size constraints
    constraint c_p_size {
        p_size dist {
            SMALL := w_small,
            MED   := w_med,
            LARGE := w_large
        };
    }

    // Packet payload size constraints
    constraint c_size {
        if (p_size == SMALL) {
            payload.size() inside { [1:3] };
        }
        else if (p_size == LARGE) {
            payload.size() inside { [100:128] };
        }
        else {
            payload.size() inside { [4:99] };
        }
    }

    // Header routing constraints
    constraint c_header {
        header inside { hermes_pkg::valid_addrs(this.dport) };
        x == header[7:4];
        y == header[3:0];
        solve dport before header;
        solve header before x;
        solve header before y;
    }

    // Constructor
    function new(string name = "");
        super.new(name);
    endfunction

    // Header manipulation
    function void set_header(input bit [hermes_pkg::FLIT_WIDTH-1:0] h);
        y = h[quarter_flit-1:0];
        x = h[half_flit-1:quarter_flit];
    endfunction

    function bit [hermes_pkg::FLIT_WIDTH-1:0] get_header();
        return {8'b0, x, y};
    endfunction

    // UVM utilities
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        hermes_packet_t that;
        if (!$cast(that, rhs)) return 0;
        return (
            super.do_compare(rhs, comparer) &&
            this.x      == that.x &&
            this.y      == that.y &&
            this.payload.size() == that.payload.size() &&
            this.payload == that.payload
        );
    endfunction

    virtual function void do_copy(uvm_object rhs);
        hermes_packet_t that;
        if (!$cast(that, rhs)) begin
            `uvm_error(get_name(), "rhs is not a hermes_packet_t")
            return;
        end
        super.do_copy(rhs);
        this.x       = that.x;
        this.y       = that.y;
        this.dport   = that.dport;
        this.oport   = that.oport;
        this.payload = that.payload;
    endfunction

    virtual function string convert2string();
        string s = super.convert2string();
        s = { s, $sformatf("\nx      : %0d", x) };
        s = { s, $sformatf("\ny      : %0d", y) };
        s = { s, $sformatf("\nip     : %0d", dport) };
        s = { s, $sformatf("\nop     : %0d", oport) };
        s = { s, $sformatf("\nsize   : %0d", payload.size()) };
        s = { s, $sformatf("\npayload: ") };
        foreach (payload[i]) begin
            s = { s, $sformatf("\n\t%H ", payload[i]) };
        end
        return s;
    endfunction

    function void do_record(uvm_recorder recorder);
        super.do_record(recorder);
        `uvm_record_attribute(recorder.tr_handle, "x", x)
        `uvm_record_attribute(recorder.tr_handle, "y", y)
        `uvm_record_attribute(recorder.tr_handle, "ip", dport)
        `uvm_record_attribute(recorder.tr_handle, "op", oport)
        `uvm_record_attribute(recorder.tr_handle, "size", payload.size())
    endfunction
endclass : hermes_packet_t

typedef uvm_sequencer #(hermes_packet_t) packet_sequencer;