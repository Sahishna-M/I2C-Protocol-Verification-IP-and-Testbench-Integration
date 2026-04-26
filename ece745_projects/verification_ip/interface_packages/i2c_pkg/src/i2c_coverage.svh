class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

bit [6:0] addr;
bit start_cond;
bit stop_cond;
bit repeated_start;
bit last_trans = 0;
bit nack_bit;

covergroup i2c_cg;
option.per_instance = 1;
option.name = get_full_name();

// Coverpoint for 3.4
cp_start: coverpoint start_cond{
    bins start_stop = {1'b1};
}

// Coverpoint for 3.5
cp_stop: coverpoint stop_cond{
    bins start_stop = {1'b1};
}

// Coverpoint for 4.1
cp_repeated_start: coverpoint repeated_start{
    bins start_stop = {1'b1};
}

// Coverpoint and cross for 4.2
cp_ack: coverpoint nack_bit{
    bins acked  = {1'b0}; // Present
    bins nacked = {1'b1}; // Absent 

}
cp_slave_addr: coverpoint addr{
    bins valid_range   = { [7'h01:7'h7E] };  // ensures that the exact adress that is going in seen
}

cx_slave_nack: cross cp_slave_addr, cp_ack;

endgroup


function new(string name = "", ncsu_component_base parent = null);
super.new(name, parent);
i2c_cg = new();
endfunction

virtual function void nb_put(T trans);
this.addr = trans.addr;
this.nack_bit = trans.ack;
this.start_cond = 1'b1;


// repeated start
this.repeated_start = last_trans;

// stop 
this.stop_cond = trans.stop_bit;

last_trans = !this.stop_cond;

i2c_cg.sample();
endfunction

endclass