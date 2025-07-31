class hermes_monitor extends uvm_monitor;
  `uvm_component_utils(hermes_monitor)

  uvm_analysis_port #(hermes_packet_t) aport;  // Output to scoreboard
  virtual hermes_if dut_vi;
  bit [3:0] port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new


  function void build_phase(uvm_phase phase);
    aport = new("aport", this); 

    // Print config_db if in high verbosity
    if (uvm_top.get_report_verbosity_level() >= UVM_HIGH)
      print_config();

    // Get configuration
    if (!uvm_config_db #(bit [3:0])::get(this, "", "port", port))
      `uvm_fatal("MONITOR", "Port configuration not found")
    `uvm_info("MONITOR", $sformatf("Port number: %0d", port), UVM_HIGH)

    if (!uvm_config_db #(virtual hermes_if)::get(this, "", "if", dut_vi))
      `uvm_fatal("MONITOR", "Interface not found")

    `uvm_info("MONITOR", "Monitor build complete", UVM_HIGH)
  endfunction : build_phase


  task run_phase(uvm_phase phase);
    hermes_packet_t tx;
    int             i, size;
    
    // Wait for initial reset sequence
    @(negedge dut_vi.reset);
    @(negedge dut_vi.clock);

    forever begin
      tx = hermes_packet_t::type_id::create("tx");
      `uvm_info("MONITOR", $sformatf("%s: Starting packet capture", get_full_name()), UVM_HIGH)
      
      // Capture header
      @(negedge dut_vi.clock iff (dut_vi.credit && dut_vi.avail));
      tx.set_header(dut_vi.data);
      `uvm_info("MONITOR", 
               $sformatf("%s: Header captured: 0x%h", get_full_name(), dut_vi.data), 
               UVM_HIGH)
      
      // Capture packet size
      @(negedge dut_vi.clock iff (dut_vi.credit && dut_vi.avail));
      size = dut_vi.data;
      `uvm_info("MONITOR", 
               $sformatf("%s: Payload size: %0d", get_full_name(), size), 
               UVM_HIGH)

      // Allocate and capture payload
      tx.payload = new[size];
      i = 0;
      while (i < size) begin
        @(negedge dut_vi.clock iff (dut_vi.credit && dut_vi.avail));
        tx.payload[i] = dut_vi.data;
        `uvm_info("MONITOR", 
                 $sformatf("%s: Flit %0d: 0x%h", get_full_name(), i, tx.payload[i]), 
                 UVM_HIGH)
        i++;
      end
      `uvm_info("MONITOR", 
               $sformatf("%s: Payload captured", get_full_name()), 
               UVM_HIGH)

      // Set output port and send packet
      tx.oport = port;
      `uvm_info("MONITOR", tx.convert2string(), UVM_MEDIUM)
      aport.write(tx);
    end
  endtask : run_phase

endclass : hermes_monitor