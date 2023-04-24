//-----------------------------------------------------------
// Author        : Jzhen
// Email         : majx1996@outlook.com
// Last modified : 2023-04-23 22:14
// Filename      : axi_decoder.v
// Description   : address decoder for axi
//-----------------------------------------------------------
module axi_decoder #(
    parameter SLV_N = 8,    // slave number
    parameter AW = 32,      // address width
    parameter [AW-1:0] SLV_ADDR_L[SLV_N] = '{SLV_N { {AW{1'b0}} }}, // low address per slave
    parameter [AW-1:0] SLV_ADDR_H[SLV_N] = '{SLV_N { {AW{1'b0}} }}, // high address per slave
    parameter [SLV_N-1:0] SLV_ACCESS = {SLV_N{1'b1}} // master access slave
    
)(
    i_addr, i_valid,
    o_sel, o_sel_ds
);

input logic [AW-1:0] i_addr;
input logic i_valid;
output logic [SLV_N-1:0] o_sel;
output logic o_sel_ds; // sel default slave


    integer i;

    always @ (*) begin
        for(i=0; i<SLV_N; i=i+1) begin
            o_sel[i] = i_valid && SLV_ACCESS[i] && (i_addr >= SLV_ADDR_L[i]) && (i_addr <= SLV_ADDR_H[i]);
        end
    end

    assign o_sel_ds = i_valid & ~|o_sel;

endmodule
