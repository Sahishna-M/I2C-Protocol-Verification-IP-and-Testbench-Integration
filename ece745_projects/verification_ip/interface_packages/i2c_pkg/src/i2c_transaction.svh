class i2c_transaction extends ncsu_transaction;
`ncsu_register_object(i2c_transaction)

//i2c specific data
bit [6:0]addr;
bit [7:0]data[];
bit ack;
bit stop_bit;
typedef enum {WRITE, READ} op_type;
op_type op;
bit transfer_complete;

function new(string name=""); 
    super.new(name);       // sets ID for the transaction, hence calls ncsu_transaction constructor
endfunction

virtual function string convert2string();
    return $sformatf("Addr: 0x%h Data: %p Op: %s", addr, data, op.name());
endfunction

// Compare method used by scoreboard to check if predicted output and actual output are matching
virtual function bit compare(i2c_transaction expected);

return((this.addr == expected.addr) &&
    (this.data == expected.data) &&
    (this.op == expected.op));

endfunction

// Deep copy to let driver and predictor work on their own versions
virtual function void copy(i2c_transaction copied);
copied.name = this.name;
copied.addr = this.addr;
copied.data = this.data;
copied.op = this.op;
copied.ack = this.ack;
copied.stop_bit = this.stop_bit;

endfunction
endclass