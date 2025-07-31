class hermes_agent_config extends uvm_object;
  `uvm_object_utils(hermes_agent_config)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit master_driver_enabled = 1;

  rand bit [3:0] cred_distrib;
  bit [3:0] cred_dist[11] = {0, 5, 5, 1, 1, 1, 1, 1, 1, 5, 30};  // Distribution weights

  constraint c_cred_distrib {
    cred_distrib dist {
      0  := cred_dist[0],
      1  := cred_dist[1],
      2  := cred_dist[2],
      3  := cred_dist[3],
      4  := cred_dist[4],
      5  := cred_dist[5],
      6  := cred_dist[6],
      7  := cred_dist[7],
      8  := cred_dist[8],
      9  := cred_dist[9],
      10 := cred_dist[10]
    };
    !(cred_distrib inside {[11:15]});
  }

  //==========================
  // Hermes driver timing knobs
  //==========================
  // Cycles to wait before sending packet
  rand bit [3:0] cycle2send;
  bit [3:0] cycle2send_dist[16] = {10,10,10,1,1,1,1,1,1,1,1,1,1,1,1,1};

  // Cycles between flits
  rand bit [3:0] cycle2flit;
  bit [3:0] cycle2flit_dist[16] = {15,5,5,1,1,1,1,1,1,1,1,1,1,1,1,1};

  constraint c_cycle2send {
    cycle2send dist {
      0  := cycle2send_dist[0],
      1  := cycle2send_dist[1],
      2  := cycle2send_dist[2],
      3  := cycle2send_dist[3],
      4  := cycle2send_dist[4],
      5  := cycle2send_dist[5],
      6  := cycle2send_dist[6],
      7  := cycle2send_dist[7],
      8  := cycle2send_dist[8],
      9  := cycle2send_dist[9],
      10 := cycle2send_dist[10],
      11 := cycle2send_dist[11],
      12 := cycle2send_dist[12],
      13 := cycle2send_dist[13],
      14 := cycle2send_dist[14],
      15 := cycle2send_dist[15]
    };
  }

  constraint c_cycle2flit {
    cycle2flit dist {
      0  := cycle2flit_dist[0],
      1  := cycle2flit_dist[1],
      2  := cycle2flit_dist[2],
      3  := cycle2flit_dist[3],
      4  := cycle2flit_dist[4],
      5  := cycle2flit_dist[5],
      6  := cycle2flit_dist[6],
      7  := cycle2flit_dist[7],
      8  := cycle2flit_dist[8],
      9  := cycle2flit_dist[9],
      10 := cycle2flit_dist[10],
      11 := cycle2flit_dist[11],
      12 := cycle2flit_dist[12],
      13 := cycle2flit_dist[13],
      14 := cycle2flit_dist[14],
      15 := cycle2flit_dist[15]
    };
  }


  function new(string name = "");
    super.new(name);
  endfunction : new


  function void do_copy(uvm_object rhs);
    hermes_agent_config that;
    
    if (!$cast(that, rhs)) begin
      `uvm_error("DO_COPY", "RHS is not a hermes_agent_config")
      return;
    end
    
    super.do_copy(rhs);
    this.cred_distrib    = that.cred_distrib;
    this.cred_dist       = that.cred_dist;
    this.cycle2send      = that.cycle2send;
    this.cycle2send_dist = that.cycle2send_dist;
    this.cycle2flit      = that.cycle2flit;
    this.cycle2flit_dist = that.cycle2flit_dist;
  endfunction : do_copy


  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf("\n  cred_distrib : %0d", cred_distrib)};
    s = {s, $sformatf("\n  cycle2send   : %0d", cycle2send)};
    s = {s, $sformatf("\n  cycle2flit   : %0d", cycle2flit)};
    return s;
  endfunction : convert2string

endclass : hermes_agent_config