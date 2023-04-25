module tb_skidbuffer();
`define RD 1

localparam MODE = 3; // 1: forward register, 2: backward register, 3: fully register
localparam DW = 8;

logic            i_clk;
logic            i_resetn;
logic [DW-1:0]   s_data;
logic            s_valid;
logic            s_ready;
logic [DW-1:0]   m_data;
logic            m_valid;
logic            m_ready;
integer          data_cnt;
logic            send_one_data;
logic            rev_one_data;

axi_skidbuffer #(
    .DW (DW),
    .MODE (MODE)
) dut(
    .*
);

initial begin
    i_clk = 0;
    i_resetn = 0;

    # 1000
    i_resetn = 1;
end

always #5 i_clk = ~i_clk;


initial begin
    s_data = 0;
    s_valid = 0;
    m_ready = 0;

    wait(i_resetn==1);

    alw_send_stall_rev;
    stall_send_alw_rev;
    alw_send_alw_rev;
    stall_send_stall_rev;

    #100;
    $finish();

end

always @ (posedge i_clk or negedge i_resetn) begin
    if(~i_resetn)
        s_data <= #`RD '0;
    else if(~s_valid || s_ready)
        s_data <= #`RD $random();
end

always @ (posedge i_clk) begin
    if(s_valid && s_ready)
        $display("Send data: %h", s_data);
end

always @ (posedge i_clk) begin
    if(m_valid && m_ready)
        $display("Receive data: %h", m_data);
end

assign send_one_data = s_valid && s_ready;
assign rev_one_data = m_ready && m_valid;


always @ (posedge i_clk) begin
    if(~i_resetn)
        data_cnt <= 0;
    else if(send_one_data && ~rev_one_data)
        data_cnt <= data_cnt + 1;
    else if(rev_one_data && ~send_one_data)
        data_cnt <= data_cnt - 1; 
end

task alw_send_stall_rev;
    #100;
    repeat(30) begin
        @ (posedge i_clk) begin
            #`RD;
            s_valid = 1;
            m_ready = $random();
        end
    end
    rev_rest_data();
endtask

task stall_send_alw_rev;
    #100;
    @ (posedge i_clk) begin
        #`RD;
        m_ready = 1;
    end
    repeat(30) begin
        @ (posedge i_clk) begin
            if(~s_valid) begin
                #`RD;
                s_valid = $random();
            end else if(s_valid && s_ready) begin
                #`RD
                s_valid = $random();
            end
        end
    end
    rev_rest_data();
endtask

task alw_send_alw_rev;
    #100;
    @ (posedge i_clk) begin
        #`RD m_ready = 1;
        #`RD s_valid = 1;
    end
    repeat(30) begin
        @(posedge i_clk);
    end
    rev_rest_data();
endtask

task stall_send_stall_rev;
    #100;
    repeat(30) fork
        @(posedge i_clk) begin
            #`RD; m_ready = $random();
        end
        
        @(posedge i_clk) begin
            if(~s_valid) begin
                #`RD;
                s_valid = $random();
            end else if(s_valid && s_ready) begin
                #`RD
                s_valid = $random();
            end            
        end
    join
    rev_rest_data();
endtask

task rev_rest_data;
    @(posedge i_clk);

    while(data_cnt >= 1) begin
        @(posedge i_clk) begin
            #`RD;
            s_valid = 0;
            m_ready = 1;
        end
    end
    
    @(posedge i_clk)
    #`RD
    m_ready = 0;
endtask


endmodule
