class hermes_router_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(hermes_router_scoreboard)

  uvm_analysis_port #(hermes_packet_t) in_mon_ap;   // From input monitor to SB
  uvm_analysis_port #(hermes_packet_t) out_mon_ap;  // From output monitor to SB
  uvm_analysis_port #(hermes_packet_t) cov_ap;      // For coverage collection

  uvm_tlm_analysis_fifo #(hermes_packet_t) input_fifo;
  uvm_tlm_analysis_fifo #(hermes_packet_t) output_fifo;

  // Simulation statistics
  int packet_matches;
  int packet_mismatches; 
  int packets_sent;
  int packets_received; 

  // Input packet storage for checking
  hermes_packet_t input_packet_queue[$];


  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new


  function void build_phase(uvm_phase phase);
    in_mon_ap      = new("in_mon_ap", this);
    out_mon_ap     = new("out_mon_ap", this); 
    cov_ap         = new("cov_ap", this); 
    input_fifo     = new("input_fifo", this); 
    output_fifo    = new("output_fifo", this); 
    
    packet_matches    = 0;
    packet_mismatches = 0;
    packets_sent      = 0;
    packets_received  = 0;
  endfunction : build_phase


  function void connect_phase(uvm_phase phase);
    in_mon_ap.connect(input_fifo.analysis_export);
    out_mon_ap.connect(output_fifo.analysis_export);
  endfunction : connect_phase


  task run_phase(uvm_phase phase);
    fork
      get_input_data(input_fifo, phase);
      get_output_data(output_fifo, phase);
    join
  endtask : run_phase


  task get_input_data(uvm_tlm_analysis_fifo #(hermes_packet_t) fifo, uvm_phase phase);
    hermes_packet_t tx;
    forever begin
      fifo.get(tx);
      phase.raise_objection(this);
      input_packet_queue.push_back(tx);
      packets_sent++;
      `uvm_info("SCOREBOARD", "Input packet received", UVM_HIGH)
    end
  endtask : get_input_data


  task get_output_data(uvm_tlm_analysis_fifo #(hermes_packet_t) fifo, uvm_phase phase);
    hermes_packet_t tx;
    int             i;
    bit             found;
    
    forever begin
      tx = hermes_packet_t::type_id::create("tx");
      fifo.get(tx);
      
      packets_received++;
      `uvm_info("SCOREBOARD", "Output packet received", UVM_HIGH)
      
      if (input_packet_queue.size() == 0) begin
        `uvm_error("SB_MISMATCH", 
                  $sformatf("Input packet queue empty!\n%s", tx.convert2string()))
        packet_mismatches++;
      end
      
      found = 0;
      for (i = 0; i < input_packet_queue.size(); i++) begin
        if (input_packet_queue[i].compare(tx)) begin
          if (check_xy_routing(tx.x, tx.y, input_packet_queue[i].dport, tx.oport)) begin
            `uvm_info("SB_MATCH", 
                     $sformatf("Packet routed successfully!\n%s", tx.convert2string()), 
                     UVM_HIGH)
            packet_matches++;
            found = 1;
            tx.dport = input_packet_queue[i].dport;  // Set source port for coverage
            cov_ap.write(tx);                        // Send to coverage
            input_packet_queue.delete(i);
            break;
          end 
          else begin
            `uvm_error("SB_MISMATCH", 
                      $sformatf("Invalid routing!\n%s", tx.convert2string()))
          end
        end
      end
      
      if (!found) begin  
        `uvm_error("SB_MISMATCH", 
                  $sformatf("Packet mismatch!\n%s", tx.convert2string()))
        packet_mismatches++;      
      end 
      phase.drop_objection(this);
    end
  endtask : get_output_data


  function void extract_phase(uvm_phase phase);
    hermes_packet_t t;
    super.extract_phase(phase);

    `uvm_info("SCOREBOARD", 
             $sformatf("Simulation summary:\n  Packets sent:     %0d\n  Packets received: %0d\n  Matches:          %0d\n  Mismatches:       %0d",
                       packets_sent, packets_received, packet_matches, packet_mismatches), 
             UVM_NONE)

    // Final consistency checks
    if (packets_sent == 0)
      `uvm_error("SB_MISMATCH", "No packets sent")
    if (packets_received == 0)
      `uvm_error("SB_MISMATCH", "No packets received")
    if (packets_sent > 0 && (packets_sent != packets_received))
      `uvm_error("SB_MISMATCH", 
                $sformatf("Sent/Received mismatch: %0d vs %0d", packets_sent, packets_received))
    if (packet_mismatches != 0)
      `uvm_error("SB_MISMATCH", $sformatf("%0d mismatches detected", packet_mismatches))
    if (packets_sent > 0 && (packet_matches != packets_sent))
      `uvm_error("SB_MISMATCH", 
                $sformatf("Match count mismatch: %0d vs %0d", packets_sent, packet_matches))

    // Check for leftover packets
    if (input_packet_queue.size() > 0)
      `uvm_error("SB_MISMATCH", 
                $sformatf("%0d packets in input queue", input_packet_queue.size()))

    if (input_fifo.try_get(t)) 
      `uvm_error("SB_MISMATCH", 
                $sformatf("Leftover input packet:\n%s", t.convert2string()))

    if (output_fifo.try_get(t)) 
      `uvm_error("SB_MISMATCH", 
                $sformatf("Leftover output packet:\n%s", t.convert2string()))
  endfunction : extract_phase


  function bit check_xy_routing(byte x, byte y, byte ip, byte op);
    `uvm_info("SCOREBOARD", 
             $sformatf("Checking XY routing: X:%0d Y:%0d IP:%0d OP:%0d", x, y, ip, op), 
             UVM_HIGH)

    // Local destination check
    if ((hermes_pkg::X_ADDR == x) && (hermes_pkg::Y_ADDR == y)) begin
      if (op == hermes_pkg::LOCAL) begin
        return (ip != hermes_pkg::LOCAL);  // Disallow loopback
      end
      return 0;
    end

    // Horizontal routing (X-axis)
    if (hermes_pkg::X_ADDR > x) begin
      return ((op == hermes_pkg::WEST) && 
             !(ip inside {hermes_pkg::NORTH, hermes_pkg::SOUTH}));
    end
    else if (hermes_pkg::X_ADDR < x) begin
      return ((op == hermes_pkg::EAST) && 
             !(ip inside {hermes_pkg::NORTH, hermes_pkg::SOUTH}));
    end

    // Vertical routing (Y-axis)
    if (hermes_pkg::Y_ADDR < y) begin
      return (op == hermes_pkg::NORTH);
    end
    else begin
      return (op == hermes_pkg::SOUTH);
    end
  endfunction : check_xy_routing

endclass : hermes_router_scoreboard