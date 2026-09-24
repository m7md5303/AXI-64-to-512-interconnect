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
module readaxi_mk (aclk,
    aresetn,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arlen,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_rdata,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arlen,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_rdata,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid);

//declaring parameters
  parameter ADDR_WIDTH = 31;
  parameter MASTER_WIDTH = 512;
  parameter SLAVE_WIDTH = 64;
  localparam STRB_M = MASTER_WIDTH/8;
  localparam STRB_S = SLAVE_WIDTH/8;
  localparam FIXED=2'b00;
  localparam INCR=2'b01;


  //declaring ports
  input wire aclk, aresetn;

  //declaring AXI Slave ports
  input wire [ADDR_WIDTH-1:0] S_AXI_araddr;
  input wire [1:0] S_AXI_arburst;
  input wire [7:0] S_AXI_arlen;
  output wire S_AXI_arready;
  input wire [2:0] S_AXI_arsize;
  input wire S_AXI_arvalid;
  output wire [SLAVE_WIDTH-1:0] S_AXI_rdata;
  output wire S_AXI_rlast;
  input wire S_AXI_rready;
  output wire [1:0] S_AXI_rresp;
  output wire S_AXI_rvalid;

  //declaring AXI Master ports
  output wire [ADDR_WIDTH-1:0] M_AXI_araddr;
  output wire [1:0] M_AXI_arburst;
  output wire [7:0] M_AXI_arlen;
  input wire M_AXI_arready;
  output wire [2:0] M_AXI_arsize;
  output wire M_AXI_arvalid;
  input wire [MASTER_WIDTH-1:0] M_AXI_rdata;
  input wire M_AXI_rlast;
  output wire M_AXI_rready;
  input wire [1:0] M_AXI_rresp;
  input wire M_AXI_rvalid;

  //placeholders
  reg [ADDR_WIDTH-1:0] M_AXI_araddr_reg;
  reg [1:0] M_AXI_arburst_reg;
  reg [7:0] M_AXI_arlen_reg;
  reg [2:0] M_AXI_arsize_reg;
  reg M_AXI_arvalid_reg;
  reg M_AXI_rready_reg;
  reg S_AXI_arready_reg;
  reg [SLAVE_WIDTH-1:0] S_AXI_rdata_reg;
  reg S_AXI_rlast_reg;
  reg [1:0] S_AXI_rresp_reg;
  reg S_AXI_rvalid_reg;

  //AXI-related registers
  reg [ADDR_WIDTH-1:0] araddr_reg;
  reg finished_read;
  reg [7:0] read_transactions, rec_read_transactions, orig_len;
  reg [1:0] active_burst;
  reg [ADDR_WIDTH-1:0] cpu_orig_address;
  reg [7:0] sent_beats;
  reg subbeat_ack;
  reg [2:0] covered_subbeats;
  reg done_conversion;
  reg first_transaction;


  //Receiving FIFO
  reg reset_fifo_n;
  wire full_fifo, empty_fifo;
  reg wen_fifo;
  reg rready_fifo;
  wire [511:0] out_data_fifo;
  reg [511:0] in_data_fifo;

  scfifo_mk #(.FIFO_DEPTH(33),.DATA_WIDTH(512)) read_fifo (.clk(aclk), .rst_n(reset_fifo_n), 
  .in_data(in_data_fifo), .out_data(out_data_fifo), .full(full_fifo), .empty(empty_fifo), 
  .wen(wen_fifo), .rready(rready_fifo));

  //Read Response FIFO
  wire full_fifo_resp, empty_fifo_resp;
  reg wen_fifo_resp;
  reg rready_fifo_resp;
  wire [1:0] out_data_fifo_resp;
  reg [1:0] in_data_fifo_resp;

  scfifo_mk #(.FIFO_DEPTH(33),.DATA_WIDTH(2)) read_fifo_resp (.clk(aclk), .rst_n(reset_fifo_n), 
  .in_data(in_data_fifo_resp), .out_data(out_data_fifo_resp), .full(full_fifo_resp), .empty(empty_fifo_resp), 
  .wen(wen_fifo_resp), .rready(rready_fifo_resp));


  //Read Strobe FIFO
  wire full_fifo_stb, empty_fifo_stb;
  reg wen_fifo_stb;
  reg rready_fifo_stb;
  wire [7:0] out_data_fifo_stb;
  reg [7:0] in_data_fifo_stb;
  reg read_strobe [7:0];

  scfifo_mk #(.FIFO_DEPTH(33),.DATA_WIDTH(8)) read_fifo_stb (.clk(aclk), .rst_n(reset_fifo_n), 
  .in_data(in_data_fifo_stb), .out_data(out_data_fifo_stb), .full(full_fifo_stb), .empty(empty_fifo_stb), 
  .wen(wen_fifo_stb), .rready(rready_fifo_stb));

  //data FIFO
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      in_data_fifo <= 0;
    end
    else begin
      in_data_fifo <= M_AXI_rdata;
    end
  end
  always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      wen_fifo<=1'b0;
    end
    else begin
      if (rec_read_transactions<= read_transactions ) begin
        wen_fifo<= M_AXI_rready_reg && M_AXI_rvalid;
      end
      else begin
        wen_fifo<=1'b0;
      end
    end
  end

  //resp FIFO
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      in_data_fifo_resp <= M_AXI_rresp;
    end
    else begin
      in_data_fifo_resp <= M_AXI_rresp;
    end
  end
  always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      wen_fifo_resp<=1'b0;
    end
    else begin
      if (rec_read_transactions<= read_transactions ) begin
        wen_fifo_resp<= M_AXI_rready_reg && M_AXI_rvalid;
      end
      else begin
        wen_fifo_resp<=1'b0;
      end
    end
  end

  //strobe FIFO
  always @(*) begin
    in_data_fifo_stb = {read_strobe[7],read_strobe[6],read_strobe[5],read_strobe[4],read_strobe[3],read_strobe[2],read_strobe[1],read_strobe[0]};
  end
  always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      wen_fifo_stb<=1'b0;
    end
    else begin
      if (rec_read_transactions<= read_transactions ) begin
        wen_fifo_stb<= M_AXI_rready_reg && M_AXI_rvalid;
      end
      else begin
        wen_fifo_stb<=1'b0;
      end
    end
  end
  integer i,j,k,l,m,n;
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      for(i =0;i<8;i=i+1) begin
        read_strobe[i]<=0;
      end
    end
    else begin
      if(rec_read_transactions<= read_transactions && M_AXI_rready_reg && M_AXI_rvalid) begin
        case (active_burst)
          FIXED: begin
            read_strobe[cpu_orig_address[5:3]] <= 1'b1;
            for(j=0;j<8;j=j+1) begin
              if(j!=cpu_orig_address[5:3]) begin
                read_strobe[j]<=1'b0;
              end
            end
          end
          INCR: begin
            if(M_AXI_arlen_reg==0) begin
              for(k=0;k<8;k=k+1) begin
                if(k <= orig_len && (k+cpu_orig_address[5:3]<8)) begin
                  read_strobe[cpu_orig_address[5:3]+k] <= 1'b1;
                end
                else begin
                  read_strobe[cpu_orig_address[5:3]+k] <= 1'b0;
                end
              end
            end
            else if(rec_read_transactions==0) begin
              for(l=0;l<8;l=l+1) begin
                if(l>=cpu_orig_address[5:3]) begin
                  read_strobe[l] <= 1'b1;
                end
                else begin
                  read_strobe[l] <= 1'b0;
                end
              end    
            end
            else if(M_AXI_rlast) begin
              for(m=0;m<8;m=m+1) begin
                if(!cpu_orig_address[5:3]) begin
                  if(m < ( orig_len+1 - ((rec_read_transactions)<<3))) begin
                    read_strobe[m]<=1'b1;
                  end
                  else begin
                    read_strobe[m]<=1'b0;
                  end  
                end
                else begin
                  if(m < ( orig_len+1 - (((rec_read_transactions-1))<<3) - ((4'd8 - cpu_orig_address[5:3] )&4'b0111))) begin
                    read_strobe[m]<=1'b1;
                  end
                  else begin
                    read_strobe[m]<=1'b0;
                  end 
                end
              end
            end
            else begin
              for(n=0;n<8;n=n+1) begin
                read_strobe[n]<=1'b1;
              end
            end
          end
          default: begin
            for(n=0;n<8;n=n+1) begin
              read_strobe[n]<=1'b0;
            end
          end
        endcase
      end
      else if(M_AXI_arvalid_reg&&M_AXI_arready) begin
        for(n=0;n<8;n=n+1) begin
          read_strobe[n]<=1'b0;
        end  
      end
    end
  end
  //counting desired reads
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      read_transactions<=0;
    end
    else begin
      if(M_AXI_arready && M_AXI_arvalid_reg) begin
        read_transactions<=calc_len(S_AXI_arlen, S_AXI_arburst, S_AXI_araddr);
      end
    end
  end
  //counting successful reads
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      rec_read_transactions<=0;
    end
    else begin
      if(M_AXI_arready && M_AXI_arvalid_reg) begin
        rec_read_transactions<=0;
      end
      else if(rec_read_transactions<=read_transactions) begin
        if(M_AXI_rvalid && M_AXI_rready_reg) begin
          rec_read_transactions<=rec_read_transactions+1'b1;
        end
      end
    end
  end
  //finished a single read
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      finished_read<=0;
    end
    else begin
      if(M_AXI_arready && M_AXI_arvalid_reg) begin
        finished_read<=0;
      end
      else if(rec_read_transactions== read_transactions + 1'b1) begin
        finished_read<=1;
      end
    end
  end
  //sending the read beats
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      sent_beats<=0;
    end
    else begin
      if(S_AXI_rvalid_reg && S_AXI_rready && !done_conversion) begin
        if(sent_beats == orig_len) begin
          sent_beats<=0;
        end
        else begin
          sent_beats<=sent_beats+1'b1;
        end
      end
    end
  end
  //retrieving data from FIFO
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      rready_fifo<=1'b0;
      rready_fifo_stb<=1'b0;
      rready_fifo_resp<=1'b0;
    end
    else begin
      if(finished_read && !done_conversion) begin
        if(sent_beats <= orig_len && covered_subbeats ==7 && S_AXI_rready) begin
          rready_fifo<=1'b1;
          rready_fifo_stb<=1'b1;
          rready_fifo_resp<=1'b1;  
        end
        else begin
          rready_fifo<=1'b0;
          rready_fifo_stb<=1'b0;  
          rready_fifo_resp<=1'b0;
        end
      end
      else if(wen_fifo && rec_read_transactions==1 ) begin
        rready_fifo<=1'b1;
        rready_fifo_stb<=1'b1;
        rready_fifo_resp<=1'b1;         
      end
      else begin
        rready_fifo<=1'b0;
        rready_fifo_stb<=1'b0;
        rready_fifo_resp<=1'b0;    
      end
    end
  end
  //subbeat_acknowledgement
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      subbeat_ack<=1'b0;
    end
    else begin
      subbeat_ack <= (rready_fifo && rready_fifo_resp && rready_fifo_stb && !wen_fifo && finished_read);
    end
  end
  //covered_subbeats
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      covered_subbeats<=3'b0;
    end
    else begin
      if(finished_read  && !done_conversion) begin
        if(covered_subbeats==0 && sent_beats<=orig_len && ((sent_beats==0&&!S_AXI_rvalid) || subbeat_ack)) begin
          if(S_AXI_rready) begin
            covered_subbeats<=covered_subbeats+1'b1;
          end
        end
        else if(covered_subbeats>3'b0 && sent_beats<=orig_len && !S_AXI_rlast_reg) begin
          if(S_AXI_rready) begin
            covered_subbeats<=covered_subbeats+1'b1;
          end
        end
        else if(orig_len==0 && covered_subbeats<cpu_orig_address[5:3]) begin
          if(S_AXI_rready) begin
            covered_subbeats<=covered_subbeats+1'b1;
          end 
        end
        else if(S_AXI_rlast_reg&&S_AXI_rready&&S_AXI_rvalid_reg) begin
          covered_subbeats<=3'b0;
        end
      end
      else begin
        covered_subbeats<=3'b0;
      end
    end
  end
  //sending data
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      S_AXI_rvalid_reg<=1'b0;
      S_AXI_rdata_reg<=0;
      S_AXI_rresp_reg<=0;
    end
    else begin
      if(covered_subbeats==0&& (subbeat_ack || (finished_read&&sent_beats==0)) && !done_conversion) begin
        if(out_data_fifo_stb[covered_subbeats]) begin
          S_AXI_rvalid_reg<=1'b1;
          S_AXI_rresp_reg<=out_data_fifo_resp;
          S_AXI_rdata_reg<=out_data_fifo[covered_subbeats*64 +: 64];
        end
        else begin
          S_AXI_rvalid_reg<=1'b0;
        end
      end
      else if(finished_read && covered_subbeats>0 && sent_beats<=orig_len && !done_conversion && !(S_AXI_rlast_reg&&S_AXI_rready&&S_AXI_rvalid_reg)) begin
        if(out_data_fifo_stb[covered_subbeats]) begin
          S_AXI_rvalid_reg<=1'b1;
          S_AXI_rresp_reg<=out_data_fifo_resp;
          S_AXI_rdata_reg<=out_data_fifo[covered_subbeats*64 +: 64];
        end
        else begin
          S_AXI_rvalid_reg<=1'b0;
        end
      end
      else begin
          S_AXI_rvalid_reg<=1'b0;
      end
    end
  end
  //rlast
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      S_AXI_rlast_reg<=1'b0;
    end
    else begin
      if(S_AXI_rvalid_reg && S_AXI_rready && S_AXI_rlast_reg) begin
        S_AXI_rlast_reg<=1'b0;
      end
      else if(finished_read && orig_len==0 && !done_conversion && !(S_AXI_rvalid_reg && S_AXI_rready && S_AXI_rlast_reg)) begin
        S_AXI_rlast_reg<=1'b1;
      end
      else if(sent_beats==orig_len-1 && finished_read && !done_conversion && S_AXI_rvalid_reg && S_AXI_rready) begin
        S_AXI_rlast_reg<=1'b1;
      end
      else if(done_conversion) begin
        S_AXI_rlast_reg<=1'b0;
      end
    end
  end
  //done conversion
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      done_conversion<=1'b0;
    end
    else begin
      if(sent_beats==orig_len && S_AXI_rready && S_AXI_rvalid_reg) begin
        done_conversion<=1'b1;
      end
      else if(!finished_read) begin
        done_conversion<=1'b0;
      end
    end
  end
  //araddr
  always @(posedge aclk or negedge aresetn) begin
      if(!aresetn) begin
        M_AXI_araddr_reg<=0;
      end
      else begin
        M_AXI_araddr_reg<={S_AXI_araddr[30:6] , {6{1'b0}}};
      end
  end
  //cpu_orig_address
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      cpu_orig_address<=0;
    end
    else begin
      if(M_AXI_arready && M_AXI_arvalid_reg) begin
        cpu_orig_address<=S_AXI_araddr;
      end
    end
  end
  //arready
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      S_AXI_arready_reg<=0;
    end
    else begin
      if(done_conversion || first_transaction) begin
        S_AXI_arready_reg<=M_AXI_arready;
      end
      else begin
        S_AXI_arready_reg<=0;
      end
    end
  end
  //arvalid
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      M_AXI_arvalid_reg<=0;
    end
    else begin
      if(done_conversion || first_transaction) begin
        M_AXI_arvalid_reg<=S_AXI_arvalid;
      end
      else begin
        M_AXI_arvalid_reg<=0;
      end
    end
  end
  //arburst
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      M_AXI_arburst_reg<=0;
    end
    else begin
      M_AXI_arburst_reg<=S_AXI_arburst;
    end
  end
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      active_burst<=0;
    end
    else begin
      if(M_AXI_arready && M_AXI_arvalid_reg) begin
        active_burst<=M_AXI_arburst_reg;
      end
    end
  end
  //arlen
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      orig_len<=0;
    end
    else begin
      if(M_AXI_arvalid_reg && M_AXI_arready) begin
        orig_len<=S_AXI_arlen;
      end
    end
  end
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      M_AXI_arlen_reg<=0;
    end
    else begin
      M_AXI_arlen_reg<=calc_len(S_AXI_arlen, S_AXI_arburst, S_AXI_araddr);
    end
  end
  //arsize
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      M_AXI_arsize_reg<=0;
    end
    else begin
      M_AXI_arsize_reg<=3'h6;
    end
  end
  //rready
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      M_AXI_rready_reg<=0;
    end
    else begin
      M_AXI_rready_reg<=S_AXI_rready;
    end
  end

  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      first_transaction<=1'b0;
    end
    else begin
      first_transaction<=1'b1;
    end
  end
  //packing
  assign S_AXI_rdata = S_AXI_rdata_reg;
  assign S_AXI_rlast = S_AXI_rlast_reg;
  assign S_AXI_rvalid = S_AXI_rvalid_reg;
  assign S_AXI_rresp = S_AXI_rresp_reg;
  assign S_AXI_arready = S_AXI_arready_reg;
  assign M_AXI_arlen = M_AXI_arlen_reg;
  assign M_AXI_rready = M_AXI_rready_reg;
  assign M_AXI_arsize = M_AXI_arsize_reg;
  assign M_AXI_araddr = M_AXI_araddr_reg;
  assign M_AXI_arburst = M_AXI_arburst_reg;
  assign M_AXI_arvalid = M_AXI_arvalid_reg;
  always @(*) begin
    if(M_AXI_arvalid_reg&&M_AXI_arready) begin
      reset_fifo_n=0;
    end
    else begin
      reset_fifo_n = aresetn;
    end
  end
  //translating arlen
  function automatic [7:0] calc_len;
    input wire [7:0] orig_len_f;
    input wire [1:0] burst_type_f;
    input wire [30:0] araddr_in_f;
    reg [7:0] new_len;
    reg [8:0] total_len;
    begin
      total_len = orig_len_f+1'b1;
      new_len = ((total_len)>>3) -1'b1;
      if(burst_type_f==0) begin
        calc_len = orig_len_f;
      end
      else if(total_len>8) begin
        if(!araddr_in_f[5:3]) begin
          calc_len = new_len +  |(total_len[2:0]);
        end
        else if(((4'd8-araddr_in_f[5:3]) + (new_len<<3) + 4'd8 <total_len))begin
          calc_len = new_len +2'b10;
        end
        else if(((4'd8-araddr_in_f[5:3]) + (new_len<<3)  <total_len))begin
          calc_len = new_len +1'b1;
        end
        else begin
          calc_len = new_len;
        end
      end
      else if(total_len<=8) begin
        calc_len = ((araddr_in_f[5:3]+ total_len) > 8);
      end
      else begin
        calc_len = 8'b0;
      end
    end
  endfunction
endmodule //downsizer_mk