class wb_configuration extends ncsu_configuration;

v_wb_if bus;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return $sformatf("name: %s ",name);
  endfunction

endclass