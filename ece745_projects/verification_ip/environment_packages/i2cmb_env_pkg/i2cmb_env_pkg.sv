package i2cmb_env_pkg;
    import ncsu_pkg::*; 
    import wb_pkg::*;
    import i2c_pkg::*;

    `include "ncsu_macros.svh"

    typedef enum bit {i2c_write = 1'b0, i2c_read = 1'b1  } i2c_op_t;
    
    `include "src/i2cmb_env_configuration.svh"
    `include "src/i2cmb_coverage.svh"
    
    `include "src/i2cmb_scoreboard.svh"
    `include "src/i2cmb_generator.svh"

    `include "src/i2cmb_predictor.svh"

    `include "src/i2cmb_environment.svh"

    `include "src/i2cmb_test.svh"
 
endpackage