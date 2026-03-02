`timescale 1ns / 10ps
interface i2c_if       #(
      int I2C_ADDR_WIDTH = 7,                                
      int I2C_DATA_WIDTH = 8                                
      )

(
  inout scl,
  inout triand sda
);

typedef enum bit{
i2c_write = 1'b0,
i2c_read = 1'b1
} i2c_op_t;

// Internal signals to drive the bus
logic scl_out = 1'b1;
logic sda_out = 1'b1;

assign scl = (scl_out === 1'b0) ? 1'b0 : 1'bz;
assign sda = (sda_out === 1'b0) ? 1'b0 : 1'bz;

// ****************************************************************************
// Waits for and captures transfer start

task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);    // write_data is a dynamic array
begin

    bit [I2C_ADDR_WIDTH:0] addr_temp;
    bit [I2C_DATA_WIDTH - 1:0] data_temp;
    write_data = {};

    // Detecting a START condition
    wait(scl === 1'b1 && sda === 1'b1);
    @(negedge sda); 
    begin
        if(scl === 1'b1) begin          // when sda falls from 1 to 0, if scl is 1 then START condition is achieved
        begin
            // Capturing Address and Read/Write
            for(int i = I2C_ADDR_WIDTH; i >= 0; i = i - 1)
            begin
                @(posedge scl);  
                addr_temp[i] = sda;     // Capturing the 7 bit address
            end

            // Capturing Read/Write
            if(addr_temp[0] === 1'b1)  op = i2c_read;
            else  op = i2c_write;

            // Sending an ACK in the 9th clock pulse, and releasing the line
            @(negedge scl); sda_out = 1'b0;
            @(posedge scl);             // for master to latch on to ack
            @(negedge scl); sda_out = 1'b1;
            if(op == i2c_read)   return;

            // If operation is Write, continue till STOP is achieved
            // For every byte of data recieved, an ACK bit must be sent
            // Dynamic array is declared as we are not sure of how many bytes of data is sent
            else begin            
            forever
                begin
                    fork    
                    begin : capture_byte
                    begin
                        //Capturing one byte
                        for(int i = I2C_DATA_WIDTH - 1; i >= 0; i = i - 1)
                        begin
                            @(posedge scl);  
                            data_temp[i] = sda;     // Capturing the 8 bit data
                        end  

                        // Storing
                        write_data = new[write_data.size() + 1](write_data);
                        write_data[write_data.size() - 1] = data_temp;

                        // Sending an ACK in the 9th clock pulse, and releasing the line
                        @(negedge scl);                 // 8th negedgedriving acknowledge
                        sda_out = 1'b0;
                        @(posedge scl);             // for master to latch on to ack
                        @(negedge scl);
                        sda_out = 1'b1;
                    end
                    end : capture_byte          

                    begin : detect_stop
                        @(posedge sda iff scl === 1'b1); 
                        disable capture_byte;      
                    end : detect_stop
                    join_any
                    disable fork;

                    if(scl == 1'b1 && sda == 1'b1) break;
                end
           end
        end
        end
    end
end
endtask

// ****************************************************************************
// Provides data for read operation
task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
begin
    int num_of_bytes;
    int ack_bit;
    transfer_complete = 1'b0;
    num_of_bytes = read_data.size();

    for(int i = 0; i < num_of_bytes; i++)
    begin
        for(int j = I2C_DATA_WIDTH - 1; j >= 0; j--)
        begin
            // when j = I2C_DATA_WIDTH - 1, it is 8th negedge
            sda_out = read_data[i][j];     //Bit-by-bit transmission to master on sda_out
            @(negedge scl);     // The HIGH or LOW state of the data line can only change when the clock signal on the SCL line is LOW
        end 

        sda_out = 1'b1;         // Releasing the bus
        @(posedge scl);                         // Handling the Acknowledge bit
        @(negedge scl);         // recieving acknowledge bit in 9th negedge
        ack_bit = sda;
    end
    // Detect end
    wait(scl === 1'b1 && sda_out === 1'b1);       
    transfer_complete = 1;
    //sda_out = 1'b1;     // Releasing the bus at the end of transmission
end
endtask

// ****************************************************************************
task monitor ( output bit [I2C_ADDR_WIDTH-1:0]  addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
begin
    bit read_done;
    bit [I2C_ADDR_WIDTH:0] addr_temp;
    bit [I2C_DATA_WIDTH - 1:0] data_temp;
    int ack_bit;
    data = {};

    wait(scl === 1'b1 && sda === 1'b1);

    // Detecting a START condition
    @(negedge sda);  
    begin
        if(scl === 1'b1)           // when sda falls from 1 to 0, if scl is 1 then START condition is achieved
        begin
            // Capturing Address and Read/Write
            for(int i = I2C_ADDR_WIDTH; i >= 0; i = i - 1)
            begin
                @(posedge scl);  
                addr_temp[i] = sda;     // Capturing the 7 bit address
            end

            addr = addr_temp[I2C_ADDR_WIDTH-1:1];

            // Capturing Read/Write
            if(addr_temp[0] === 1)
            begin
                op = i2c_read;
            end
            else
            begin
                op = i2c_write;
            end

            // Sending an ACK in the 9th clock pulse, and releasing the line

            @(posedge scl);             // for master to latch on to ack
            @(negedge scl);

            // If operation is Write, continue till STOP is achieved
            // For every byte of data recieved, an ACK bit must be sent
            // Dynamic array is declared as we are not sure of how many bytes of data is sent
            //if(op == i2c_write)            

            forever begin
                begin
                    fork    
                    begin : capture_byte
                    begin
                        //Capturing one byte
                        for(int i = I2C_DATA_WIDTH - 1; i >= 0; i = i - 1)
                        begin
                            @(posedge scl);  
                            data_temp[i] = sda;     // Capturing the 7 bit address
                        end  

                        // Storing
                        data = new[data.size() + 1](data);
                        data[data.size() - 1] = data_temp;

                        // Sending an ACK in the 9th clock pulse, and releasing the line
                        @(posedge scl);             // for master to latch on to ack
                        ack_bit = sda;
                        @(negedge scl);

                        if(op == i2c_read && ack_bit == 1'b1)  
                            read_done = 1'b1;   // if master sends NACK after a read byte, it indicates end of read transfer
                    end
                    end : capture_byte         

                    begin : detect_stop
                        @(posedge sda iff scl === 1'b1);
                        disable capture_byte;      
                    end : detect_stop
                    join_any
                    disable fork;
                    if(op == i2c_read && read_done) break;
                    if(scl == 1'b1 && sda == 1'b1) break;
                end
                end    
            end      
    end
end
endtask
endinterface