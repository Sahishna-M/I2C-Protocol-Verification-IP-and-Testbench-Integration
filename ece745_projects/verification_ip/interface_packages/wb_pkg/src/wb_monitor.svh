class wb_monitor extends ncsu_component#(.T(wb_transaction));

wb_configuration configuration;
T monitored_trans;
ncsu_component #(T) parent;

function new(string name="", ncsu_component #(T) parent=null); 
    super.new(name,parent);
    this.parent = parent;
endfunction

// Recieves an wb_configuration object and assigns it to the internal configuration handle
function void set_configuration(wb_configuration cfg);
configuration = cfg;
endfunction

virtual task run();
bit [1:0] addr;
bit [7:0] data;
bit we;  //write enable

forever 
begin
    configuration.bus.master_monitor(addr, data, we);
    monitored_trans = new("monitored_trans");    
    monitored_trans.data = data;
    monitored_trans.addr = addr;
    if(we) monitored_trans.op = wb_transaction::WRITE;
    else monitored_trans.op = wb_transaction::READ;
    parent.nb_put(monitored_trans);
end

endtask
endclass