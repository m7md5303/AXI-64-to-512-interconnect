# AXI-64-to-512-interconnect
Open-source AXI interconnect between 64-bit Master and 512-bit Slave supporting up to 2GB memory space for fixed-ID transactions implemented in Verilog. 

## Repository Structure

### Design files

Includes the design files written in Verilog:

- interconnect.v: top module file
- writeaxi_mk.v: write interconnect receiving writes from the master and translating them to the slave
- readaxi_mk.v: read interconnect translating read orders from the master to the slave and then translating back the read words to the master
- scfifo_mk.v: synchronous FIFO for the in and out conversions, used in both write and read converters


### Simulation files

Includes the simulation files for the two converters written in SystemVerilog:

- axiwrite_tb.sv: testbench file for the write interconnect
- axiread_tb.sv: testbench file for the read interconnect

## Hardware Testing

The design was tested on hardware on Kintex-7 using Vivado AXI Traffic Generator (ATG) IP and the UBERDDR3 memory controller
<img width="1558" height="799" alt="ATG_Inter_Uber" src="https://github.com/user-attachments/assets/b8d87afe-4a70-4afe-a8d3-e06ed3973a47" />


## Specs and Limitations

- Supported Master interface: 64 bits
- Supported Slave interface: 512 bits
- Supported Address Space: up to 2GB memory
- Independent write and read channels
- Fixed-ID Transactions
- Expecting same clock for the Master and Slave
- Wrap bursts are not supported
- No AXI USER/PROT/CACHE fields

## Instantiation Template
```verilog
interconnect_mk u_interconnect_mk (
    .aclk            (aclk),
    .aresetn         (aresetn),

    //Master Interface

    .M_AXI_araddr    (M_AXI_araddr),
    .M_AXI_arburst   (M_AXI_arburst),
    .M_AXI_arlen     (M_AXI_arlen),
    .M_AXI_arready   (M_AXI_arready),
    .M_AXI_arsize    (M_AXI_arsize),
    .M_AXI_arvalid   (M_AXI_arvalid),

    .M_AXI_awaddr    (M_AXI_awaddr),
    .M_AXI_awburst   (M_AXI_awburst),
    .M_AXI_awlen     (M_AXI_awlen),
    .M_AXI_awready   (M_AXI_awready),
    .M_AXI_awsize    (M_AXI_awsize),
    .M_AXI_awvalid   (M_AXI_awvalid),

    .M_AXI_bready    (M_AXI_bready),
    .M_AXI_bresp     (M_AXI_bresp),
    .M_AXI_bvalid    (M_AXI_bvalid),

    .M_AXI_rdata     (M_AXI_rdata),
    .M_AXI_rlast     (M_AXI_rlast),
    .M_AXI_rready    (M_AXI_rready),
    .M_AXI_rresp     (M_AXI_rresp),
    .M_AXI_rvalid    (M_AXI_rvalid),

    .M_AXI_wdata     (M_AXI_wdata),
    .M_AXI_wlast     (M_AXI_wlast),
    .M_AXI_wready    (M_AXI_wready),
    .M_AXI_wstrb     (M_AXI_wstrb),
    .M_AXI_wvalid    (M_AXI_wvalid),

    //Slave Interface

    .S_AXI_araddr    (S_AXI_araddr),
    .S_AXI_arburst   (S_AXI_arburst),
    .S_AXI_arlen     (S_AXI_arlen),
    .S_AXI_arready   (S_AXI_arready),
    .S_AXI_arsize    (S_AXI_arsize),
    .S_AXI_arvalid   (S_AXI_arvalid),

    .S_AXI_awaddr    (S_AXI_awaddr),
    .S_AXI_awburst   (S_AXI_awburst),
    .S_AXI_awlen     (S_AXI_awlen),
    .S_AXI_awready   (S_AXI_awready),
    .S_AXI_awsize    (S_AXI_awsize),
    .S_AXI_awvalid   (S_AXI_awvalid),

    .S_AXI_bready    (S_AXI_bready),
    .S_AXI_bresp     (S_AXI_bresp),
    .S_AXI_bvalid    (S_AXI_bvalid),

    .S_AXI_rdata     (S_AXI_rdata),
    .S_AXI_rlast     (S_AXI_rlast),
    .S_AXI_rready    (S_AXI_rready),
    .S_AXI_rresp     (S_AXI_rresp),
    .S_AXI_rvalid    (S_AXI_rvalid),

    .S_AXI_wdata     (S_AXI_wdata),
    .S_AXI_wlast     (S_AXI_wlast),
    .S_AXI_wready    (S_AXI_wready),
    .S_AXI_wstrb     (S_AXI_wstrb),
    .S_AXI_wvalid    (S_AXI_wvalid)
);
```


## License
The project is open-source under MIT License
