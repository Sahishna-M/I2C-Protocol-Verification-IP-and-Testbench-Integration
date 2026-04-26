class i2cmb_generator extends ncsu_component #(.T(i2c_transaction)); 

wb_agent wb_agent_h; // Wishbone agent handle
i2c_agent i2c_agent_h;  //i2c_agent handle


i2cmb_env_configuration configuration;

function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
endfunction

// To give the generator a handle to the wishbone agent
function void set_wb_agent(wb_agent wb_agent_h);
    this.wb_agent_h = wb_agent_h;
endfunction

// To give the generator a handle to the i2c agent
function void set_i2c_agent(i2c_agent i2c_agent_h);
    this.i2c_agent_h = i2c_agent_h;
endfunction

// setting configuration
function void set_configuration(i2cmb_env_configuration cfg);
  this.configuration = cfg;
endfunction

// ************************************************************* HELPER TASKS ********************************************************************
// task to do wishbone write and wait for completion
task wb_write(bit [2:0] addr, bit [7:0]data);

  wb_transaction wb_trans;
  wb_trans = new("wb_trans");
  wb_trans.op = wb_transaction::WRITE;
  wb_trans.addr = addr;
  wb_trans.data = data;
  wb_agent_h.bl_put(wb_trans);

  if (addr == 32'h2 && data != 8'h07)
  begin
    wb_transaction read_don;
    read_don = new("read_don");
    read_don.op = wb_transaction::READ;
    read_don.addr = 32'h2;

    do begin
      wb_agent_h.bl_put(read_don);
    end while(read_don.data[7:4] == 4'b0000);
  end
endtask

// task to do wishbone read
task wb_read(input bit [2:0] addr, output bit [7:0]data);

  wb_transaction wb_trans;
  wb_trans = new("wb_trans");
  wb_trans.op = wb_transaction::READ;
  wb_trans.addr = addr;
  wb_trans.data = data;
  wb_agent_h.bl_put(wb_trans);

  data = wb_trans.data;
  
endtask
// ************************************************************* TASKS FOR TEST CASE 1 (PROJ2) ********************************************************************
task i2c_write(input bit[6:0] addr);
  bit [7:0] i;
  // Start condition is achieved by writing 0x04 to the CMDR
  wb_write(2'h2, 8'h04);

  // Writing the slave address to the DPR, with the write bit (0) at the end    
  wb_write(2'h1, {addr, 1'b0});

  // Giving the Write command by writing 0x01 to the CMDR
  wb_write(2'h2, 8'h01); 

  // 32 writes
  for(i = 0; i < 32; i = i + 1)
  begin
    // Writing data to the DPR and giving the Write command for each byte of data
    wb_write(2'h1, i); 
    wb_write(2'h2, 8'h01);
  end
   //stop
   wb_write(2'h2, 8'h05);
endtask

// ************************************************************* TASKS FOR TEST CASE 2 (PROJ2) ********************************************************************

task i2c_read(input bit [6:0]addr, input bit[7:0] start_data = 8'd100, input int num_bytes = 32);
  bit [7:0] i;
  bit [7:0] expected_data [];
  bit [7:0] read_data [];
  i2c_transaction data_i2c;

  expected_data = new[num_bytes];
  read_data = new[num_bytes];

  // Data that I want the slave to send back
  for(int j = 0; j < num_bytes; j = j + 1)
  begin
    expected_data[j] = start_data + j;
  end

  // passing this data to I2C agent
  data_i2c = new("data_i2c");
  data_i2c.data = expected_data;
  data_i2c.addr = addr;
  data_i2c.op = i2c_transaction::READ;

  fork
    i2c_agent_h.bl_put(data_i2c);
  join_none

  // Start condition is achieved by writing 0x04 to the CMDR
  wb_write(2'h2, 8'h04);

  // Writing the slave address to the DPR, with the write bit (0) at the end    
  wb_write(2'h1, {addr, 1'b1});

  // Giving the Write command by writing 0x01 to the CMDR
  wb_write(2'h2, 8'h01); 
 
  for(i = 0; i < num_bytes; i = i + 1)
  begin
    if(i == num_bytes - 1)
    wb_write(2'h2, 8'h03); // Read command with NACK bit set
    
    else
    wb_write(2'h2, 8'h02); // Read command with ACK bit set
   
   wb_read(2'h1, read_data[i]); // Reading the data byte from the DPR
  end
  wb_write(2'h2, 8'h05);

endtask

// ************************************************************* TASKS FOR TEST CASE 3 (PROJ2) ********************************************************************

task i2c_alternate(input [6:0]addr);
  bit [7:0]write_data;
  bit [7:0]read_data;
  bit [7:0]expected_read;   //Data that slave must send to read
  i2c_transaction data_i2c;

  write_data = 8'd64;
  expected_read = 8'd63;

    for(int i = 0; i < 64; i = i + 1)
    begin
        // Write data to the slave
        wb_write(2'h2, 8'h04); // Start condition
        wb_write(2'h1, {addr, 1'b0}); // Slave address with write bit
        wb_write(2'h2, 8'h01); // Write command
        wb_write(2'h1, write_data); //data
        wb_write(2'h2, 8'h01); // Write command
        wb_write(2'h2, 8'h05); // Stop condition

        write_data = write_data + 1'd1; 

        // passing this data to I2C agent
        data_i2c = new("data_i2c");
        data_i2c.addr = addr;
        data_i2c.op = i2c_transaction::READ;
        // allocating memory to dynamic array
        data_i2c.data = new[1];
        data_i2c.data[0] = expected_read;

        fork
          i2c_agent_h.bl_put(data_i2c);
        join_none

        // Read data from the slave
        wb_write(2'h2, 8'h04); // Start condition        
        wb_write(2'h1, {addr, 1'b1}); // Slave address with read bit
        wb_write(2'h2, 8'h01); // Read command
        wb_write(2'h2, 8'h03); // Read command with NACK bit set
        wb_read(2'h1, read_data); // Read data from the DPR
        wb_write(2'h2, 8'h05); // Stop condition

        expected_read = expected_read - 1'd1;
    end
endtask

// ************************************************************* TASKS FOR COVERAGE ********************************************************************

// ************************************************************* SECTION 1 **************************************************************************
task coverage_section_1();
  bit [7:0]temp;
  bit [7:0] rand_data;

  // --- 1.5 Set Bus Id ---
  // Disable the core (EN=0) to clear internal FS
  wb_write(2'h0, 8'h00);

  // Setting EN bit
  wb_write(2'h0, 8'hC0);

  for(int i = 0; i < 16; i++)
  begin
    wb_write(2'h1, i[7:0]); // writing target bus ID
    wb_write(2'h2, 8'h06);  // Set_bus command
    wb_read(2'h0, temp);    // Reading the CSR to see if the specific Bus ID was set
  end
  wb_read(2'h0, temp);

  // --- 1.1 - 1.4  --- 
  for(int i = 0; i < 4; i++)
  begin
    if(i == 2)  wb_read(i, temp);    // 8'h00 at address 2 is WAIT, so we only read
    else begin
      rand_data = $urandom_range(255, 0);  
      wb_write(i, (i==0) ? 8'hC0 : rand_data);
      wb_read(i, temp);
    end
  end
  wb_write(2'h1, 8'h00);
  wb_write(2'h2, 8'h06);
  #200ns;

endtask

// ************************************************************* SECTION 2 **************************************************************************

 task coverage_section_2();
  bit [7:0] status;
  bit [7:0] data_val;
  bit [6:0] temp_addr = 7'h22;

  // --- 2.1 Wait Command ---
  // Write wait duration to DPR, then issue Wait (0x00)
  wb_write(2'h1, 8'h20);
  wb_write(2'h2, 8'h00); 
  
  // --- 2.4 Start Command ---
  // Issue Start (0x04)
  wb_write(2'h2, 8'h04);

  // --- 2.2 Write Command ---
  // Load address and issue Write (0x01)
  wb_write(2'h1, {temp_addr, 1'b0});
  wb_write(2'h2, 8'h01); 
  wb_write(2'h2, 8'h05); // Issue STOP to release the bus controller

  // --- 2.6 Set Bus Command ---
  // Load a bus ID and issue Set Bus (0x06)
  wb_write(2'h1, 8'h00);
  wb_write(2'h2, 8'h06);

  // --- 2.3 Read NACK & Read ACK ---
  begin
      i2c_transaction slave_resp;
      slave_resp = new("slave_resp");
      slave_resp.addr = temp_addr;
      slave_resp.op = i2c_transaction::READ; // Slave provides data for a Master Read
      slave_resp.data = new[2];
      slave_resp.data = '{8'hAA, 8'hBB};
      fork
          i2c_agent_h.bl_put(slave_resp);
      join_none
      #100ns;
  end

  // Put the Master into Read Mode via Wishbone
  wb_write(2'h2, 8'h04);              // START
  wb_write(2'h1, {temp_addr, 1'b1});  // Load Address + READ bit (1)
  wb_write(2'h2, 8'h01);              // COMMAND: Write Address (waits for Slave ACK)

  // Execute the specific Read commands
  wb_write(2'h2, 8'h02);              // COMMAND: Read with ACK (Hits 010)
  wb_read(2'h1, data_val);            // Clear register

  wb_write(2'h2, 8'h03);              // COMMAND: Read with NACK (Hits 011)
  wb_read(2'h1, data_val);            // Clear register

  wb_write(2'h2, 8'h05);              // STOP
endtask

// ************************************************************* SECTION 3 **************************************************************************
task coverage_section_3();
  bit [7:0] nack_data;
  bit [7:0] temp;

  // --- 3.2 Core Enable ---
  // Disabling and enabling the core to test
  wb_write(2'h0, 8'h00);              // Disabling the core
  wb_write(2'h0, 8'hC0);              // Enabling the core

  // Re-set bus to 0 after re-enable
  wb_write(2'h1, 8'h00);
  wb_write(2'h2, 8'h06);   // Set Bus 0

  // --- 3.1 DON bit ---
  wb_write(2'h2, 8'h04);   // START - DON fires after completion
  wb_read(2'h2, temp);     // READ CMDR - explicitly sample DON
  wb_write(2'h2, 8'h05);   // STOP

  // --- 3.2 NAK bit ---
  // Write to a non-existent slave address
  // No i2c_agent will respond so DUT sets NAK=1 in CMDR
  wb_write(2'h2, 8'h04);       // START
  wb_write(2'h1, 8'hFE);       // addr 0x7F and write bit
  wb_write(2'h2, 8'h01);       // WRITE - slave won't ACK, so NAK bit set
  wb_read(2'h2, nack_data);    // READ CMDR samples cp_nack
    wb_write(2'h2, 8'h05);       // STOP

  // --- 3.4 and 3.5 I2C Start and Stop ---
  // Fired by every transfer in proj2 tests
endtask

// ************************************************************* SECTION 4 **************************************************************************
task coverage_section_4();
    i2c_transaction data_i2c;
    bit [7:0] read_data;
    bit [6:0] temp_addr = 7'h22;

    // --- 4.2: Slave NACK ---
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, 8'hFE);             // addr 0x7F + write, no slave
    wb_write(2'h2, 8'h01);             // WRITE
    wb_write(2'h2, 8'h05);             // STOP
    wb_write(2'h0, 8'h00);             // disable
    wb_write(2'h0, 8'hC0);             // re-enable
    wb_write(2'h1, 8'h00);             // bus 0
    wb_write(2'h2, 8'h06);             // Set Bus 0

    // --- 4.3a: START -> WRITE ---
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b0}); // addr + WRITE
    wb_write(2'h2, 8'h01);             // WRITE <- START-> WRITE fires
    wb_write(2'h2, 8'h05);             // STOP

    // --- 4.3b: WRITE -> READ_ACK ---
    data_i2c = new("data_i2c");
    data_i2c.addr    = temp_addr;
    data_i2c.op      = i2c_transaction::READ;
    data_i2c.data    = new[2];
    data_i2c.data[0] = 8'hAA;
    data_i2c.data[1] = 8'hBB;
    fork i2c_agent_h.bl_put(data_i2c); join_none
    #100ns;
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b1}); // addr + READ
    wb_write(2'h2, 8'h01);             // WRITE address
    wb_write(2'h2, 8'h02);             // READ_ACK <- WRITE-> READ_ACK fires
    wb_read(2'h1,  read_data);
    wb_write(2'h2, 8'h03);             // READ_NACK
    wb_read(2'h1,  read_data);
    wb_write(2'h2, 8'h05);             // STOP

    // --- 4.3c: WRITE -> READ_NACK ---
    data_i2c = new("data_i2c");
    data_i2c.addr    = temp_addr;
    data_i2c.op      = i2c_transaction::READ;
    data_i2c.data    = new[1];
    data_i2c.data[0] = 8'hCC;
    fork i2c_agent_h.bl_put(data_i2c); join_none
    #100ns;
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b1}); // addr + READ
    wb_write(2'h2, 8'h01);             // WRITE address
    wb_write(2'h2, 8'h03);             // READ_NACK <- WRITE-> READ_NACK fires
    wb_read(2'h1,  read_data);
    wb_write(2'h2, 8'h05);             // STOP

    // --- 4.4a: WRITE -> STOP ---
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b0}); // addr + WRITE
    wb_write(2'h2, 8'h01);             // WRITE address
    wb_write(2'h1, 8'hDD);             // data
    wb_write(2'h2, 8'h01);             // WRITE data
    wb_write(2'h2, 8'h05);             // STOP <- WRITE->STOP fires

    // --- 4.4b: READ_ACK -> STOP ---
    data_i2c = new("data_i2c");
    data_i2c.addr    = temp_addr;
    data_i2c.op      = i2c_transaction::READ;
    data_i2c.data    = new[1];
    data_i2c.data[0] = 8'hEE;
    fork i2c_agent_h.bl_put(data_i2c); join_none
    #100ns;
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b1}); // addr + READ
    wb_write(2'h2, 8'h01);             // WRITE address
    wb_write(2'h2, 8'h02);             // READ_ACK
    wb_read(2'h1,  read_data);
    wb_write(2'h2, 8'h05);             // STOP <- READ_ACK-> STOP fires

    // --- 4.4c: READ_NACK -> STOP ---
    data_i2c = new("data_i2c");
    data_i2c.addr    = temp_addr;
    data_i2c.op      = i2c_transaction::READ;
    data_i2c.data    = new[1];
    data_i2c.data[0] = 8'hFF;
    fork i2c_agent_h.bl_put(data_i2c); join_none
    #100ns;
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b1}); // addr + READ
    wb_write(2'h2, 8'h01);             // WRITE address
    wb_write(2'h2, 8'h03);             // READ_NACK
    wb_read(2'h1,  read_data);
    wb_write(2'h2, 8'h05);             // STOP <- READ_NACK-> STOP fires

    // --- 4.1: Repeated Start - do LAST since it leaves bus busy ---
    data_i2c = new("data_i2c");
    data_i2c.addr    = temp_addr;
    data_i2c.op      = i2c_transaction::READ;
    data_i2c.data    = new[1];
    data_i2c.data[0] = 8'hAB;
    fork i2c_agent_h.bl_put(data_i2c); join_none
    #100ns;
    wb_write(2'h2, 8'h04);             // START
    wb_write(2'h1, {temp_addr, 1'b0}); // addr + WRITE
    wb_write(2'h2, 8'h01);             // WRITE
    wb_write(2'h2, 8'h04);             // REPEATED START
    wb_write(2'h1, {temp_addr, 1'b1}); // addr + READ
    wb_write(2'h2, 8'h01);             // WRITE address
    wb_write(2'h2, 8'h03);             // READ_NACK
    wb_read(2'h1,  read_data);
    wb_write(2'h2, 8'h05);             // STOP
endtask

// ************************************************************* TASKS FOR TEST CASES Function ********************************************************************
// task that contains test cases
virtual task run();

  bit [6:0] slave_addr = 7'h22;
  i2c_transaction i2c_trans;

  i2c_trans = new("i2c_trans");
  i2c_trans.addr = slave_addr;
  i2c_trans.op = i2c_transaction::WRITE;
  i2c_trans.data = new[32]; // Initialize size to 32
  
  this.nb_transport(i2c_trans, i2c_trans);  

  fork
    begin
      i2c_trans = new("i2c_trans");
      // This tells the I2C Agent to wait for a transaction on the bus
      i2c_agent_h.bl_put(i2c_trans); 
    end
  join_none

  //1. Enabling the IICMB core by setting enable bit to 1
  wb_write(2'h0, 8'hC0);

// 2. IMPORTANT: Set Prescaler IMMEDIATELY
    // The hardware needs a clock to process commands like "Set Bus"
    wb_write(2'h1, 8'h01); 
    wb_write(2'h2, 8'h07);

  //2. Writing byte 0x00 to the DPR. This is the ID of desired I2C bus
  wb_write(2'h1, 8'h00);

  //3. Writing byte “xxxxx110” to the CMDR. This is Set Bus command.
  wb_write(2'h2, 8'h06);
  
  // Test 1
  i2c_write(slave_addr);
  
  // Test2
  i2c_read(slave_addr);

  // Test3
  i2c_alternate(slave_addr);

  // COVERAGE
  // Coverage section 1
  coverage_section_1();

  // Coverage section 2
  coverage_section_2();

  // Coverage section 3
  coverage_section_3();

  //// Coverage section 4
  coverage_section_4();

endtask

endclass