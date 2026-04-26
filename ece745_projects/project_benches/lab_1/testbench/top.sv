`timescale 1ns / 10ps

module top();
parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;

wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;

tri1  [NUM_I2C_BUSSES-1:0] scl;
tri1  [NUM_I2C_BUSSES-1:0] sda;

// ****************************************************************************
// Clock generator
initial begin : clk_gen
clk = 1'b0;
forever
begin
  #5ns clk = ~clk;
end
end : clk_gen

// ****************************************************************************
// Reset generator
initial begin : rst_gen
#113ns;
rst = 1'b0;
end : rst_gen

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
logic [WB_ADDR_WIDTH-1:0]monitor_addr;
logic [WB_DATA_WIDTH-1:0]monitor_data;
logic monitor_we;
end : wb_monitoring

// ****************************************************************************
// I2C slave block
initial begin : i2c_slave

bit [7:0]write_data [];
logic op;
bit [7:0]read_data [];
bit transfer_complete;
int tc3_ptr = 63;

bit [7:0] last_byte_written = 8'h00;

forever
begin
  i2c_bus.wait_for_i2c_transfer(op, write_data);

  if(op == 1'b0)
  begin
    if(write_data.size() > 0)
    last_byte_written = write_data[0];
  end

  if(op == 1'b1)
  begin
    // Populate read_data with expected values for the read operation
    if(last_byte_written >= 8'd64)
    begin
      read_data = new[1];
      read_data[0] = tc3_ptr;
      tc3_ptr = tc3_ptr - 1;
    end

    else
    begin
      read_data = new[32];
      for(int idx = 0; idx < 32; idx = idx + 1) read_data[idx] = 8'd100 + idx;  // Return values 100-131
    end

    i2c_bus.provide_read_data(read_data, transfer_complete);
    
  end
end
end : i2c_slave

// ****************************************************************************
// I2C monitor block
initial begin : monitor_i2c_bus
logic [7:0]monitor_addr;
bit [7:0]monitor_data [];
logic monitor_op;

forever begin
i2c_bus.monitor(.addr(monitor_addr), .op(monitor_op), .data(monitor_data));

if(monitor_op == 1'b0)
$display("I2C_BUS WRITE Transfer: %p", monitor_data);

else
$display("I2C_BUS READ Transfer: %p", monitor_data);
end
end : monitor_i2c_bus

// ****************************************************************************
// Define the flow of the simulation
initial begin : test_flow

// ********************************************************* Project 1 Test cases *****************************************************************
logic [7:0] cmdr_don;

//1. Enabling the IICMB core by setting enable bit to 1
wb_bus.master_write(.addr(2'h0),.data(8'h80));
//$display("Enabled the IICMB core");

//2. Writing byte 0x00 to the DPR. This is the ID of desired I2C bus -  bus 0
wb_bus.master_write(.addr(2'h1),.data(8'h00));
//$display("Selected bus");

//3. Writing byte “xxxxx110” to the CMDR. This is Set Bus command.
wb_bus.master_write(.addr(2'h2),.data(8'h06));
//$display("Gave Set bus command");

//4. Waiting till the command is complete (DON) bit should be set to 1
wb_bus.master_read(.addr(2'h2),.data(cmdr_don));
while(cmdr_don[7] == 1'b0)
begin
  wb_bus.master_read(.addr(2'h2), .data(cmdr_don));
end
//$display("DON bit has been set to 1");

// ************************************************************* TEST CASE 1 (PROJ 1) *************************************************************************
// Write 32 incrementing values, from 0 to 31, to the i2c_bus
//$display(" ****************** TEST CASE 1 (PROJ 1) ******************");
// 8'h22 is the slave address of the i2c slave
i2c_write(8'h22);
//$display(" ****************** TEST CASE 1 COMPLETE ******************");
// Wait for bus to settle and slave task to exit properly
#100us;

// ************************************************************* TEST CASE 2 (PROJ 1) *************************************************************************
// Read 32 values from the i2c_bus
// Return incrementing data from 100 to 131  
//$display(" ****************** TEST CASE 2 (PROJ 1) ******************");
i2c_read(8'h22);
//$display(" ****************** TEST CASE 2 COMPLETE ******************");

// ************************************************************* TEST CASE 3 (PROJ 1) *************************************************************************
// Alternate writes and reads for 64 transfers
// Increment write data from 64 to 127
// Decrement read data from 63 to 0
//$display(" ****************** TEST CASE 3 (PROJ 1) ******************");
i2c_alternate(8'h22);
//$display(" ****************** TEST CASE 3 COMPLETE ******************");

end : test_flow

// ************************************************************* TASKS FOR TEST CASE 1 (PROJ1) ********************************************************************
task wb_write(input bit [1:0]wb_addr, input bit [7:0] wb_data);
begin
  logic [7:0] cmdr_don;
  wb_bus.master_write(.addr(wb_addr), .data(wb_data));

  if(wb_addr == 2'h2)
  begin
    do begin
      wb_bus.master_read(.addr(2'h2),.data(cmdr_don));
    end while(cmdr_don[7:6] == 2'b00);
  end
end
endtask

task i2c_write(input bit [6:0]i2c_addr);
begin
  bit [7:0] i;

  // Start condition is achieved by writing 0x04 to the CMDR
  wb_write(2'h2, 8'h04);

 // Writing the slave address to the DPR, with the write bit (0) at the end    
  wb_bus.master_write(2'h1, {i2c_addr, 1'b0});  

  // Giving the Write command by writing 0x01 to the CMDR
  wb_write(2'h2, 8'h01);  

  for(i = 0; i < 32; i = i + 1)
  begin
    // Writing data to the DPR and giving the Write command for each byte of data
    wb_bus.master_write(2'h1, 8'(i));  
    wb_write(2'h2, 8'h01);
  end
  wb_write(2'h2, 8'h05);      // Stop command
end
endtask

// ************************************************************* TASKS FOR TEST CASE 2 (PROJ1) ********************************************************************
task i2c_read(input bit [6:0]i2c_addr, input bit [7:0] start_data = 8'd100, input int num_bytes = 32);
begin
  bit [7:0] i;
  bit [7:0] expected_data [];
  bit [7:0] read_data [];
  bit [7:0] cmdr_don;

  // Initialize the expected_data array with expected values
  expected_data = new[num_bytes];
  read_data = new[num_bytes];

  for(int j = 0; j < num_bytes; j = j + 1)
  begin
    expected_data[j] = start_data + j;
  end

  // Start condition is achieved by writing 0x04 to the CMDR
  wb_write(2'h2, 8'h04);

  // Writing the slave address to the DPR, with the read bit (1) at the end
  wb_bus.master_write(2'h1, {i2c_addr, 1'b1});
  wb_write(2'h2, 8'h01); // Giving the Read command by writing 0x01 to the CMDR

  for(i = 0; i < num_bytes; i = i + 1)
  begin
    if(i == num_bytes - 1)
    wb_write(2'h2, 8'h03); // Read command with NACK bit set
    else
    wb_write(2'h2, 8'h02); // Read command with ACK bit set
   wb_bus.master_read(2'h1, read_data[i]); // Reading the data byte from the DPR
  end
 wb_write(2'h2, 8'h05); // Stop command
end
endtask
// ************************************************************* TASKS FOR TEST CASE 3 (PROJ1) ********************************************************************
task i2c_alternate(input [6:0]i2c_addr);
begin
  bit [7:0]write_data;
  bit [7:0]read_data;
  bit [7:0]expected_read;

  write_data = 8'd64;
  expected_read = 8'd63;

    for(int i = 0; i < 64; i = i + 1)
    begin
        // Write data to the slave
        wb_write(2'h2, 8'h04); // Start condition
        wb_bus.master_write(2'h1, {i2c_addr, 1'b0}); // Slave address with write bit
        wb_write(2'h2, 8'h01); // Write command

        wb_bus.master_write(2'h1, write_data); //data
        wb_write(2'h2, 8'h01); // Write command

        wb_write(2'h2, 8'h05); // Stop condition

        write_data = write_data + 1'd1;   

        // Read data from the slave
        wb_write(2'h2, 8'h04); // Start condition
        wb_bus.master_write(2'h1, {i2c_addr, 1'b1}); // Slave address with read bit
        wb_write(2'h2, 8'h01); // Read command

        wb_write(2'h2, 8'h03); // Read command with NACK bit set
        wb_bus.master_read(2'h1, read_data); // Read data from the DPR

        wb_write(2'h2, 8'h05); // Stop condition

        expected_read = expected_read - 1'd1;
    end
end
endtask
// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )

wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),

  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),

  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),

  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)  
);

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
   // ------------------------------------
    // -- Wishbone signals:
   .clk_i(clk),         // in    std_logic;                            -- Clock
   .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
   .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
   .stb_i(stb),         // in    std_logic;                            -- Slave selection
   .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
   .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

// ****************************************************************************
// Instantiate the I2C Interface
// Instance: i2c_bus
i2c_if       #(
      .I2C_ADDR_WIDTH(7),
      .I2C_DATA_WIDTH(8)
      )

i2c_bus (
  // Clock line
  .scl(scl),
  // Data line
  .sda(sda)
  );
endmodule