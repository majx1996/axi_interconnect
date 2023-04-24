//-----------------------------------------------------------
// Author        : Jzhen
// Email         : majx1996@outlook.com
// Last modified : 2023-04-24 22:34
// Filename      : axi_fifo.v
// Description   :
//-----------------------------------------------------------
`define RD 1

module axi_fifo #(
    parameter   DW = 8, // Data Width
    parameter   DP = 4  // Data Depth
)(
    i_clk, i_resetn,
    i_data, i_push, i_pop,
    o_data, o_valid, o_full, o_empty
);

input  logic          i_clk;
input  logic          i_resetn;
input  logic [DW-1:0] i_data;
input  logic          i_push;
input  logic          i_pop;
output logic [DW-1:0] o_data;
output logic          o_valid;
output logic          o_full;
output logic          o_empty;

localparam AW = $clog2(DW);


reg [DW-1:0] mem [DP];
reg [AW-1:0] wptr;
reg [AW-1:0] rptr;
reg [AW-1:0] cnt;
wire         wr_en;
wire         rd_en;

//-----------------------
//    Control Logic
//-------------------------
assign wr_en = i_push && ~o_full;
assign rd_en = i_pop && ~o_empty;
assign o_full = cnt==DP-1;
assign o_empty = cnt==0;


always @ (posedge i_clk or negedge i_resetn) begin
    if(~i_resetn)
        wptr <= #`RD '0;
    else if(wr_en)
        wptr <= #`RD wptr + 1;
end

always @ (posedge i_clk or negedge i_resetn) begin
    if(~i_resetn)
        rptr <= #`RD '0;
    else if(rd_en)
        rptr <= #`RD rptr + 1;
end

always @ (posedge i_clk or negedge i_resetn) begin
    if(~i_resetn)
        cnt <= #`RD '0;
    else if(wr_en & ~rd_en)
        cnt <= #`RD cnt + 1;
    else if(rd_en & ~wr_en)
        cnt <= #`RD cnt - 1;
end


//-----------------------
//    Data Logic
//-------------------------
always @ (posedge i_clk or negedge i_resetn) begin
    integer i;
    if(~i_resetn) begin
        for(i=0;i<DP;i=i+1) begin
            mem[i] <= #`RD '0;
        end
    end else if(wr_en) begin
        mem[wptr] <= #`RD i_data;
    end
end


assign o_data = mem[rptr];
assign o_valid = rd_en;


endmodule
