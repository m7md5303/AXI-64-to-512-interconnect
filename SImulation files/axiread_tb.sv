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
module axiread_tb;


  parameter ADDR_WIDTH = 31;
  parameter MASTER_WIDTH = 512;
  parameter SLAVE_WIDTH = 64;
  localparam STRB_M = MASTER_WIDTH/8;
  localparam STRB_S = SLAVE_WIDTH/8;
  localparam FIXED=2'b00;
  localparam INCR=2'b01;


  bit aclk;
  logic  aresetn;

  logic [ADDR_WIDTH-1:0] S_AXI_araddr;
  logic [1:0] S_AXI_arburst;
  logic [7:0] S_AXI_arlen;
  logic S_AXI_arready;
  logic [2:0] S_AXI_arsize;
  logic S_AXI_arvalid;
  logic [SLAVE_WIDTH-1:0] S_AXI_rdata;
  logic S_AXI_rlast;
  logic S_AXI_rready;
  logic [1:0] S_AXI_rresp;
  logic S_AXI_rvalid;

  logic [ADDR_WIDTH-1:0] M_AXI_araddr;
  logic [1:0] M_AXI_arburst;
  logic [7:0] M_AXI_arlen;
  logic M_AXI_arready;
  logic [2:0] M_AXI_arsize;
  logic M_AXI_arvalid;
  logic [MASTER_WIDTH-1:0] M_AXI_rdata;
  logic M_AXI_rlast;
  logic M_AXI_rready;
  logic [1:0] M_AXI_rresp;
  logic M_AXI_rvalid;

  int err_count=0, crrct_count=0, arlen_constr_0=0, arlen_constr_1=1, read_beats=0;
  logic start_reading=0;
  int ctrl_len, master_reads=0, slave_reads=0;
  logic [511:0] queue_ [32:0];
  int count=0;
  logic [2:0] subcount=0;
  int stall_cycles=0,loopcnt=0;
 
  readaxi_mk DUT (.*);

  initial begin
    forever begin
        #1; aclk=~aclk;
    end
  end

  initial begin
    //reset test
     $display("start reset test at %0t",$time);
    repeat (10) begin
      reset_test;
      if(M_AXI_arvalid||S_AXI_rdata||M_AXI_rready||S_AXI_arready) begin
        $display("error at %0t: reset error", $time);
        err_count++;
      end
      else begin
        crrct_count++;
      end 
    end
    aresetn = 1;
    //arvalid test
     $display("start behavior at low valid at %0t",$time);
    repeat(30) begin
      arvalid_test;
      if(M_AXI_arvalid||S_AXI_rvalid)begin
        $display("error at %0t: low arvalid error", $time);
        err_count++;
      end
      else begin 
        crrct_count++;
      end
    end 
   //araddr and arlen test
    $display("start address transalation and arlen interpretation at %0t",$time);
   repeat(85) begin
     addr_len_test;
     if(M_AXI_arready) begin
      @(negedge aclk);
      @(negedge aclk);
      if(M_AXI_araddr !=={S_AXI_araddr[30:6], {6{1'b0}}}) begin
        $display("addr error at %0t", $time);
        err_count++;
      end
      else begin
        crrct_count++;
      end
      if((S_AXI_arlen+1)<8) begin
        if(S_AXI_arlen+1 + S_AXI_araddr[5:3]>8) begin
          if(M_AXI_arlen!==1) begin
            $display("len error at %0t", $time);
            err_count++;
          end
          else begin
            crrct_count++;
          end
        end
        else begin
          if(M_AXI_arlen!==0) begin
            $display("len error at %0t", $time);
            err_count++;
          end
          else begin
            crrct_count++;
          end
        end
      end
      else begin
        if(!S_AXI_araddr[5:3]) begin
          if(M_AXI_arlen!== (((S_AXI_arlen+1)/8)-1) + |(S_AXI_arlen[2:0]+1)) begin
            $display("len error at %0t, expected is %0d got %0d", $time, ((((S_AXI_arlen+1)/8)-1) + |(S_AXI_arlen[2:0])), M_AXI_arlen);
            err_count++;
          end
          else begin
            crrct_count++;
          end
        end
        if(M_AXI_arlen!== ((((S_AXI_arlen+1)/8)-1) + (((((S_AXI_arlen+1)/8)-1))*8 + 8 + 8-S_AXI_araddr[5:3]<S_AXI_arlen+1) + (((((S_AXI_arlen+1)/8)-1))*8 + 8-S_AXI_araddr[5:3]<S_AXI_arlen+1))) begin
          $display("len error at %0t, expected is %0d got %0d", $time,((((S_AXI_arlen+1)/8)-1) + (((((S_AXI_arlen+1)/8)-1))*8 + 8 + 8-S_AXI_araddr[5:3]<S_AXI_arlen+1) + (+ ((((S_AXI_arlen+1)/8)-1))*8 + 8-S_AXI_araddr[5:3]<S_AXI_arlen+1)), M_AXI_arlen);
          err_count++;
        end
        else begin
          crrct_count++;
        end
      end
     end
   end
   //different number of bursts
   $display("start bursts_test at %0t",$time);
   repeat(300) bursts_test;
   $display("start cont_test at %0t",$time);
   repeat (300) cont_test;
   $display("start stall_test at %0t",$time);
   repeat(300) stall_test;


    repeat(20) @(negedge aclk);
    $display("Test finished number of passed tests : %0d , failed tests : %0d", crrct_count, err_count);
    $stop;
  end


  assign S_AXI_arsize = 3;
  task reset_test;
    aresetn =0;
    S_AXI_arvalid=$random;
    M_AXI_rvalid =$random;
    @(negedge aclk);
  endtask
  task arvalid_test;
    S_AXI_arvalid=0;
    M_AXI_arready=$random;
    S_AXI_rready=0;
    M_AXI_rvalid=$random;
    @(negedge aclk);
  endtask
  task addr_len_test;
    aresetn =0;
    S_AXI_arvalid=0;
    @(negedge aclk);
    aresetn =1;
    S_AXI_arvalid=1;
    M_AXI_arready=$random;
    S_AXI_araddr = $random;
    S_AXI_arburst = INCR;
    if((((arlen_constr_1)/(arlen_constr_0+arlen_constr_1))*100)>50) begin
      S_AXI_arlen = $urandom_range(0,7);
      arlen_constr_0++;
    end
    else begin
      S_AXI_arlen = $urandom_range(8,255);
      arlen_constr_1++;
    end
    @(negedge aclk);
  endtask
  task bursts_test;
    aresetn =0;
    S_AXI_arvalid=0;
    start_reading=0;
    M_AXI_rresp=0;
    M_AXI_rvalid=0;
    S_AXI_rready=0;
    @(negedge aclk);
    aresetn=1;
    S_AXI_arvalid =1;  
    S_AXI_araddr={$random,3'b0};
    S_AXI_arburst=INCR;
    M_AXI_arready=1;
    S_AXI_arlen=$random;
    count=0;
    subcount=0;
    @(negedge aclk);
    wait(S_AXI_arready && M_AXI_arvalid);
    S_AXI_arvalid =0;
    start_reading=1;
    master_reads=0;
    slave_reads=0;
    ctrl_len = calc_len(S_AXI_arlen , INCR , S_AXI_araddr);
    @(negedge aclk);
    repeat(ctrl_len+1) begin
      M_AXI_rvalid=1;
      M_AXI_rdata={ $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random };
      S_AXI_rready=1;
      M_AXI_rresp=0;
      wait(M_AXI_rready&&M_AXI_rvalid);
      master_reads++;
      if(master_reads == ctrl_len+1) begin
        M_AXI_rlast=1;
        @(negedge aclk); 
      end
      else begin
        M_AXI_rlast=0;
      end
      if(master_reads==1) begin
        @(negedge aclk); @(negedge aclk);
      end
      else begin 
        @(negedge aclk);
      end 
      queue_[count] = M_AXI_rdata;
      count++;
      //wait(M_AXI_rready&&S_AXI_rvalid); 
    end  
    count=0;
    M_AXI_rvalid=0;
    M_AXI_rlast=0;
    while(slave_reads<=S_AXI_arlen) begin
      if(S_AXI_rvalid && S_AXI_rready) begin
        slave_reads++;
      end
      if(subcount<8 && count==0) begin
        if( S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][(S_AXI_araddr[5:3]+subcount)*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time, queue_[count][(S_AXI_araddr[5:3]+subcount)*64 +: 64] , S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;
          if(subcount+(S_AXI_araddr[5:3])==8) begin
            count++;
            subcount=0;
          end
        end
      end
      else if (count == M_AXI_arlen)begin
        if(subcount <= (S_AXI_arlen[2:0] - (8-S_AXI_araddr[5:3])) && S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][subcount*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time,  queue_[count][subcount*64 +: 64], S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;
        end   
      end
      else begin
        if(S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][subcount*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time,queue_[count][subcount*64 +: 64]  , S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;     
        end
      end
      @(negedge aclk); 
      if((subcount+1)%8==0) begin
        count<=count+1;
      end
    end
    // wait(S_AXI_rlast);
    start_reading=0;
  endtask

  task cont_test;
    S_AXI_arvalid=0;
    start_reading=0;
    M_AXI_rresp=0;
    M_AXI_rvalid=0;
    @(negedge aclk);
    S_AXI_rready=0;
    aresetn=1;
    S_AXI_arvalid =1;  
    S_AXI_araddr={$random,3'b0};
    S_AXI_arburst=INCR;
    M_AXI_arready=1;
    S_AXI_arlen=0;
    count=0;
    subcount=0;
    @(negedge aclk);
    S_AXI_arvalid =0;
    start_reading=1;
    master_reads=0;
    slave_reads=0;
    ctrl_len = calc_len(S_AXI_arlen , INCR , S_AXI_araddr);
    @(negedge aclk);
    repeat(ctrl_len+1) begin
      M_AXI_rvalid=1;
      M_AXI_rdata={ $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random };
      S_AXI_rready=1;
      M_AXI_rresp=0;
      if(ctrl_len==0)begin
        M_AXI_rlast=1;
      end
      wait(M_AXI_rready&&M_AXI_rvalid);
      master_reads++;
      if(master_reads == ctrl_len+1) begin
        M_AXI_rlast=1;
        @(negedge aclk); 
        M_AXI_rlast=0;
        M_AXI_rvalid=0;
      end
      else begin
        M_AXI_rlast=0;
      end
      begin 
        @(negedge aclk);
      end 
      queue_[count] = M_AXI_rdata;
      count++;
      //wait(M_AXI_rready&&S_AXI_rvalid); 
    end  
    count=0;
    M_AXI_rvalid=0;
    M_AXI_rlast=0;
    while(slave_reads<=S_AXI_arlen) begin
      if(S_AXI_rvalid && S_AXI_rready) begin
        slave_reads++;
      end
      if(subcount<8 && count==0) begin
        if( S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][(S_AXI_araddr[5:3]+subcount)*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time, queue_[count][(S_AXI_araddr[5:3]+subcount)*64 +: 64] , S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;
          if(subcount+(S_AXI_araddr[5:3])==8) begin
            count++;
            subcount=0;
          end
        end
      end
      else if (count == M_AXI_arlen)begin
        if(subcount <= (S_AXI_arlen[2:0] - (8-S_AXI_araddr[5:3])) && S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][subcount*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time,  queue_[count][subcount*64 +: 64], S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;
        end   
      end
      else begin
        if(S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][subcount*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time,queue_[count][subcount*64 +: 64]  , S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;     
        end
      end
      @(negedge aclk); 
      if((subcount+1)%8==0) begin
        count<=count+1;
      end
    end
    // wait(S_AXI_rlast);
  endtask

  task stall_test;
    aresetn =0;
    S_AXI_arvalid=0;
    start_reading=0;
    M_AXI_rresp=0;
    M_AXI_rvalid=0;
    S_AXI_rready=0;
    loopcnt=256;
    @(negedge aclk);
    aresetn=1;
    S_AXI_arvalid =1;  
    S_AXI_araddr={$random,3'b0};
    S_AXI_arburst=INCR;
    M_AXI_arready=1;
    S_AXI_arlen=$random;
    count=0;
    subcount=0;
    @(negedge aclk);
    wait(S_AXI_arready && M_AXI_arvalid);
    S_AXI_arvalid =0;
    start_reading=1;
    master_reads=0;
    slave_reads=0;
    ctrl_len = calc_len(S_AXI_arlen , INCR , S_AXI_araddr);
    @(negedge aclk);
    repeat(ctrl_len+1) begin
      M_AXI_rvalid=0;
      M_AXI_rdata={ $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random };
      stall_cycles= $urandom_range(0,10); #0;
      repeat(stall_cycles) @(negedge aclk);
      M_AXI_rvalid=1;
      M_AXI_rdata={ $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random };
      S_AXI_rready=1;
      M_AXI_rresp=0;
      wait(M_AXI_rready&&M_AXI_rvalid);
      master_reads++;
      if(master_reads == ctrl_len+1) begin
        M_AXI_rlast=1;
        @(negedge aclk); 
      end
      else begin
        M_AXI_rlast=0;
      end
      if(master_reads==1) begin
        @(negedge aclk); @(negedge aclk);
      end
      else begin 
        @(negedge aclk);
      end 
      queue_[count] = M_AXI_rdata;
      count++;
      //wait(M_AXI_rready&&S_AXI_rvalid); 
    end  
    count=0;
    M_AXI_rvalid=0;
    M_AXI_rlast=0;
    while(slave_reads<=S_AXI_arlen) begin
      if(S_AXI_rvalid && S_AXI_rready) begin
        slave_reads++;
      end
      if(subcount<8 && count==0) begin
        if( S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][(S_AXI_araddr[5:3]+subcount)*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time, queue_[count][(S_AXI_araddr[5:3]+subcount)*64 +: 64] , S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;
          if(subcount+(S_AXI_araddr[5:3])==8) begin
            count++;
            subcount=0;
          end
        end
      end
      else if (count == M_AXI_arlen)begin
        if(subcount <= (S_AXI_arlen[2:0] - (8-S_AXI_araddr[5:3])) && S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][subcount*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time,  queue_[count][subcount*64 +: 64], S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;
        end   
      end
      else begin
        if(S_AXI_rvalid) begin
          if(S_AXI_rdata !== queue_[count][subcount*64 +: 64]) begin
            $display("read error at %0t, expected data %0h, got data %0h", $time,queue_[count][subcount*64 +: 64]  , S_AXI_rdata);
            err_count++;
          end
          else crrct_count++;
          subcount++;     
        end
      end
      loopcnt--;
      @(negedge aclk); 
      if((subcount+1)%8==0) begin
        count<=count+1;
      end
    end
    // wait(S_AXI_rlast);
    start_reading=0;
  endtask
  function automatic [7:0] calc_len;
    input [7:0] orig_len_f;
    input [1:0] burst_type_f;
    input [30:0] araddr_in_f;
    reg [7:0] new_len;
    reg [8:0] total_len;
    reg [8:0] rem_8;
    begin
      total_len = orig_len_f+1'b1;
      new_len = ((total_len)>>3) -1'b1;
      rem_8 = (total_len- (4'd8 - araddr_in_f[5:3]));
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
  always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
      read_beats<=0;
    end
    else begin
      if(S_AXI_rvalid&&S_AXI_rready) begin
        if(S_AXI_rlast) begin
          if(read_beats!==S_AXI_arlen) begin
            $display("burst error at %0t", $time);
            err_count++;
          end
          else begin
            crrct_count++;
          end
          read_beats<=0; 
        end 
        else
        read_beats<=read_beats+1; 
      end
    end 
  end
    
endmodule

