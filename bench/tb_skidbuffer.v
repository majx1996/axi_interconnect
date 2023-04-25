module tb_skidbuffer();
`define RD 1

localparam MODE = 1; // 1: forward register, 2: backward register, 3: fully register
localparam DW = 8;

logic            i_clk;
logic            i_resetn;
logic [DW-1:0]   s_data;
logic            s_valid;
logic            s_ready;
logic [DW-1:0]   m_data;
logic            m_valid;
logic            m_ready;

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

    #100;

    s_valid = 1;
    m_ready = 1;
 
    repeat(30) begin
        @ (posedge i_clk) begin
            #`RD;
            s_valid = $random();
            m_ready = $random();
        end
    end

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


endmodule
