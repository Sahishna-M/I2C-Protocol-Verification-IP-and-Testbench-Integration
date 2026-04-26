class i2cmb_environment extends ncsu_component;

i2cmb_env_configuration configuration;
i2c_agent i2c_agent_handle;
wb_agent wb_agent_handle;
i2c_coverage i2c_cov;
wb_coverage wb_cov;
i2cmb_predictor predictor;
i2cmb_scoreboard scoreboard;

function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
endfunction

function void set_configuration(i2cmb_env_configuration cfg);
  configuration = cfg;
  configuration.map_objects();
endfunction

virtual function void build();
    i2c_agent_handle = new("i2c_agent_handle", this);
    i2c_agent_handle.set_configuration(configuration.i2c_cfg);
    i2c_agent_handle.build();

    wb_agent_handle = new("wb_agent_handle", this);
    wb_agent_handle.set_configuration(configuration.wb_cfg);
    wb_agent_handle.build();

    i2c_cov = new("i2c_cov", this);
    wb_cov = new("wb_cov", this);

    predictor = new("predictor", this);
    predictor.set_configuration(configuration);
    predictor.build();

    scoreboard = new("scoreboard", this);
    scoreboard.set_configuration(configuration);
    scoreboard.build();

    // Connecting subscribers and scoreboard
    i2c_agent_handle.connect_subscriber(i2c_cov);
    wb_agent_handle.connect_subscriber(wb_cov);
    wb_agent_handle.connect_subscriber(predictor);
    predictor.set_scoreboard(scoreboard);
    i2c_agent_handle.connect_subscriber(scoreboard);
endfunction

function wb_agent get_wb_agent();
    return wb_agent_handle;
endfunction

function i2c_agent get_i2c_agent();
    return i2c_agent_handle;
endfunction

virtual task run();
fork
    wb_agent_handle.run();
    i2c_agent_handle.run();
join_none
endtask

endclass