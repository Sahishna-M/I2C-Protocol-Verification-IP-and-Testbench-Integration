class i2c_driver extends ncsu_component#(.T(i2c_transaction));

`ncsu_register_object(i2c_driver)

i2c_configuration configuration;

function new(string name="", ncsu_component_base  parent=null); 
    super.new(name,parent);
endfunction

// Recieves an i2c_configuration object and assigns it to the internal configuration handle
function void set_configuration(i2c_configuration cfg);
configuration = cfg;
endfunction

//The driver reads or writes based on the input 
virtual task bl_put(T trans);

bit op;
bit [7:0] captured_data[];            // to hold data from tasks
bit transfer_complete;
// Wait for START
configuration.bus.wait_for_i2c_transfer(op, captured_data);

trans.op = (op == 1'b0) ? i2c_transaction::WRITE : i2c_transaction::READ;

if(trans.op == i2c_transaction::WRITE)
begin
    trans.data = captured_data;
end

else
begin
    //execute read condition
    configuration.bus.provide_read_data(trans.data,transfer_complete);
    trans.transfer_complete = transfer_complete;
end
endtask

endclass