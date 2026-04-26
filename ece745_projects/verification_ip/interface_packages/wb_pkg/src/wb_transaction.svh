class wb_transaction extends ncsu_transaction;
`ncsu_register_object(wb_transaction)

//wb specific data
bit [1:0]addr;
bit [7:0]data;
typedef enum {WRITE, READ} op_type;
op_type op;

function new(string name=""); 
    super.new(name);       // sets ID for the transaction, hence calls ncsu_transaction constructor
endfunction

virtual function string convert2string();
    return {super.convert2string(),
    $sformatf("Addr: 0x%x Data: 0x%x Op: %s", addr, data, op.name())};
endfunction

// Compare method used by scoreboard to check if predicted output and actual output are matching
virtual function bit compare(wb_transaction expected);

return((this.addr == expected.addr) &&
    (this.data == expected.data) &&
    (this.op == expected.op));

endfunction

// Deep copy to let driver and predictor work on their own versions
virtual function void copy(wb_transaction copied);
copied.name = this.name;
copied.addr = this.addr;
copied.data = this.data;
copied.op = this.op;

endfunction
endclass