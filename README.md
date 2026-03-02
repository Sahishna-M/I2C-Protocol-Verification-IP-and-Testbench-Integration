# I2C-Protocol-Verification-IP-and-Testbench-Integration
Developed a Verification IP to model an I2C Slave interface, facilitating communication with Design Under Test (DUT).

## Project Architecture: I2C Slave Verification IP
Developed a modular, transaction-based verification environment in SystemVerilog to validate an I2C Master DUT connected via a Wishbone interconnect.
• Layered Testbench Structure: Implemented a structured environment consisting of a Generator, Driver, Monitor, and Scoreboard to separate stimulus generation from protocol checking.
• Reactive Slave Model: Engineered a SystemVerilog-based Slave VIP that dynamically responds to Master requests, handling 7-bit addressing and the R/W bit with 100% accuracy.
• Asynchronous Handshaking: Designed sophisticated tasks, including wait_for_i2c_transfer, to synchronize the high-speed Wishbone bus clock with the asynchronous I2C Start/Stop sequences.

## Technical Deep Dive & Features
• Protocol Compliance: Validated the complete I2C state machine, ensuring correct transitions between START, ADDRESS_PHASE, DATA_PHASE, and STOP conditions.
• Back-to-Back Transaction Stress Testing: Verified the robustness of the I2C-to-Wishbone bridge by executing 64 consecutive transactions to test buffer overflows and timing slacks.
• Advanced Monitoring: Developed a real-time monitor that sniffs the SDA/SCL lines to decode bus traffic and feed a dynamic Scoreboard for automated data comparison.
• Error Injection & Corner Cases: (If applicable to your code) Tested the DUT’s ability to handle NACK responses and repeated START conditions without losing synchronization.

## Tools & Methodology
• Simulation & Synthesis: Used QuestaSim and Synopsys tools for RTL simulation and functional verification.
• Verification Metric: Achieved complete functional coverage of the I2C address space and command set (Read/Write sequencing).
