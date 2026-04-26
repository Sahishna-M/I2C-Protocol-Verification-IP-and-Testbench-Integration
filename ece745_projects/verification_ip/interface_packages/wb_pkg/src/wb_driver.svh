class wb_driver extends ncsu_component#(.T(wb_transaction));

`ncsu_register_object(wb_driver)

wb_configuration configuration;

function new(string name="", ncsu_component_base  parent=null); 
    super.new(name,parent);
endfunction

// Recieves an wb_configuration object and assigns it to the internal configuration handle
function void set_configuration(wb_configuration cfg);
configuration = cfg;
endfunction

//The driver reads or writes based on the input 
virtual task bl_put(T trans);

if(trans.op == wb_transaction::WRITE)
begin
    //i2c driver contains a handle to i2c_configuration object
    configuration.bus.master_write(trans.addr, trans.data);
end

else
begin
    bit [7:0] read;

    configuration.bus.master_read(trans.addr, read);
    trans.data = read;
end
endtask

virtual task run();
    configuration.bus.wait_for_reset();
endtask

endclass