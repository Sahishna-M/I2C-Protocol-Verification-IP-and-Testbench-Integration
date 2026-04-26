class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

i2cmb_scoreboard scoreboard;
i2cmb_env_configuration env_configuration;
i2c_transaction predicted_trans;
bit [7:0] captured_data;        // To hold data from DPR writes
bit is_start;
bit [6:0] current_addr;
i2c_op_t current_op;

function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
endfunction

function void set_configuration(i2cmb_env_configuration cfg);
  env_configuration = cfg;
endfunction

virtual function void set_scoreboard(i2cmb_scoreboard scoreboard);
    this.scoreboard = scoreboard;
endfunction

virtual function void nb_put(T trans);

    /*if(trans.we == 1)
    begin
        // DPR -> save the byte
        if(trans.addr == 2'b01) 
        begin
            captured_data = trans.data;
        end

        // CSR
        else if(trans.addr == 2'b10)
        begin
            case(trans.data[2:0])   // CMD of CMDR 

            3'b100: begin   //Start
                is_start = 1;
            end

            3'b001: begin   // Writing data
                predicted_trans = new("predicted_trans");

                if(is_start)
                begin
                    // capturing address and R/W bit which comes in the first byte
                    current_addr = captured_data[7:1];
                    current_op = (captured_data[0] == 0) ? i2c_transaction:: WRITE : i2c_transaction:: READ;
                    is_start = 0; // next byte will be data
                end

                // Putting the byte in the transaction
                predicted_trans.addr = current_addr;
                predicted_trans.op = current_op;
                predicted_trans.data = captured_data;

                // Sending to scoreboard
                scoreboard.nb_transport(trans, predicted_trans);
            end

            3'b101: begin   //Stop
                is_start = 0;
            end

            endcase
        end
    end*/    

endfunction
endclass