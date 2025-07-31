class parallel_test extends base_test;
  `uvm_component_utils(parallel_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Randomize agent configuration
    /*
    foreach (acfg[i]) begin
      if (!acfg[i].randomize()) 
        `uvm_error("test", "Invalid agent cfg randomization"); 
    end
    */

    // In this test, all agents have the same behavior
    foreach (acfg[i]) begin
      if (!acfg[i].randomize() with { 
        cycle2send == 1;   // New packet sent 1 cycle after last
        cycle2flit == 0;   // New flit every cycle after transaction starts
        cred_distrib == 5;  // Slave ports have 50% availability
      }) 
      `uvm_error("test", "Invalid agent cfg randomization")
    end

    // Set environment configuration
    uvm_config_db#(hermes_router_env_config)::set(
      null, "uvm_test_top.env", "config", env_cfg
    );
    env_h = hermes_router_env::type_id::create("env", this);
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    parallel_seq seq = parallel_seq::type_id::create("seq");
    hermes_router_seq_config cfg[hermes_pkg::NPORT];

    foreach (cfg[i]) begin
      cfg[i] = hermes_router_seq_config::type_id::create($sformatf("seq_cfg[%0d]", i));
      if (!cfg[i].randomize() with { 
        npackets == 5;                  // Packets per sequencer
        port      == i;                 // Port assignment
        p_size    == hermes_packet_t::SMALL;  // Only small packets
      }) 
      `uvm_error("test", "Invalid cfg randomization")
      
      uvm_config_db#(hermes_router_seq_config)::set(
        null, 
        $sformatf("uvm_test_top.env.agent_master_%0d.sequencer", i),
        "config",
        cfg[i]
      );
    end

    phase.raise_objection(this);
    init_vseq(seq);  // Initialize virtual sequence
    seq.start(null);  // Start virtual sequence
    phase.phase_done.set_drain_time(this, 100ns);  // Allow drain time
    phase.drop_objection(this);
  endtask : run_phase

endclass : parallel_test