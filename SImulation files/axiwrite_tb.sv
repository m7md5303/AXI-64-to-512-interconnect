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
module axiwrite_tb;
    
  parameter ADDR_WIDTH = 31;
  parameter MASTER_WIDTH = 512;
  parameter SLAVE_WIDTH = 64;
  localparam STRB_M = MASTER_WIDTH/8;
  localparam STRB_S = SLAVE_WIDTH/8;
  localparam FIXED=2'b00;
  localparam INCR=2'b01;


  bit aclk;
  logic  aresetn;


  logic [ADDR_WIDTH-1:0] S_AXI_awaddr;
  logic [1:0] S_AXI_awburst;
  logic [7:0] S_AXI_awlen;
  logic S_AXI_awready;
  logic [2:0] S_AXI_awsize;
  logic S_AXI_awvalid;
  logic S_AXI_bready;
  logic [1:0] S_AXI_bresp;
  logic S_AXI_bvalid;
  logic [SLAVE_WIDTH-1:0] S_AXI_wdata;
  logic S_AXI_wlast;
  logic S_AXI_wready;
  logic [STRB_S-1:0] S_AXI_wstrb;
  logic S_AXI_wvalid;



  logic [ADDR_WIDTH-1:0] M_AXI_awaddr;
  logic [1:0] M_AXI_awburst;
  logic [7:0] M_AXI_awlen;
  logic M_AXI_awready;
  logic [2:0] M_AXI_awsize;
  logic M_AXI_awvalid;
  logic M_AXI_bready;
  logic [1:0] M_AXI_bresp;
  logic M_AXI_bvalid;
  logic [MASTER_WIDTH-1:0] M_AXI_wdata;
  logic M_AXI_wlast;
  logic M_AXI_wready;
  logic [STRB_M-1:0] M_AXI_wstrb;
  logic M_AXI_wvalid;

  writeaxi_mk DUT (.*);

  int err_count=0, crrct_count=0, awlen_constr_0=0, awlen_constr_1=0, count=0, subcount=0;
  int master_writes=0, slave_writes=0, ctrl_len=0, stall_cycles=0;
  bit [511:0] queue_ [32:0];
  bit [63:0] queue_stb [32:0];
  logic [5:0] write_idx;


  initial begin
    forever begin
        #1; aclk = ~aclk;
    end
  end


  initial begin
    S_AXI_awsize = 3;
    S_AXI_awburst = INCR;
    $display("starting reset test at %0t", $time);
    //reset test
    repeat(50) begin
        check_reset;
        if(M_AXI_awvalid || M_AXI_wvalid) begin
            $display("error reset at %0t", $time);
            err_count++;
        end
        else begin
            crrct_count++;
        end
    end
    aresetn =1;
    $display("starting low valid test at %0t", $time);
    //low valid test
    repeat(70) begin
        low_valid;
        if(M_AXI_wvalid || M_AXI_awvalid) begin
            $display("error low valid test at %0t", $time);
            err_count++;
        end
        else begin
            crrct_count++;
        end
        if(S_AXI_awready && !M_AXI_awready) begin
            $display("error low awready test at %0t", $time);
            err_count++;
        end
        else begin
            crrct_count++;
        end
    end

     $display("starting address translation test at %0t", $time);
     //repeat(70) addr_trans;

     $display("starting len translation test at %0t", $time);
     //repeat(250) len_trans;

    $display("starting reset test at %0t", $time);
    //reset test
    repeat(50) begin
        check_reset;
        if(M_AXI_awvalid || M_AXI_wvalid) begin
            $display("error reset at %0t", $time);
            err_count++;
        end
        else begin
            crrct_count++;
        end
    end
    aresetn =1;

    $display("starting burst test at %0t" , $time);
    repeat(700) burst_test;

    $display("starting stall test at %0t" , $time);
    repeat(700) stall_test;

    $display("starting continous test at %0t" , $time);
    repeat(700) cont_test;

    

    $display("total correct count: %0d, error count: %0d", crrct_count, err_count);
    repeat(20) @(negedge aclk);
    $stop;
  end
  

  task check_reset;
    aresetn =0;
    S_AXI_awvalid=$random;
    S_AXI_wvalid=$random;
    M_AXI_wready=$random;
    @(negedge aclk);
  endtask

  task low_valid;
    S_AXI_awvalid=0;
    M_AXI_awready=$random;
    S_AXI_wvalid=0;
    M_AXI_wready=$random;
    @(negedge aclk);
  endtask

  task addr_trans;
    aresetn =0;
    S_AXI_awvalid=0;
    @(negedge aclk);
    aresetn =1;
    S_AXI_awvalid=1;
    M_AXI_awready=1;
    S_AXI_awaddr=$random;
    @(negedge aclk);
    if(M_AXI_awaddr !== {S_AXI_awaddr[30:6] , {6{1'b0}}}) begin
        $display("error addr translation at %0t", $time);
        err_count++;
    end
    else begin
        crrct_count++;
    end
  endtask

  task len_trans;
    aresetn =0;
    S_AXI_awvalid=0;
    @(negedge aclk);
    aresetn =1;
    S_AXI_awvalid=1;
    M_AXI_awready=1;
    S_AXI_awaddr = $random;
    if((((awlen_constr_1)/(awlen_constr_0+awlen_constr_1))*100)>50) begin
      S_AXI_awlen = $urandom_range(0,7);
      awlen_constr_0++;
    end
    else begin
      S_AXI_awlen = $urandom_range(8,255);
      awlen_constr_1++;
    end
    repeat (1) @(negedge aclk);
    if((S_AXI_awlen+1)<8) begin
      if(S_AXI_awlen+1 + S_AXI_awaddr[5:3]>8) begin
        if(M_AXI_awlen!==1) begin
          $display("len error at %0t", $time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
      end
      else begin
        if(M_AXI_awlen!==0) begin
          $display("len error at %0t", $time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
      end
    end
    else begin
      if(!S_AXI_awaddr[5:3]) begin
        if(M_AXI_awlen!== (((S_AXI_awlen+1)/8)-1) + |((S_AXI_awlen[2:0]+1) &4'b0111)) begin
          $display("len error at %0t, expected is %0d got %0d", $time, ((((S_AXI_awlen+1)/8)-1) + |(S_AXI_awlen[2:0])), M_AXI_awlen);
          err_count++;
        end
        else begin
          crrct_count++;
        end
      end
      else if(M_AXI_awlen!== ((((S_AXI_awlen+1)/8)-1) + (((((S_AXI_awlen+1)/8)-1))*8 + 8 + 8-S_AXI_awaddr[5:3]<S_AXI_awlen+1) + (((((S_AXI_awlen+1)/8)-1))*8 + 8-S_AXI_awaddr[5:3]<S_AXI_awlen+1))) begin
        $display("len error at %0t, expected is %0d got %0d", $time,((((S_AXI_awlen+1)/8)-1) + (((((S_AXI_awlen+1)/8)-1))*8 + 8 + 8-S_AXI_awaddr[5:3]<S_AXI_awlen+1) + (+ ((((S_AXI_awlen+1)/8)-1))*8 + 8-S_AXI_awaddr[5:3]<S_AXI_awlen+1)), M_AXI_awlen);
        err_count++;
      end
      else begin
        crrct_count++;
      end
    end
  endtask

  
  task burst_test;
    aresetn=0;
    S_AXI_awvalid=0;
    M_AXI_bresp=0;
    M_AXI_bvalid=0;
    S_AXI_wvalid=0;
    master_writes=0;
    slave_writes=0;
    M_AXI_wready=1;
    subcount=0;
    count=0;
    for (int i=0; i<33; i++) begin
      queue_[i]=0;
      queue_stb[i]=0;
    end
    @(negedge aclk);
    aresetn =1;
    S_AXI_awvalid=1;
    M_AXI_awready=1;
    S_AXI_awaddr=$random;
    S_AXI_awlen=$random;  
    @(negedge aclk);
    subcount = S_AXI_awaddr[5:3];
    S_AXI_awvalid=0;
    ctrl_len = calc_len(S_AXI_awlen , INCR , S_AXI_awaddr);
    @(negedge aclk);
    repeat(S_AXI_awlen+1) begin
      S_AXI_wdata = {$random, $random};
      S_AXI_wvalid=1;
      S_AXI_wstrb=$random;
      if(!slave_writes) begin
        repeat(1) @(negedge aclk);
      end
      queue_[count][64*subcount +: 64] = S_AXI_wdata;
      queue_stb[count][8*subcount +: 8] = S_AXI_wstrb;
      subcount++;
      slave_writes++;
      if(slave_writes == S_AXI_awlen+1) begin
        S_AXI_wlast=1;
        @(negedge aclk); 
        S_AXI_wlast=0;
        S_AXI_wvalid=0;
      end
      else begin
        S_AXI_wlast=0;
        @(negedge aclk);
      end
      
      if(subcount==8) begin
        subcount=0;
        count++;
      end
    end
    wait(M_AXI_wvalid&&M_AXI_wready);
    repeat(ctrl_len+1) begin
      @(negedge aclk);
      if(M_AXI_wvalid) begin
        if(M_AXI_wdata !== queue_[master_writes]) begin
          $display("write error at %0t",$time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
        if(M_AXI_wstrb !== queue_stb[master_writes]) begin
          $display("write strobe error at %0t",$time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
        if(master_writes==ctrl_len) begin
          if(!M_AXI_wlast && M_AXI_wvalid) begin
            $display("write last error at %0t",$time);
            err_count++;
          end
          else begin
            crrct_count++;
          end
          @(negedge aclk);
        end 
      master_writes++;
      end
    end
    M_AXI_bvalid=1;
    S_AXI_bready=1;
    M_AXI_bresp=0;
    @(negedge aclk);
    if(!S_AXI_bvalid) begin
      $display("write resp error at %0t",$time);
      err_count++;
    end
    else begin
      crrct_count++;
    end
  endtask


  task  cont_test;
    S_AXI_awvalid=0;
    M_AXI_bresp=0;
    M_AXI_bvalid=0;
    S_AXI_wvalid=0;
    master_writes=0;
    slave_writes=0;
    M_AXI_wready=1;
    subcount=0;
    count=0;
    for (int i=0; i<33; i++) begin
      queue_[i]=0;
      queue_stb[i]=0;
    end
    @(negedge aclk);
    aresetn =1;
    S_AXI_awvalid=1;
    M_AXI_awready=1;
    S_AXI_awaddr=$random;
    S_AXI_awlen=$random;  
    @(negedge aclk);
    subcount = S_AXI_awaddr[5:3];
    S_AXI_awvalid=0;
    ctrl_len = calc_len(S_AXI_awlen , INCR , S_AXI_awaddr);
    @(negedge aclk);
    repeat(S_AXI_awlen+1) begin
      S_AXI_wdata = {$random, $random};
      S_AXI_wvalid=1;
      S_AXI_wstrb=$random;
      if(!slave_writes) begin
        repeat(1) @(negedge aclk);
      end
      queue_[count][64*subcount +: 64] = S_AXI_wdata;
      queue_stb[count][8*subcount +: 8] = S_AXI_wstrb;
      subcount++;
      slave_writes++;
      if(slave_writes == S_AXI_awlen+1) begin
        S_AXI_wlast=1;
        @(negedge aclk); 
        S_AXI_wlast=0;
        S_AXI_wvalid=0;
      end
      else begin
        S_AXI_wlast=0;
        @(negedge aclk);
      end
      
      if(subcount==8) begin
        subcount=0;
        count++;
      end
    end
    wait(M_AXI_wvalid&&M_AXI_wready);
    repeat(ctrl_len+1) begin
      @(negedge aclk);
      if(M_AXI_wvalid) begin
        if(M_AXI_wdata !== queue_[master_writes]) begin
          $display("write error at %0t",$time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
        if(M_AXI_wstrb !== queue_stb[master_writes]) begin
          $display("write strobe error at %0t",$time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
        if(master_writes==ctrl_len) begin
          if(!M_AXI_wlast && M_AXI_wvalid) begin
            $display("write last error at %0t",$time);
            err_count++;
          end
          else begin
            crrct_count++;
          end
          @(negedge aclk);
        end 
      master_writes++;
      end
    end
    M_AXI_bvalid=1;
    S_AXI_bready=1;
    M_AXI_bresp=0;
    @(negedge aclk);
    if(!S_AXI_bvalid) begin
      $display("write resp error at %0t",$time);
      err_count++;
    end
    else begin
      crrct_count++;
    end
  endtask


  task stall_test;
    aresetn=0;
    S_AXI_awvalid=0;
    M_AXI_bresp=0;
    M_AXI_bvalid=0;
    S_AXI_wvalid=0;
    master_writes=0;
    slave_writes=0;
    stall_cycles=0;
    M_AXI_wready=1;
    subcount=0;
    count=0;
    for (int i=0; i<33; i++) begin
      queue_[i]=0;
      queue_stb[i]=0;
    end
    @(negedge aclk);
    aresetn =1;
    stall_cycles=$urandom_range(1,10);
    S_AXI_awvalid=1;
    M_AXI_awready=1;
    S_AXI_awaddr=$random;
    S_AXI_awlen=$random;  
    @(negedge aclk);
    subcount = S_AXI_awaddr[5:3];
    S_AXI_awvalid=0;
    ctrl_len = calc_len(S_AXI_awlen , INCR , S_AXI_awaddr);
    @(negedge aclk);
    repeat(S_AXI_awlen+1) begin
      S_AXI_wdata = {$random, $random};
      S_AXI_wvalid=1;
      S_AXI_wstrb=$random;
      if(!slave_writes) begin
        repeat(1) @(negedge aclk);
      end
      queue_[count][64*subcount +: 64] = S_AXI_wdata;
      queue_stb[count][8*subcount +: 8] = S_AXI_wstrb;
      subcount++;
      slave_writes++;
      if(slave_writes == S_AXI_awlen+1) begin
        S_AXI_wlast=1;
        M_AXI_wready=0;
        @(negedge aclk); 
        M_AXI_wready=1;
        S_AXI_wlast=0;
        S_AXI_wvalid=0;
      end
      else begin
        S_AXI_wlast=0;
        M_AXI_wready=1;
        @(negedge aclk);
        S_AXI_wvalid=0;
        repeat(10) @(negedge aclk);
      end
      
      if(subcount==8) begin
        subcount=0;
        count++;
      end
    end
    wait(M_AXI_wvalid);
    @(negedge aclk);
    while(master_writes<ctrl_len) begin
      if(M_AXI_wvalid && M_AXI_wready) begin
        if(M_AXI_wdata !== queue_[master_writes]) begin
          $display("write error at %0t",$time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
        if(M_AXI_wstrb !== queue_stb[master_writes]) begin
          $display("write strobe error at %0t",$time);
          err_count++;
        end
        else begin
          crrct_count++;
        end
        if(master_writes==ctrl_len) begin
          if(!M_AXI_wlast && M_AXI_wvalid) begin
            $display("write last error at %0t",$time);
            err_count++;
          end
          else begin
            crrct_count++;
          end
        end 
        master_writes++;
        M_AXI_wready=0;
        @(negedge aclk);
      end
      M_AXI_wready=1;
      @(negedge aclk);
    end
    M_AXI_bvalid=1;
    S_AXI_bready=1;
    M_AXI_bresp=0;
    @(negedge aclk);
    if(!S_AXI_bvalid) begin
      $display("write resp error at %0t",$time);
      err_count++;
    end
    else begin
      crrct_count++;
    end
  endtask


  function automatic [7:0] calc_len;
    input [7:0] orig_len_f;
    input [1:0] burst_type_f;
    input [30:0] araddr_in_f;
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

endmodule