class random_test extends base_test;
  `uvm_component_utils(random_test)

  int repeat_sequence = 10;  // Default value, configurable via command line


  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Configure agent behavior
    foreach (acfg[i]) begin
      if (!acfg[i].randomize() with { 
        cycle2send == 1;
        cycle2flit == 0;
      }) begin
        `uvm_error("TEST", "Agent configuration randomization failed")
      end
    end

    // Get sequence repeat count from command line
    if (!uvm_config_db #(uvm_bitstream_t)::get(null, "", "repeat_sequence", repeat_sequence))
      `uvm_info("TEST", $sformatf("Using default repeat_sequence: %0d", repeat_sequence), UVM_MEDIUM)

    // Set environment configuration and create environment
    uvm_config_db#(hermes_router_env_config)::set(null, "uvm_test_top.env", "config", env_cfg);
    env_h = hermes_router_env::type_id::create("env", this);
  endfunction : build_phase


  task run_phase(uvm_phase phase);
    repeat_seq seq;
    hermes_router_seq_config seq_cfg;

    phase.raise_objection(this, "Starting test sequence");

    repeat (repeat_sequence) begin
      // Create and configure sequence
      seq_cfg = hermes_router_seq_config::type_id::create("seq_cfg");
      if (!seq_cfg.randomize() with { 
          npackets == 1; 
          p_size == hermes_packet_t::SMALL;
        }) begin
        `uvm_error("TEST", "Sequence configuration randomization failed")
      end
      
      uvm_config_db#(hermes_router_seq_config)::set(null, "", "config", seq_cfg);

      // Create and start sequence
      seq = repeat_seq::type_id::create("seq");
      init_vseq(seq);
      
      if (!seq.randomize()) 
        `uvm_error("TEST", "Sequence randomization failed")
      
      seq.start(seq.sequencer[seq_cfg.port]);
    end

    phase.drop_objection(this, "Test sequence complete");
  endtask : run_phase

endclass : random_test