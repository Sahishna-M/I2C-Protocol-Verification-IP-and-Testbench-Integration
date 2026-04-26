## Overview

This repository contains a series of four verification projects for the **I2C Multiple Bus Controller (I2CMB)** DUT, developed incrementally as part of ECE 745 – ASIC Verification at NC State University. 
The verification environment is written in SystemVerilog and simulated using Questa/ModelSim. 
Each project builds upon the previous one, culminating in a full layered testbench with functional coverage, a formal test plan, and a complete regression suite.

The DUT is the I2CMB (I2C Multiple Bus Controller), an OpenCores IP that acts as a Wishbone slave and I2C master, capable of controlling multiple I2C buses. 
The verification environment interfaces with the DUT through two interfaces: a Wishbone bus interface (wb_if) and an I2C bus interface (i2c_if).

---

## Repository Structure

ece745_projects/
├── verification_ip/
│   ├── interface_packages/
│   │   ├── wb_pkg/                  # Wishbone interface and package
│   │   │   └── src/
│   │   │       └── wb_if.sv
│   │   │       └── wb_agent.sv
│   │   │       └── wb_configuration.sv
│   │   │       └── wb_coverage.sv
│   │   │       └── wb_driver.sv
│   │   │       └── wb_monitor.sv
│   │   │       └── wb_transaction.sv
│   │   │   └── wb_pkg.sv
│   │   └── i2c_pkg/                 # I2C interface and package
│   │   │    └── src/
│   │   │       └── i2c_if.sv
│   │   │       └── i2c_agent.sv
│   │   │       └── i2c_configuration.sv
│   │   │       └── i2c_coverage.sv
│   │   │       └── i2c_driver.sv
│   │   │       └── i2c_monitor.sv
│   │   │       └── i2c_transaction.sv
│   │   │   └── i2c_pkg.sv
│   └── environment_packages/
│       └── i2cmb_env_pkg/           # Layered testbench environment
│           └── src/
│               ├── i2cmb_test.svh
│               ├── i2cmb_generator.svh
│               ├── i2cmb_environment.svh
│               ├── i2cmb_env_configuration.svh
│               ├── i2cmb_predictor.svh
│               ├── i2cmb_scoreboard.svh
│               └── i2cmb_coverage.svh
│           └── i2cmb_env_pkg.sv
│      └── ncsu_pkg/
└── project_benches/
    ├── lab_1/                        # Lab 1 baseline bench
    ├── proj_1/                       # Project 1: I2C Interface
    ├── proj_2/                       # Project 2: Layered Testbench
    ├── proj_3/                       # Project 3: Test Plan & Coverage
    └── proj_4/                       # Project 4: Coverage Closure

---

## Projects

### Project 1 – I2CMB I2C Interface (`proj_1`)

Goal: Create an i2c_if SystemVerilog interface that models an I2C slave device, capable of interacting with the I2CMB DUT over the I2C bus.

What was implemented:
- wait_for_i2c_transfer(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data[]) - Waits for and captures an I2C transfer initiated by the DUT. Detects start condition, reads the address and direction bit,
  and collects any write data byte by byte.
- provide_read_data(input bit [I2C_DATA_WIDTH-1:0] read_data[], output bit transfer_complete) - When the DUT initiates a read, this task drives data back onto the I2C bus byte by byte, completing the transfer.
- monitor(output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data[]) - Passively observes all I2C transactions and returns the address, operation type, and data for logging purposes.
- An i2c_bus instance of i2c_if is instantiated in top.sv and connected to the DUT.
- A monitor_i2c_bus initial block in top.sv continuously calls the monitor task and prints observed transfers with the prefix I2C_BUS WRITE Transfer: or I2C_BUS READ Transfer:.

Test flow executed:
1. Write 32 incrementing values (0–31) to the I2C bus
2. Read 32 values from the I2C bus, returning incrementing data (100–131)
3. Alternate 64 transfers (32 writes + 32 reads): write data increments from 64–127, read data decrements from 63–0

To run:
```bash
cd project_benches/proj_2/sim
make clean
make debug_3step
```
---

### Project 2 – I2CMB Layered Testbench (`proj_2`)

Goal: Refactor the Project 1 test flow into a structured, layered testbench architecture using object-oriented SystemVerilog classes, based on the ncsu_pkg base class library.


**What was implemented:**
- `wb_pkg` – Wishbone agent package including `wb_driver`, `wb_monitor`, `wb_agent`, `wb_transaction`, and `wb_configuration`, all extending from `ncsu_pkg` base classes.
- `i2c_pkg` – I2C agent package including `i2c_driver`, `i2c_monitor`, `i2c_agent`, `i2c_transaction`, and `i2c_configuration`, reusing the `i2c_if` tasks from Project 1.
- `i2cmb_env_pkg` – Top-level environment package including the test, generator, environment, predictor, scoreboard, and coverage components.
- `top.sv` was updated to instantiate `i2cmb_test`, store virtual interface handles in `ncsu_config_db`, construct and run the test after reset is released, and call `$finish` upon completion.
- The generator implements the full Project 1 test flow using `wb_transactions` and `i2c_transactions`, supporting both polling the CMDR register and using the `wait_for_interrupt` task for DON bit detection.
- The scoreboard verifies DUT operation by comparing predicted vs. observed I2C transactions.

**Test flow executed:** Same as Project 1 (32 writes, 32 reads, 64 alternating transfers), now driven through the layered environment.

**To run:**
```bash
cd project_benches/proj_2/sim
make clean
make debug_3step
```

---

### Project 3 – I2CMB Test Plan & Functional Coverage (`proj_3`)

**Goal:** Develop a formal test plan derived from the I2CMB specification and implement corresponding functional coverage in the testbench. Link all test plan items to simulation coverage structures in Questa.

**What was implemented:**
- A completed `i2cmb_test_plan.xls` spreadsheet in the `sim/` directory containing 20 test plan items:
  - **5 register-related items** covering the CSR, DPR, CMDR, and FSMR registers - including valid/invalid address access, default values, read/write permissions, and field accuracy.
  - **15 functional items** covering areas such as FSM state transitions, byte-level write and read operations, start/stop/repeated-start conditions, I2C bus arbitration, multi-byte transfers,
  - interrupt behavior, and bus enable/disable sequences.
- Covergroups, coverpoints with explicit bins, cross coverage, and transition coverage implemented within the testbench components (`i2cmb_coverage`, `i2cmb_predictor`, agents).
- The test plan was imported into Questa, converted to UCDB, merged with simulation coverage, and all test plan links verified against simulation coverage structures.

**Test plan columns:** Number, Section, Description, Link, Type, Weight, Goal

**Coverage types used:** Covergroups, coverpoints with bins, cross coverage, transition coverage, code coverage

**To run:**
```bash
cd project_benches/proj_3/sim
make run_p3
```

---

### Project 4 – Coverage Closure & Bug Reporting (`proj_4`)

**Goal:** Close the test plan coverage defined in Project 3 by writing directed and randomized tests. Document any bugs discovered in the DUT using formal bug reports.

**What was implemented:**
- Multiple directed tests targeting specific uncovered bins and FSM transitions identified in the test plan.
- Randomized tests with controlled seeds to efficiently hit remaining coverage holes.
- A `testlist` file in the `sim/` directory listing all test name and seed pairs used to achieve coverage results.
- A `regress.sh` script in the `sim/` directory that automates the full regression flow.
- Bug reports completed for any bugs identified in the I2CMB DUT during testing.

**The `regress.sh` script does the following:**
1. Runs all directed and randomized tests with specified seeds and arguments
2. Merges all individual UCDBs into a single `merged_tests.ucdb`
3. Converts the test plan XML into `test_plan.ucdb`
4. Merges `test_plan.ucdb` and `merged_tests.ucdb` into `regression.ucdb`
5. Opens the Questa GUI for viewing the final regression coverage results

**To run:**
```bash
cd project_benches/proj_4/sim
bash regress.sh
```

> **Note:** The TA will run `regress.sh` directly. Ensure the script has no dependencies on local environment variables, absolute paths, or files outside the submission directory. Test in a clean unzipped environment before submitting.

---

## General Notes

- Always run `make clean` in the `sim/` directory before creating a tar submission.
- For Project 4, remove the `work/` directory from `sim/` before creating the tar file.
- All I2C operations are driven indirectly through the DUT via the Wishbone bus (`wb_bus`) — the testbench does not directly drive the I2C master signals.
- Debug messages should not be left in the transcript. Only scoreboard and monitor output should appear during normal simulation runs.

---

## Tools Used

- **Simulator:** Questa/ModelSim
- **Language:** SystemVerilog
- **Coverage & Regression:** Questa UCDB, test plan XML import/merge
- **DUT:** I2CMB (I2C Multiple Bus Controller) – OpenCores IP
```
