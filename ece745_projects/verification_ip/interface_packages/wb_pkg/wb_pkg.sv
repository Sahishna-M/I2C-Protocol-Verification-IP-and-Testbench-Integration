package wb_pkg;
    import ncsu_pkg::*; // Import base classes to allow for extension 

    `include "ncsu_macros.svh"

    parameter int WB_ADDR_WIDTH = 2;
    parameter int WB_DATA_WIDTH = 8;

    typedef virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) v_wb_if;
    
    // Include the class header files in an order that respects dependencies

    //typedef enum bit {wb_write = 1'b0, wb_read = 1'b1  } wb_op_t;

    `include "src/wb_transaction.svh"
    `include "src/wb_configuration.svh"
    `include "src/wb_driver.svh"
    `include "src/wb_monitor.svh"
    `include "src/wb_agent.svh"
    `include "src/wb_coverage.svh"
endpackage