class wb_agent extends ncsu_component#(.T(wb_transaction));

wb_configuration configuration;
wb_monitor monitor;
wb_driver driver;
ncsu_component #(T) subscribers[$];

function new(string name="", ncsu_component_base parent = null); 
  super.new(name,parent);
endfunction

// Recieves an wb_configuration object and assigns it to the internal configuration handle
function void set_configuration(wb_configuration cfg);
  configuration = cfg;
endfunction

// Building objects
virtual function void build();

//creating a driver and passing it to the configuration
  driver = new("driver", this);
  driver.set_configuration(this.configuration);
  //driver.build();

//creating a monitor and passing it to the configuration
  monitor = new("monitor", this);
  monitor.set_configuration(this.configuration);
  //monitor.build();  
endfunction

//Monitor calls to send data to environment
virtual function void nb_put(T trans);
  foreach(subscribers[i]) subscribers[i].nb_put(trans);
endfunction

//Environment calls to send data to driver
virtual task bl_put(T trans);
  driver.bl_put(trans);
endtask

virtual function void connect_subscriber(ncsu_component #(T) subscriber);
    subscribers.push_back(subscriber);
endfunction

virtual task run();
  fork
    driver.run();
    monitor.run();
  join_none
endtask

virtual task wait_for_interrupt();
  this.configuration.bus.wait_for_interrupt();
endtask
  
endclass