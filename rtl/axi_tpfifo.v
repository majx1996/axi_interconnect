//-----------------------------------------------------------
// Author        : Jzhen
// Email         : majx1996@outlook.com
// Last modified : 2023-04-24 22:34
// Filename      : axi_tpfifo.v
// Description   : transparent fifo for every data
//-----------------------------------------------------------
`define RD 1

module axi_tpfifo #(
    parameter   DW = 8, // Data Width
    parameter   DP = 4  // Data Depth, DP >= 2
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
output logic [DW-1:0] o_data [DP];
output logic          o_valid [DP];
output logic          o_full;
output logic          o_empty;

localparam AW = $clog2(DW);


reg [DW-1:0] mem [DP];
reg [AW-1:0] wptr;
reg [DP-1:0] shift_cnt;
wire         wr_en;
wire         rd_en;

//-----------------------
//    Control Logic
//-------------------------
assign wr_en = i_push && ~o_full;
assign rd_en = i_pop && ~o_empty;
assign o_full = &shift_cnt;
assign o_empty = ~|shift_cnt;


always @ (posedge i_clk or negedge i_resetn) begin
    if(~i_resetn)
        wptr <= #`RD '0;
    else if(wr_en)
        wptr <= #`RD wptr + 1;
end


always @ (posedge i_clk or negedge i_resetn) begin
    if(~i_resetn)
        shift_cnt <= #`RD '0;
    else if(wr_en & ~rd_en)
        shift_cnt <= #`RD {shift_cnt[DP-2:0], 1'b1};    // note DP >= 2
    else if(rd_en & ~wr_en)
        shift_cnt <= #`RD {1'b0, shift_cnt[DP-1:1]};
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


always @ (*) begin
    integer i;
    for(i=0;i<DP;i=i+1) begin
        o_data[i] = mem[i];
    end
end


always @ (*) begin
    integer i;
    for(i=0;i<DP;i=i+1) begin
        o_valid[i] = shift_cnt[i];
    end
end


endmodule
