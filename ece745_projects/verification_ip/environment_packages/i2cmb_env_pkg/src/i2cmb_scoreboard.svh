class i2cmb_scoreboard extends ncsu_component#(.T(i2c_transaction));

ncsu_configuration configuration;
function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
endfunction

function void set_configuration(ncsu_configuration cfg);
  configuration = cfg;
endfunction

i2c_transaction expected_trans;

virtual function void nb_transport(input T input_trans, output T output_trans);        
    this.expected_trans = input_trans; 
endfunction

virtual function void nb_put(T trans);

    //$display("ENTERED SCOREBOARD");

    i2c_transaction actual_data;
    i2c_transaction expected_data;
    if (trans == null) 
    begin        
    end 
    else 
    begin
        $display("Scoreboard: %s",trans.convert2string());
    end

    /*if(expected_trans.size() == 0)
    begin
        $display("ERROR: Monitor saw a byte on the wires that the CPU never sent!!");
    end
    else
    begin
        expected_data = expected_trans.pop_front();
        if(trans.compare(expected_data))
        begin
            $display("SUCCESS!! Data: 0x%x Address: 0x%x", trans.data, trans.addr);
        end
        else
        begin
            $display("MISMATCH!!!");
            $display("Actual: %s", trans.convert2string());
            $display("Expected: %s", expected_data.convert2string());
        end
    end*/
endfunction

endclass