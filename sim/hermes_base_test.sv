class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  hermes_router_env        env_h;
  hermes_router_env_config env_cfg;
  hermes_agent_config      acfg[hermes_pkg::NPORT];


  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new


  // Initialize virtual sequence handles
  function void init_vseq(hermes_base_seq vseq);
    foreach (vseq.sequencer[i]) begin
      vseq.sequencer[i] = env_h.agent_master_h[i].sequencer_h;
    end
  endfunction : init_vseq


  // Print debug information in high verbosity
  function void end_of_elaboration_phase(uvm_phase phase); 
    super.end_of_elaboration_phase(phase); 
    if (uvm_top.get_report_verbosity_level() >= UVM_HIGH) begin
      this.print(); 
      uvm_top.print_topology();
      uvm_config_db #(int)::dump(); 
    end
  endfunction : end_of_elaboration_phase


  // Create environment and configurations
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create environment configuration
    env_cfg = hermes_router_env_config::type_id::create("env_cfg", this);
    
    // Create and assign agent configurations
    foreach (acfg[i]) begin
      acfg[i] = hermes_agent_config::type_id::create($sformatf("acfg[%0d]", i), this);
      env_cfg.agent_cfg[i] = acfg[i];
    end
  endfunction : build_phase

endclass : base_test