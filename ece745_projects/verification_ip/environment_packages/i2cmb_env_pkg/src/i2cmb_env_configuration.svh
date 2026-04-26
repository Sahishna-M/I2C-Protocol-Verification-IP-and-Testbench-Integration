class i2cmb_env_configuration extends ncsu_configuration;

i2c_configuration i2c_cfg;
wb_configuration wb_cfg;

v_wb_if wb_bus;
v_i2c_if i2c_bus;

function new(string name = "");
    super.new(name);
    i2c_cfg = new();
    wb_cfg = new();
endfunction

virtual function void map_objects();
    i2c_cfg.bus = this.i2c_bus;
    wb_cfg.bus = this.wb_bus;
endfunction

endclass