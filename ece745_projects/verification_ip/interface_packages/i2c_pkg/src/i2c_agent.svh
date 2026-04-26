class i2c_agent extends ncsu_component#(.T(i2c_transaction));

i2c_configuration configuration;
i2c_monitor monitor;
i2c_driver driver;
ncsu_component #(T) subscribers[$];

function new(string name="", ncsu_component_base parent = null); 
  super.new(name,parent);
endfunction

// Recieves an i2c_configuration object and assigns it to the internal configuration handle
function void set_configuration(i2c_configuration cfg);
  configuration = cfg;
endfunction

// Building objects
virtual function void build();

//creating a driver and passing it to the configuration
  driver = new("driver", this);
  driver.set_configuration(configuration);
  //driver.build();

//creating a monitor and passing it to the configuration
  monitor = new("monitor", this);
  monitor.set_configuration(configuration);
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
  
endclass