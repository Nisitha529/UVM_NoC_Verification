`timescale 1ns / 1ps

module top;
  import uvm_pkg::*;

  // Clock and reset signals
  bit clock;
  bit reset = 1;

  // Clock generator (50MHz -> 20ns period)
  always #10 clock = ~clock;

  // Reset generator
  initial begin : reset_gen
    repeat (5) @(posedge clock);
    reset = 0;
  end

  // Interface instances
  hermes_if master_if[hermes_pkg::NPORT](clock, reset);
  hermes_if slave_if[hermes_pkg::NPORT](clock, reset);

  // Configuration: Pass interfaces to UVM agents
  generate
    for (genvar i = 0; i < hermes_pkg::NPORT; i++) begin : if_config
      initial begin
        // Master interface (input to DUT)
        uvm_config_db#(virtual hermes_if)::set(
          null, 
          $sformatf("uvm_test_top.env.agent_master_%0d", i),
          "if",
          master_if[i]
        );
        
        // Slave interface (output from DUT)
        uvm_config_db#(virtual hermes_if)::set(
          null, 
          $sformatf("uvm_test_top.env.agent_slave_%0d", i),
          "if",
          slave_if[i]
        );
      end
    end
  endgenerate

  top_routercc dut1 (
    .clock (clock),
    .reset (reset),
    .din   (master_if),  // Input interfaces
    .dout  (slave_if)    // Output interfaces
  );

  // Test Setup and Execution
  initial begin : test_control
    // Enable transaction recording
    uvm_config_db#(int)::set(null, "*", "recording_detail", 1);
    
    // Start UVM test (specified with +UVM_TESTNAME)
    run_test();
  end

endmodule : top