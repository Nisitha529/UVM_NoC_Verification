class sequential_test extends base_test;
  `uvm_component_utils(sequential_test)

  // Configure via command line: +uvm_set_config_int=*,repeat_sequence,3
  int repeat_sequence;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Randomize agent configuration 
    foreach (acfg[i]) begin
      if (!acfg[i].randomize() with { 
        // cycle2send == 1;
        cycle2flit == 0;
        cred_distrib == 8;
      }) 
      `uvm_error("test", "Invalid agent cfg randomization")
    end

    // Change env/agent configuration before sending to config_db
    if (!uvm_config_db #(uvm_bitstream_t)::get(
          null, "", "repeat_sequence", repeat_sequence
        )
    ) 
      repeat_sequence = 10;  // Default value

    // Set environment configuration
    uvm_config_db#(hermes_router_env_config)::set(
      null, "uvm_test_top.env", "config", env_cfg
    );
    env_h = hermes_router_env::type_id::create("env", this);
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    repeat_seq seq;
    hermes_router_seq_config seq_cfg;

    phase.raise_objection(this);

    for (int i = 0; i < hermes_pkg::NPORT; i++) begin
      repeat (repeat_sequence) begin
        // Create and randomize sequence configuration
        seq_cfg = hermes_router_seq_config::type_id::create("seq_cfg");
        if (!seq_cfg.randomize() with { 
              npackets == 1;        // Packets per sequencer
              port     == i;        // Input port
              p_size   == hermes_packet_t::SMALL;  // Small packets only
            }
        ) 
        `uvm_error("test", "Invalid cfg randomization")
        
        uvm_config_db#(hermes_router_seq_config)::set(
          null, "", "config", seq_cfg
        );

        // Create and initialize sequence
        seq = repeat_seq::type_id::create("seq");
        init_vseq(seq);

        if (!seq.randomize())
          `uvm_error("test", "Invalid seq randomization")

        seq.start(seq.sequencer[seq_cfg.port]);
      end
    end

    phase.drop_objection(this);
  endtask : run_phase

endclass : sequential_test