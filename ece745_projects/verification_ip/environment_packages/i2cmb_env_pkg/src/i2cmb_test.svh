class i2cmb_test extends ncsu_component;
`ncsu_register_object(i2cmb_test)

i2cmb_env_configuration cfg;
i2cmb_environment env;
i2cmb_generator gen;

function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
endfunction 

virtual function void build();
    cfg = new("cfg");

    if (!ncsu_config_db#(v_wb_if)::get("wb_interface", cfg.wb_bus)) 
        $fatal(1, "TEST: Failed to get wb_bus from config_db");

    if (!ncsu_config_db#(v_i2c_if)::get("i2c_interface", cfg.i2c_bus)) 
        $fatal(1, "TEST: Failed to get i2c_bus from config_db");

    env = new("env", this);
    env.set_configuration(cfg);
    env.build();
    
    gen = new("gen", this);
    gen.set_wb_agent(env.get_wb_agent());
    gen.set_i2c_agent(env.get_i2c_agent());
endfunction

virtual task run();
    env.run();
    gen.run();
endtask

endclass