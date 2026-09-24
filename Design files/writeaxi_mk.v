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
module writeaxi_mk (
    aclk,
    aresetn,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awlen,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awlen,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid, 
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid
);


//declaring parameters
  parameter ADDR_WIDTH = 31;
  parameter MASTER_WIDTH = 512;
  parameter SLAVE_WIDTH = 64;
  parameter STRB_M = MASTER_WIDTH/8;
  parameter STRB_S = SLAVE_WIDTH/8;
  localparam FIXED=2'b00;
  localparam INCR=2'b01;

//declaring ports
  input wire aclk, aresetn;

//declaring AXI Slave ports
    input wire [ADDR_WIDTH-1:0] S_AXI_awaddr;
    input wire [1:0] S_AXI_awburst;
    input wire [7:0] S_AXI_awlen;
    output wire S_AXI_awready;
    input wire [2:0] S_AXI_awsize;
    input wire S_AXI_awvalid;
    input wire S_AXI_bready;
    output wire [1:0] S_AXI_bresp;
    output wire S_AXI_bvalid;
    input wire [SLAVE_WIDTH-1:0] S_AXI_wdata;
    input wire S_AXI_wlast;
    output wire S_AXI_wready;
    input wire [STRB_S-1:0] S_AXI_wstrb;
    input wire S_AXI_wvalid;



//declaring AXI Master ports
    output wire [ADDR_WIDTH-1:0] M_AXI_awaddr;
    output wire [1:0] M_AXI_awburst;
    output wire [7:0] M_AXI_awlen;
    input wire M_AXI_awready;
    output wire [2:0] M_AXI_awsize;
    output wire M_AXI_awvalid;
    output wire M_AXI_bready;
    input wire [1:0] M_AXI_bresp;
    input wire M_AXI_bvalid;
    output wire [MASTER_WIDTH-1:0] M_AXI_wdata;
    output wire M_AXI_wlast;
    input wire M_AXI_wready;
    output wire [STRB_M-1:0] M_AXI_wstrb;
    output wire M_AXI_wvalid;

//placeholders
    reg S_AXI_awready_reg;
    reg [1:0] S_AXI_bresp_reg;
    reg S_AXI_bvalid_reg;
    reg S_AXI_wready_reg;
    reg [ADDR_WIDTH-1:0] M_AXI_awaddr_reg;
    reg [1:0] M_AXI_awburst_reg;
    reg [7:0] M_AXI_awlen_reg;
    reg [2:0] M_AXI_awsize_reg;
    reg M_AXI_awvalid_reg;
    reg M_AXI_bready_reg;
    reg [MASTER_WIDTH-1:0] M_AXI_wdata_reg;
    reg M_AXI_wlast_reg;
    reg [STRB_M-1:0] M_AXI_wstrb_reg;
    reg M_AXI_wvalid_reg;

//AXI-related signals
    reg [MASTER_WIDTH-1:0] written_word;
    reg [SLAVE_WIDTH-1:0] written_subword [7:0];
    reg [STRB_M-1:0] word_strb;
    reg [STRB_S-1:0] word_substrb [7:0];
    reg finished_word, finished_packing;
    reg [2:0] received_word_idx;
    reg [7:0] received_beats;
    reg [ADDR_WIDTH-1:0] cpu_orig_address;
    reg [5:0] finished_words, sent_beats;//max is 33

    reg done_conversion;

    reg resp_handshake;

    reg fifos_wen, fifos_rready, fifo_read, reset_fifo_n;
    //Writing FIFO
    wire full_fifo, empty_fifo;
    reg wen_fifo;
    reg rready_fifo;
    wire [511:0] out_data_fifo;
    reg [511:0] in_data_fifo;

    scfifo_mk #(.FIFO_DEPTH(33),.DATA_WIDTH(MASTER_WIDTH)) write_fifo (.clk(aclk), .rst_n(reset_fifo_n), 
    .in_data(in_data_fifo), .out_data(out_data_fifo), .full(full_fifo), .empty(empty_fifo), 
    .wen(wen_fifo), .rready(rready_fifo));

    //Write STROBE FIFO
    wire full_fifo_wstb, empty_fifo_wstb;
    reg wen_fifo_wstb;
    reg rready_fifo_wstb;
    wire [STRB_M-1:0] out_data_fifo_wstb;
    reg [STRB_M-1:0] in_data_fifo_wstb;

    scfifo_mk #(.FIFO_DEPTH(33),.DATA_WIDTH(STRB_M)) write_fifo_wstb (.clk(aclk), .rst_n(reset_fifo_n), 
    .in_data(in_data_fifo_wstb), .out_data(out_data_fifo_wstb), .full(full_fifo_wstb), .empty(empty_fifo_wstb), 
    .wen(wen_fifo_wstb), .rready(rready_fifo_wstb));


    //Write words Strobe FIFO
    wire full_fifo_stb, empty_fifo_stb;
    reg wen_fifo_stb;
    reg rready_fifo_stb;
    wire [7:0] out_data_fifo_stb;
    reg [7:0] in_data_fifo_stb;
    reg write_lane_strobe [7:0];

    scfifo_mk #(.FIFO_DEPTH(33),.DATA_WIDTH(8)) write_fifo_stb (.clk(aclk), .rst_n(reset_fifo_n), 
    .in_data(in_data_fifo_stb), .out_data(out_data_fifo_stb), .full(full_fifo_stb), .empty(empty_fifo_stb), 
    .wen(wen_fifo_stb), .rready(rready_fifo_stb));

    // FIFO SIGNALS
    always @(*) begin
        in_data_fifo = written_word;
    end
    always @(*) begin
        in_data_fifo_wstb = word_strb;
    end
    always @(*) begin
        in_data_fifo_stb = {write_lane_strobe[7], write_lane_strobe[6], write_lane_strobe[5], write_lane_strobe[4], write_lane_strobe[3], write_lane_strobe[2], write_lane_strobe[1], write_lane_strobe[0]};
    end
    //packing
    always @(*) begin
        written_word = {written_subword [7], written_subword [6], written_subword [5], written_subword [4], written_subword [3], written_subword [2], written_subword [1], written_subword [0]};
    end
    always @(*) begin
        word_strb = {word_substrb [7], word_substrb [6], word_substrb [5], word_substrb [4], word_substrb [3], word_substrb [2], word_substrb [1], word_substrb [0]};
    end
    always @(*) begin
        wen_fifo = fifos_wen;
    end
    always @(*) begin
        wen_fifo_wstb = fifos_wen;
    end
    always @(*) begin
        wen_fifo_stb = fifos_wen;
    end
    always @(*) begin
        rready_fifo = fifos_rready;
    end
    always @(*) begin
        rready_fifo_wstb = fifos_rready;
    end
    always @(*) begin
        rready_fifo_stb = fifos_rready;
    end

    integer i;
    //written_Subword_strbs
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for (i=0; i<8; i=i+1) begin
                written_subword[i]<=64'b0;
            end
            for (i=0; i<8; i=i+1) begin
                word_substrb[i]<=8'b0;
            end
            for (i=0; i<8; i=i+1) begin
                write_lane_strobe[i]<=1'b0;
            end
            finished_word<=1'b0;
            fifos_wen<=1'b0;
            received_word_idx<=3'b0;
            received_beats<=8'b0;
        end
        else begin
            if(S_AXI_wvalid && S_AXI_wready_reg && !finished_packing) begin
                case(M_AXI_awburst_reg)
                    FIXED: begin
                        for (i=0; i<8; i=i+1) begin
                            if(i==cpu_orig_address[5:3]) begin
                                write_lane_strobe[i]<=1'b1;
                                written_subword[i]<=S_AXI_wdata;
                                word_substrb[i]<=S_AXI_wstrb;
                            end
                            else begin
                                write_lane_strobe[i]<=1'b0;
                            end
                        end
                        finished_word<=1'b1;
                        fifos_wen<=1'b1;  
                    end
                    INCR: begin
                       if(S_AXI_awlen<8) begin
                        if(M_AXI_awlen_reg==1) begin
                            if(received_beats<(8-cpu_orig_address[5:3])) begin
                               if((received_word_idx+cpu_orig_address[5:3])<4'b1000) begin
                                write_lane_strobe[received_word_idx+cpu_orig_address[5:3]]<=1'b1;
                                written_subword[received_word_idx+cpu_orig_address[5:3]]<=S_AXI_wdata;
                                word_substrb[received_word_idx+cpu_orig_address[5:3]]<=S_AXI_wstrb;
                                received_beats<=received_beats+1'b1;
                                received_word_idx<=received_word_idx+1'b1;
                                if((received_word_idx+cpu_orig_address[5:3])==3'b111) begin
                                    for (i=0; i<cpu_orig_address[5:3]; i=i+1) begin
                                        write_lane_strobe[i]<=1'b0;
                                        written_subword[i]<=64'b0;
                                        word_substrb[i]<=8'b0;
                                    end
                                    finished_word<=1'b1;
                                    fifos_wen<=1'b1;
                                    received_word_idx<=3'b0;
                                end
                                else begin
                                    finished_word<=1'b0;
                                    fifos_wen<=1'b0;     
                                end
                               end 
                            end
                            else begin
                               if(received_beats<=S_AXI_awlen) begin
                                write_lane_strobe[received_word_idx]<=1'b1;
                                written_subword[received_word_idx]<=S_AXI_wdata;
                                word_substrb[received_word_idx]<=S_AXI_wstrb;
                                received_beats<=received_beats+1'b1;
                                received_word_idx<=received_word_idx+1'b1;
                                if(received_beats==S_AXI_awlen) begin
                                    for(i=0;i<8;i=i+1) begin
                                        if(i>=(received_word_idx+1'b1)) begin
                                            write_lane_strobe[i]<=1'b0;
                                            written_subword[i]<=64'b0;
                                            word_substrb[i]<=8'b0;
                                        end
                                    end
                                    finished_word<=1'b1;
                                    fifos_wen<=1'b1; 
                                    received_word_idx<=3'b0;
                                    received_beats<=8'b0;
                                end
                                else begin
                                    finished_word<=1'b0;
                                    fifos_wen<=1'b0; 
                                end
                               end 
                            end
                        end
                        else if(!M_AXI_awlen_reg)begin
                            if(received_word_idx<=S_AXI_awlen) begin
                                write_lane_strobe[received_word_idx+cpu_orig_address[5:3]]<=1'b1;
                                written_subword[received_word_idx+cpu_orig_address[5:3]]<=S_AXI_wdata;
                                word_substrb[received_word_idx+cpu_orig_address[5:3]]<=S_AXI_wstrb;
                                received_word_idx<=received_word_idx+1'b1; 
                                if(received_word_idx==S_AXI_awlen) begin
                                    finished_word<=1'b1;
                                    fifos_wen<=1'b1;
                                    received_word_idx<=3'b0;
                                    for(i=0;i<8;i=i+1) begin
                                        if((i>S_AXI_awlen+cpu_orig_address[5:3])||(i<cpu_orig_address[5:3])) begin
                                            write_lane_strobe[i]<=1'b0;
                                            written_subword[i]<=64'b0;
                                            word_substrb[i]<=8'b0;
                                        end
                                    end
                                end
                                else begin
                                    finished_word<=1'b0;
                                    fifos_wen<=1'b0;
                                end
                            end
                        end
                       end
                       else begin
                        if(received_beats<(4'd8-cpu_orig_address[5:3])) begin
                            write_lane_strobe[received_word_idx+cpu_orig_address[5:3]]<=1'b1;
                            written_subword[received_word_idx+cpu_orig_address[5:3]]<=S_AXI_wdata;
                            word_substrb[received_word_idx+cpu_orig_address[5:3]]<=S_AXI_wstrb;
                            received_beats<=received_beats+1'b1;
                            received_word_idx<=received_word_idx+1'b1;
                            if((received_word_idx+cpu_orig_address[5:3])==3'b111) begin
                                received_word_idx<=3'b0;
                                for (i=0; i<cpu_orig_address[5:3]; i=i+1) begin
                                    write_lane_strobe[i]<=1'b0;
                                    written_subword[i]<=64'b0;
                                    word_substrb[i]<=8'b0;
                                end
                                finished_word<=1'b1;
                                fifos_wen<=1'b1;
                            end
                            else begin
                                finished_word<=1'b0;
                                fifos_wen<=1'b0;     
                            end   
                        end
                        else begin
                            write_lane_strobe[received_word_idx]<=1'b1;
                            written_subword[received_word_idx]<=S_AXI_wdata;
                            word_substrb[received_word_idx]<=S_AXI_wstrb;
                            received_beats<=received_beats+1'b1;
                            received_word_idx<=received_word_idx+1'b1;
                            if(S_AXI_wlast) begin
                                for (i=0; i<8; i=i+1) begin
                                    if(i>=(received_word_idx+1'b1)) begin
                                    write_lane_strobe[i]<=1'b0;
                                    written_subword[i]<=64'b0;
                                    word_substrb[i]<=8'b0;
                                    end
                                end
                                finished_word<=1'b1;
                                fifos_wen<=1'b1;  
                                received_beats<=received_beats+1'b1;
                                received_word_idx<=3'b0;
                            end
                            else if(received_word_idx==3'b111) begin
                                finished_word<=1'b1;
                                fifos_wen<=1'b1;   
                            end
                            else begin
                                finished_word<=1'b0;
                                fifos_wen<=1'b0;
                            end
                        end
                       end
                    end
                    default: begin
                        finished_word<=1'b0;
                        fifos_wen<=1'b0; 
                    end  
                endcase 
            end
            else begin
                finished_word<=1'b0;
                fifos_wen<=1'b0;
            end
            if(finished_packing) begin
                received_beats<=0;
                received_word_idx<=0;
            end
        end
    end
    //finished words
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            finished_words<=6'b0;
        end
        else begin
            if(M_AXI_awready&&M_AXI_awvalid_reg) begin
                finished_words<=6'b0;
            end
            else if(finished_word) begin
                finished_words<=finished_words+1'b1;
            end
        end
    end
    //finished_packing
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            finished_packing<=1'b0;
        end
        else begin
            if((finished_words==M_AXI_awlen_reg)&&(fifos_wen)) begin
                finished_packing<=1'b1;
            end
            else if(M_AXI_awvalid_reg&&M_AXI_awready) begin
                finished_packing<=1'b0;
            end 
        end
    end



    //awburst
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
        M_AXI_awburst_reg<=0;
        end
        else begin
            if(M_AXI_awvalid_reg && M_AXI_awready) begin
            M_AXI_awburst_reg<=S_AXI_awburst; 
            end
        end
    end
    //awaddr
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            M_AXI_awaddr_reg<=0;
        end
        else begin
            M_AXI_awaddr_reg<={S_AXI_awaddr[30:6] , {6{1'b0}}};
        end
    end
    //cpu original address
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cpu_orig_address<=31'b0;
        end
        else begin
            if(M_AXI_awready && M_AXI_awvalid_reg) begin
                cpu_orig_address<= S_AXI_awaddr;
            end
        end
    end
    //awlen
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
        M_AXI_awlen_reg<=0;
        end
        else begin
            M_AXI_awlen_reg<=calc_len(S_AXI_awlen, S_AXI_awburst, S_AXI_awaddr);
        end
    end
    //wready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            S_AXI_wready_reg<=1'b0;
        end
        else begin
            S_AXI_wready_reg<=M_AXI_wready && !resp_handshake;
        end
    end
    //rreadys
    always @(*) begin
        if(M_AXI_wvalid_reg&&M_AXI_wready&&!(empty_fifo&&empty_fifo_stb&&empty_fifo_wstb)) begin
            fifos_rready=1'b1;
        end
        else begin
            fifos_rready=1'b0;
        end
    end
    //fifo_read
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            fifo_read<=1'b0;
        end
        else begin
            if(fifos_rready) begin
                fifo_read<=1'b1;
            end
            else if(M_AXI_wvalid_reg&&M_AXI_wready) begin
                fifo_read<=1'b0;
            end
        end
    end
    //wvalid, wdata, wstrb
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            M_AXI_wvalid_reg<=1'b0;
            M_AXI_wlast_reg<=1'b0;
            sent_beats<=6'b0;
        end
        else begin
            if(finished_packing && sent_beats<=M_AXI_awlen_reg) begin
                if(M_AXI_wvalid_reg && M_AXI_wready) begin
                    sent_beats<=sent_beats+1'b1;
                end 
                if(sent_beats==0 &&(!(M_AXI_wlast_reg&&M_AXI_wvalid_reg&&M_AXI_wready)) && !done_conversion) begin
                    M_AXI_wvalid_reg<=1'b1;
                end
                else if((fifos_rready || fifo_read)&&(!(M_AXI_wlast_reg&&M_AXI_wvalid_reg&&M_AXI_wready)) && !done_conversion) begin
                    M_AXI_wvalid_reg<=1'b1;
                end
                else begin
                    M_AXI_wvalid_reg<=1'b0;
                end
            end
            else begin
                M_AXI_wvalid_reg<=1'b0;
            end
            if(M_AXI_awvalid_reg&&M_AXI_awready) begin
                sent_beats<=6'b0;
            end
            if(M_AXI_wlast_reg&&M_AXI_wvalid_reg&&M_AXI_wready) begin
                M_AXI_wlast_reg<=1'b0;
            end
            else if(sent_beats==M_AXI_awlen_reg-1 && finished_packing && M_AXI_wready && M_AXI_wvalid_reg) begin
                M_AXI_wlast_reg<=1'b1;
            end
            else if(!M_AXI_awlen_reg &&finished_packing && !done_conversion) begin
                M_AXI_wlast_reg<=1'b1;
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            done_conversion<=1'b0;
        end
        else begin
            if(M_AXI_wlast_reg&&M_AXI_wvalid_reg&&M_AXI_wready) begin
                done_conversion<=1'b1;
            end
            else if(M_AXI_awready&&M_AXI_awvalid_reg) begin
                done_conversion<=1'b0;
            end
        end
    end

    always @(*) begin
        M_AXI_wdata_reg<=out_data_fifo;   
    end
    always @(*) begin
        for (i=0; i<8; i=i+1) begin
            M_AXI_wstrb_reg[8*i +: 8] = out_data_fifo_wstb[8*i +: 8] & {8{out_data_fifo_stb[i]}};
        end 
    end
    //awsize
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
          M_AXI_awsize_reg<=3'b0;
        end
        else begin
          M_AXI_awsize_reg<=3'h6;
        end
    end
    //bresp
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            S_AXI_bresp_reg<=2'b0;
        end
        else begin
            S_AXI_bresp_reg<=M_AXI_bresp;
        end
    end
    //bvalid
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            S_AXI_bvalid_reg<=1'b0;
        end
        else begin
            S_AXI_bvalid_reg<=M_AXI_bvalid;
        end
    end
    //bready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            M_AXI_bready_reg<=1'b0;
        end
        else begin
            M_AXI_bready_reg<=S_AXI_bready;
        end
    end
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            resp_handshake<=1'b1;
        end
        else begin
            if(M_AXI_awvalid_reg&&M_AXI_awready) begin
                resp_handshake<=1'b0;
            end
            else if(M_AXI_bvalid&&M_AXI_bready_reg) begin
                resp_handshake<=1'b1;
            end
        end
    end
    //awready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            S_AXI_awready_reg<=1'b0;
        end
        else begin
            if(resp_handshake) begin
                S_AXI_awready_reg<=M_AXI_awready;
            end
            else begin
                S_AXI_awready_reg<=1'b0;
            end
        end
    end
    //awvalid
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            M_AXI_awvalid_reg<=1'b0;
        end
        else begin
          if(resp_handshake) begin
            M_AXI_awvalid_reg<=S_AXI_awvalid;
          end
          else begin
            M_AXI_awvalid_reg<=1'b0;
          end
        end
    end


    assign S_AXI_awready = S_AXI_awready_reg;
    assign S_AXI_bresp = S_AXI_bresp_reg;
    assign S_AXI_bvalid = S_AXI_bvalid_reg;
    assign S_AXI_wready = S_AXI_wready_reg;
    assign M_AXI_awaddr = M_AXI_awaddr_reg;
    assign M_AXI_awburst = M_AXI_awburst_reg;
    assign M_AXI_awlen = M_AXI_awlen_reg;
    assign M_AXI_awsize = M_AXI_awsize_reg;
    assign M_AXI_awvalid = M_AXI_awvalid_reg;
    assign M_AXI_bready = M_AXI_bready_reg;
    assign M_AXI_wdata = M_AXI_wdata_reg;
    assign M_AXI_wlast = M_AXI_wlast_reg;
    assign M_AXI_wstrb = M_AXI_wstrb_reg;
    assign M_AXI_wvalid = M_AXI_wvalid_reg;
    always @(*) begin
        if(M_AXI_awvalid_reg&&M_AXI_awready) begin
        reset_fifo_n=0;
        end
        else begin
        reset_fifo_n = aresetn;
        end
    end
  //translating awlen
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

endmodule //upsizer_mk