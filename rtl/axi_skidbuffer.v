//-----------------------------------------------------------
// Author        : Jzhen
// Email         : majx1996@outlook.com
// Last modified : 2023-04-25 20:09
// Filename      : axi_skidbuffer.v
// Description   : 
//-----------------------------------------------------------
`define RD 1
module axi_skidbuffer #(
    parameter   DW = 8,
    parameter   MODE = 0 // 0: pass through, 1: forward register, 2: backward register, 3: fully register
)(
    i_clk, i_resetn,
    s_data, s_valid, s_ready,
    m_data, m_valid, m_ready
);

input logic             i_clk;
input logic             i_resetn;
input logic [DW-1:0]    s_data;
input logic             s_valid;
output logic            s_ready;
output logic [DW-1:0]   m_data;
output logic            m_valid;
input logic             m_ready;


generate 
if(MODE == 0) begin: PASS_THROUGH
//-----------------------
//    pass through
//-------------------------
    wire _unused_ok;

    assign {s_ready, m_data, m_valid} = 
           {m_ready, s_data, s_valid};

    assign _unused_ok = &{1'b0, i_clk, i_resetn};

end // PASS_THROUGH

else if(MODE == 1) begin: FORWARD_REGISTER
//-----------------------
//    forward register
//-------------------------   
    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            m_valid <= #`RD 1'b0;
        else if(s_valid)
            m_valid <= #`RD 1'b1;
        else if(m_ready)
            m_valid <= #`RD 1'b0;
    end

    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            m_data <= #`RD '0;
        else if(s_valid && s_ready)
            m_data <= #`RD s_data;
    end

    assign s_ready = (~m_valid) || m_ready;

end // FORWARD_REGISTER

else if(MODE == 2) begin: BACKWARD_REGISTER
//-----------------------
//    forward register
//-------------------------  
    reg             skidbuff_empty;
    reg [DW-1:0]    skidbuffer;

    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            skidbuff_empty <= #`RD 1'b1;
        else if((s_valid && s_ready) && (m_valid && ~m_ready)) // "We have incoming data, but the output is stalled" by Dan Gisselquist, Ph.D.
            skidbuff_empty <= #`RD 1'b0;
        else if(m_ready)
            skidbuff_empty <= #`RD 1'b1;
    end
    
    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            skidbuffer <= #`RD '0;
        else if((s_valid && s_ready) && (m_valid && ~m_ready))// "We have incoming data, but the output is stalled" by Dan Gisselquist, Ph.D.
            skidbuffer <= #`RD s_data;
    end

    assign m_data = skidbuff_empty ? s_data : skidbuffer;
    assign m_valid = ~skidbuff_empty || s_valid;
    assign s_ready = skidbuff_empty;

end // BACKWARD_REGISTER

else if(MODE == 3) begin: FULLY_REGISTER
//-----------------------
//    fully register
//-------------------------  
    reg             skidbuff_empty;
    reg [DW-1:0]    skidbuffer;

    assign s_ready = skidbuff_empty;

    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            skidbuff_empty <= #`RD 1'b1;
        else if((s_valid && s_ready) && (m_valid && ~m_ready)) // "We have incoming data, but the output is stalled" by Dan Gisselquist, Ph.D.
            skidbuff_empty <= #`RD 1'b0;
        else if(m_ready)
            skidbuff_empty <= #`RD 1'b1;
    end
    
    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            skidbuffer <= #`RD '0;
        else if((s_valid && s_ready) && (m_valid && ~m_ready))// "We have incoming data, but the output is stalled" by Dan Gisselquist, Ph.D.
            skidbuffer <= #`RD s_data;
    end

    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            m_data <= #`RD '0;
        else if(~skidbuff_empty)
            m_data <= #`RD skidbuffer;
        else if(s_valid)
            m_data <= #`RD s_data;
    end

    always @ (posedge i_clk or negedge i_resetn) begin
        if(~i_resetn)
            m_valid <= #`RD 1'b0;
        else
            m_valid <= #`RD ~skidbuff_empty || s_valid;
    end

end // FULLY_REGISTER
endgenerate


endmodule
