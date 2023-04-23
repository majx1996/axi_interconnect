//-----------------------------------------------------------
// Author        : Jzhen
// Email         : majx1996@outlook.com
// Last modified : 2023-04-23 23:44
// Filename      : axi_interconnect.v
// Description   : 
//-----------------------------------------------------------
module axi_interconnect #(
    parameter MST_N = 4,
    parameter SLV_N = 4,
    parameter DW = 32,
    parameter AW = 32,
    parameter IDW = 4,
    parameter USRW = 4,
    parameter [AW-1:0] SLV_ADDR_L[SLV_N] = '{SLV_N { AW{1'b0} }},
    parameter [AW-1:0] SLV_ADDR_H[SLV_N] = '{SLV_N { AW{1'b0} }},
    parameter [SLV_N-1:0] SLV_ACCESS[MST_N] = '{MST_N {SLV_N{1'b1}}}
)(

    // slave ports connect to external axi master
    output              s_awready[MST_N],
    input               s_awvalid[MST_N],
    input  [AW-1:0]     s_awaddr[MST_N],
    input  [2:0]        s_awsize[MST_N],
    input  [1:0]        s_awburst[MST_N],
    input  [3:0]        s_awcache[MST_N],
    input  [2:0]        s_awprot[MST_N],
    input  [IDW-1:0]    s_awid[MST_N],
    input  [7:0]        s_awlen[MST_N],
    input               s_awlock[MST_N],
    input  [3:0]        s_awqos[MST_N],
    input  [3:0]        s_awregion[MST_N],
    input  [USRW-1:0]   s_awuser[MST_N],

    output              s_wready[MST_N],
    input               s_wvalid[MST_N],
    input               s_wlast[MST_N],
    input  [DW-1:0]     s_wdata[MST_N],
    input  [(DW/8)-1:0] s_wstrb[MST_N],
    input  [USRW-1:0]   s_wuser[MST_N],

    input               s_bwready[MST_N],
    output              s_bwvalid[MST_N],
    output [1:0]        s_bresp[MST_N],
    output [IDW-1:0]    s_bid[MST_N],
    output [USRW-1:0]   s_buser[MST_N],

    output              s_aready[MST_N],
    input               s_arvalid[MST_N],
    input  [AW-1:0]     s_araddr[MST_N],
    input  [2:0]        s_arsize[MST_N],
    input  [1:0]        s_arburst[MST_N],
    input  [3:0]        s_arcache[MST_N],
    input  [2:0]        s_arprot[MST_N],
    input  [IDW-1:0]    s_arid[MST_N],
    input  [7:0]        s_arlen[MST_N],
    input               s_arlock[MST_N],
    input  [3:0]        s_arqos[MST_N],
    input  [3:0]        s_arregion[MST_N],
    input  [USRW-1:0]   s_aruser[MST_N],

    input               s_rready[MST_N],
    output              s_rvalid[MST_N],
    output              s_rlast[MST_N],
    output [DW-1:0]     s_rdata[MST_N],
    output [1:0]        s_rresp[MST_N],
    output [IDW-1:0]    s_rid[MST_N],
    output [USRW-1:0]   s_ruser[MST_N],

    // master ports connect to external axi master
    input               m_awready[SLV_N],
    output              m_awvalid[SLV_N],
    output [AW-1:0]     m_awaddr[SLV_N],
    output [2:0]        m_awsize[SLV_N],
    output [1:0]        m_awburst[SLV_N],
    output [3:0]        m_awcache[SLV_N],
    output [2:0]        m_awprot[SLV_N],
    output [IDW-1:0]    m_awid[SLV_N],
    output [7:0]        m_awlen[SLV_N],
    output              m_awlock[SLV_N],
    output [3:0]        m_awqos[SLV_N],
    output [3:0]        m_awregion[SLV_N],
    output [USRW-1:0]   m_awuser[SLV_N],

    input               m_wready[SLV_N],
    output              m_wvalid[SLV_N],
    output              m_wlast[SLV_N],
    output [DW-1:0]     m_wdata[SLV_N],
    output [(DW/8)-1:0] m_wstrb[SLV_N],
    output [USRW-1:0]   m_wuser[SLV_N],

    output              m_bwready[SLV_N],
    input               m_bwvalid[SLV_N],
    input  [1:0]        m_bresp[SLV_N],
    input  [IDW-1:0]    m_bid[SLV_N],
    input  [USRW-1:0]   m_buser[SLV_N],

    input               m_aready[SLV_N],
    output              m_arvalid[SLV_N],
    output [AW-1:0]     m_araddr[SLV_N],
    output [2:0]        m_arsize[SLV_N],
    output [1:0]        m_arburst[SLV_N],
    output [3:0]        m_arcache[SLV_N],
    output [2:0]        m_arprot[SLV_N],
    output [IDW-1:0]    m_arid[SLV_N],
    output [7:0]        m_arlen[SLV_N],
    output              m_arlock[SLV_N],
    output [3:0]        m_arqos[SLV_N],
    output [3:0]        m_arregion[SLV_N],
    output [USRW-1:0]   m_aruser[SLV_N],

    output              m_rready[SLV_N],
    input               m_rvalid[SLV_N],
    input               m_rlast[SLV_N],
    input  [DW-1:0]     m_rdata[SLV_N],
    input  [1:0]        m_rresp[SLV_N],
    input  [IDW-1:0]    m_rid[SLV_N],
    input  [USRW-1:0]   m_ruser[SLV_N],

    // global
    input               aclk,
    input               aresetn
);



endmodule
