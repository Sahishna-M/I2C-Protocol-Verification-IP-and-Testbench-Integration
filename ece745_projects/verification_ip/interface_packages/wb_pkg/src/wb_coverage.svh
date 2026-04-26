class wb_coverage extends ncsu_component#(.T(wb_transaction));

bit [1:0] addr;
bit [7:0] data;
bit we;
bit [2:0] current_cmd;
bit [2:0] last_cmd; 

covergroup wb_cg;
option.per_instance = 1;
option.name = get_full_name();

// Coverpoint for registers (1.1-1.4 for test plan)
cp_addr: coverpoint addr{
    bins csr = {2'b00};
    bins dpr = {2'b01};
    bins cmdr = {2'b10};
    bins fsmr = {2'b11};
}

// Coverpoint for 1.5
cp_bus_id: coverpoint data[3:0] iff(we && addr == 2'b00){
    bins bus_id ={4'h0000};
}

// Coverpoint for 2.1 - 2.6
cp_cmds: coverpoint current_cmd iff(we && addr == 2'b10){
    bins wait_cmd = {3'b000}; //2.1
    bins write_cmd = {3'b001};   //2.2
    bins read_ack = {3'b010}; //2.3
    bins read_nack = {3'b011}; //2.3
    bins start = {3'b100}; //2.4
    bins stop = {3'b101}; //2.5
    bins set_bus = {3'b110}; //2.6
}

// Coverpoint for 3.1
cp_don : coverpoint data[7] iff(!we && addr == 2'b10){
    bins captured = {1'b1};
}

// Coverpoint for 3.2
cp_nack : coverpoint data[6] iff(!we && addr == 2'b10){
    bins nacked = {1'b1};
}

// Coverpoint for 3.3
cp_enable : coverpoint data[7] iff(we && addr == 2'b00){
    bins enabled = {1'b1};
    //bins disabled = {1'b0};
}

// Transition coverpoint for 4.3
cp_start_to_data: coverpoint current_cmd iff(we && addr == 2'b10){
    bins start_to_write     = (3'b100 => 3'b001); // START -> WRITE
    bins write_to_read_ack   = (3'b001 => 3'b010); // WRITE -> READ_ACK
    bins write_to_read_nack  = (3'b001 => 3'b011); // WRITE -> READ_NACK
    ignore_bins invalid     = {3'b111};
}

// Transition coverpoint for 4.4 
cp_data_to_stop: coverpoint current_cmd iff(we && addr == 2'b10){
    bins write_to_stop     = (3'b001 => 3'b101); // WRITE -> STOP
    bins read_ack_to_stop  = (3'b010 => 3'b101); // READ_ACK -> STOP
    bins read_nack_to_stop = (3'b011 => 3'b101); // READ_NACK -> STOP
    ignore_bins invalid     = {3'b111};
}
endgroup


function new(string name = "", ncsu_component_base parent = null);
super.new(name, parent);
wb_cg = new();
endfunction

virtual function void nb_put(T trans);
addr = trans.addr;
data = trans.data;
we = (trans.op == wb_transaction::WRITE);

if(we && addr == 2'b10) begin
        // CMDR write - update current_cmd and sample
        current_cmd = data[2:0];
    end
else begin
    // Non-CMDR transaction - set invalid cmd
    current_cmd = 3'b111;
end

// Always sample for all coverpoints
wb_cg.sample();

endfunction
endclass