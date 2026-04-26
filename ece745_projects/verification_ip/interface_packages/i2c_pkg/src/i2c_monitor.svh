class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

i2c_configuration configuration;
T monitored_trans;
ncsu_component #(T) parent;

function new(string name="", ncsu_component #(T) parent=null); 
    super.new(name,parent);
    this.parent = parent;
endfunction

// Recieves an i2c_configuration object and assigns it to the internal configuration handle
function void set_configuration(i2c_configuration cfg);
configuration = cfg;
endfunction

virtual task run();
bit [6:0] addr;
bit op;
bit [7:0] data[];
bit addr_ack;
bit stop_seen;
forever 
begin
    configuration.bus.monitor(addr,op, data, addr_ack, stop_seen);

    monitored_trans = new("monitored_trans");    
    monitored_trans.data = data;
    monitored_trans.addr = addr;
    monitored_trans.ack = addr_ack;
    monitored_trans.stop_bit = stop_seen;

    if (op == 1'b1)  monitored_trans.op = i2c_transaction::READ;
        
    else   monitored_trans.op = i2c_transaction::WRITE;
    
    parent.nb_put(monitored_trans);    
end

endtask
endclass