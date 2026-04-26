class i2c_configuration extends ncsu_configuration;

v_i2c_if bus;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return $sformatf("name: %s ",name);
  endfunction

endclass