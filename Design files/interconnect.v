// MIT License

// Copyright (c) 2026 MohamedKhaled5303

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
module interconnect_mk
   (aclk,
    aresetn,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arlen,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awlen,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arlen,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awlen,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
//declaring parameters
  parameter ADDR_WIDTH = 31;
  parameter MASTER_WIDTH = 512;
  parameter SLAVE_WIDTH = 64;
  parameter STRB_M = MASTER_WIDTH/8;
  parameter STRB_S = SLAVE_WIDTH/8;
//declaring ports
  input wire aclk;
  input wire aresetn;
  output wire [ADDR_WIDTH-1:0]M_AXI_araddr;
  output wire [1:0]M_AXI_arburst;
  output wire [7:0]M_AXI_arlen;
  input wire M_AXI_arready;
  output wire [2:0]M_AXI_arsize;
  output wire M_AXI_arvalid;
  output wire [ADDR_WIDTH-1:0]M_AXI_awaddr;
  output wire [1:0]M_AXI_awburst;
  output wire [7:0]M_AXI_awlen;
  input wire M_AXI_awready;
  output wire [2:0]M_AXI_awsize;
  output wire M_AXI_awvalid;
  output wire M_AXI_bready;
  input wire [1:0]M_AXI_bresp;
  input wire M_AXI_bvalid;
  input wire [MASTER_WIDTH-1:0]M_AXI_rdata;
  input wire M_AXI_rlast;
  output wire M_AXI_rready;
  input wire [1:0]M_AXI_rresp;
  input wire M_AXI_rvalid;
  output wire [MASTER_WIDTH-1:0]M_AXI_wdata;
  output wire M_AXI_wlast;
  input wire M_AXI_wready;
  output wire [STRB_M-1:0]M_AXI_wstrb;
  output wire M_AXI_wvalid;
  input wire [ADDR_WIDTH-1:0]S_AXI_araddr;
  input wire [1:0]S_AXI_arburst;
  input wire [7:0]S_AXI_arlen;
  output wire S_AXI_arready;
  input wire [2:0]S_AXI_arsize;
  input wire S_AXI_arvalid;
  input wire [ADDR_WIDTH-1:0]S_AXI_awaddr;
  input wire [1:0]S_AXI_awburst;
  input wire [7:0]S_AXI_awlen;
  output wire S_AXI_awready;
  input wire [2:0]S_AXI_awsize;
  input wire S_AXI_awvalid;
  input wire S_AXI_bready;
  output wire [1:0]S_AXI_bresp;
  output wire S_AXI_bvalid;
  output wire [SLAVE_WIDTH-1:0]S_AXI_rdata;
  output wire S_AXI_rlast;
  input wire S_AXI_rready;
  output wire [1:0]S_AXI_rresp;
  output wire S_AXI_rvalid;
  input wire [SLAVE_WIDTH-1:0]S_AXI_wdata;
  input wire S_AXI_wlast;
  output wire S_AXI_wready;
  input wire [STRB_S-1:0]S_AXI_wstrb;
  input wire S_AXI_wvalid;


readaxi_mk read_interconnect (
    .aclk           (aclk),
    .aresetn        (aresetn),

    .M_AXI_araddr   (M_AXI_araddr),
    .M_AXI_arburst  (M_AXI_arburst),
    .M_AXI_arlen    (M_AXI_arlen),
    .M_AXI_arready  (M_AXI_arready),
    .M_AXI_arsize   (M_AXI_arsize),
    .M_AXI_arvalid  (M_AXI_arvalid),

    .M_AXI_rdata    (M_AXI_rdata),
    .M_AXI_rlast    (M_AXI_rlast),
    .M_AXI_rready   (M_AXI_rready),
    .M_AXI_rresp    (M_AXI_rresp),
    .M_AXI_rvalid   (M_AXI_rvalid),

    .S_AXI_araddr   (S_AXI_araddr),
    .S_AXI_arburst  (S_AXI_arburst),
    .S_AXI_arlen    (S_AXI_arlen),
    .S_AXI_arready  (S_AXI_arready),
    .S_AXI_arsize   (S_AXI_arsize),
    .S_AXI_arvalid  (S_AXI_arvalid),

    .S_AXI_rdata    (S_AXI_rdata),
    .S_AXI_rlast    (S_AXI_rlast),
    .S_AXI_rready   (S_AXI_rready),
    .S_AXI_rresp    (S_AXI_rresp),
    .S_AXI_rvalid   (S_AXI_rvalid)
);

writeaxi_mk write_interconnect (
    .aclk           (aclk),
    .aresetn        (aresetn),

    .M_AXI_awaddr   (M_AXI_awaddr),
    .M_AXI_awburst  (M_AXI_awburst),
    .M_AXI_awlen    (M_AXI_awlen),
    .M_AXI_awready  (M_AXI_awready),
    .M_AXI_awsize   (M_AXI_awsize),
    .M_AXI_awvalid  (M_AXI_awvalid),

    .M_AXI_bready   (M_AXI_bready),
    .M_AXI_bresp    (M_AXI_bresp),
    .M_AXI_bvalid   (M_AXI_bvalid),

    .M_AXI_wdata    (M_AXI_wdata),
    .M_AXI_wlast    (M_AXI_wlast),
    .M_AXI_wready   (M_AXI_wready),
    .M_AXI_wstrb    (M_AXI_wstrb),
    .M_AXI_wvalid   (M_AXI_wvalid),

    .S_AXI_awaddr   (S_AXI_awaddr),
    .S_AXI_awburst  (S_AXI_awburst),
    .S_AXI_awlen    (S_AXI_awlen),
    .S_AXI_awready  (S_AXI_awready),
    .S_AXI_awsize   (S_AXI_awsize),
    .S_AXI_awvalid  (S_AXI_awvalid),

    .S_AXI_bready   (S_AXI_bready),
    .S_AXI_bresp    (S_AXI_bresp),
    .S_AXI_bvalid   (S_AXI_bvalid),

    .S_AXI_wdata    (S_AXI_wdata),
    .S_AXI_wlast    (S_AXI_wlast),
    .S_AXI_wready   (S_AXI_wready),
    .S_AXI_wstrb    (S_AXI_wstrb),
    .S_AXI_wvalid   (S_AXI_wvalid)
);
endmodule //interconnect