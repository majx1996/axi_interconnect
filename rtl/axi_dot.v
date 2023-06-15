`define RD 1ns

module axi_dot #(
    parameter   THREAD_NUM                  = 8,
    parameter   MAX_OST_PER_THREAD          = 8,
    parameter   NUM_SLAVE                   = 8,
    parameter   NUM_MASTER                  = 8,
    parameter   NUM_MASTER_LOG2             = $ceil($clog2(NUM_MASTER)),
    parameter   NUM_SLAVE_LOG2              = $ceil($clog2(NUM_SLAVE)),
    parameter   W_ID                        = 6,
//    parameter   THREAD_NUM_LOG2             = $ceil($clog2(THREAD_NUM)),
    parameter   MAX_OST_PER_THREAD_LOG2     = $ceil($clog2(MAX_OST_PER_THREAD)),
    parameter   DEADLOCK                    = "SSPID",
    parameter   TIMEOUT_MAX_CNT             = 65535,
    parameter   TIMEOUT_MAX_CNT_LOG2        = $ceil($clog2(TIMEOUT_MAX_CNT))
)(
    input  logic                        clk_i,
    input  logic                        reset_n_i,

    input  logic [NUM_SLAVE_LOG2-1:0]   a_target_slave_i,
    input  logic [W_ID-1:0]             a_id_i,
    input  logic                        a_ready_i,
    input  logic                        a_valid_i,

    input  logic [W_ID-1:0]             b_id_i,
    input  logic                        b_valid_i,

    input  logic                        timeout_clr_i,
    output logic                        timeout_intr_o,
    output logic [NUM_SLAVE_LOG2-1:0]   timeout_slave_o,
    output logic [W_ID-1:0]             timeout_id_o,

    output logic                        deadlock_stall_o,
    output logic                        ost_stall_o
);

genvar i;

logic [THREAD_NUM-1:0]      empty_ptr;
logic [THREAD_NUM-1:0]      almost_empty_ptr;
logic [THREAD_NUM-1:0]      empty_or_almost_empty_ptr;
logic [THREAD_NUM-1:0]      onehot_empty_or_almost_empty_ptr;
logic [THREAD_NUM-1:0]      ost_col_stall_array;
logic [THREAD_NUM-1:0]      deadlock_stall_array;
logic                       ost_row_stall;
logic [THREAD_NUM-1:0]      timeout_valid_array;
logic [THREAD_NUM-1:0]      onehot_timeout_valid_array;
logic [NUM_SLAVE_LOG2-1:0]  timeout_slave_array[THREAD_NUM];
logic [W_ID-1:0]            timeout_id_array[THREAD_NUM];

assign ost_stall_o = ost_row_stall || |ost_col_stall_array;
assign deadlock_stall_o = |deadlock_stall_array;

assign empty_or_almost_empty_ptr = empty_ptr | almost_empty_ptr;
assign onehot_empty_or_almost_empty_ptr = empty_or_almost_empty_ptr & (~(empty_or_almost_empty_ptr-'b1));
assign ost_row_stall = ~|empty_or_almost_empty_ptr && a_valid_i;

assign timeout_intr_o = | timeout_valid_array;
assign onehot_timeout_valid_array = timeout_valid_array & (~(timeout_valid_array-'b1));

always_comb begin
    timeout_slave_o = '0;
    timeout_id_o = '0;
    for(int i=0;i<THREAD_NUM;i=i+1) begin
        if(onehot_timeout_valid_array==(1<<i)) begin
            timeout_slave_o = timeout_slave_array[i];
            timeout_id_o = timeout_id_array[i];
        end
    end
end

generate for(i=0;i<THREAD_NUM;i=i+1) begin: GEN_QUEUE

    logic [MAX_OST_PER_THREAD_LOG2-1:0] cnt;
    logic [NUM_SLAVE_LOG2-1:0]          slave;
    logic [W_ID-1:0]                    id;

    logic                               empty;
    logic                               almost_empty;

    logic                               a_hit_empty;
    logic                               a_try_hit_nonempty;
    logic                               a_hit_nonempty;
    logic                               r_hit_nonempty;
    logic                               a_hit;
    logic                               r_hit;

    logic                               ost_col_stall;
    logic                               deadlock_stall;

    logic [TIMEOUT_MAX_CNT_LOG2-1:0]    timeout_cnt;
    logic                               timeout_valid;
    logic [NUM_SLAVE_LOG2-1:0]          timeout_slave;
    logic [W_ID-1:0]                    timeout_id;

    assign almost_empty_ptr[i] = almost_empty;
    assign empty_ptr[i] = empty;
    assign ost_col_stall_array[i] = ost_col_stall;
    assign deadlock_stall_array[i] = deadlock_stall;
    assign timeout_valid_array[i] = timeout_valid;
    assign timeout_slave_array[i] = timeout_slave;
    assign timeout_id_array[i] = timeout_id;

    always_comb begin
        a_hit = a_hit_empty || a_hit_nonempty;
        r_hit = r_hit_nonempty;
        a_hit_empty = a_ready_i && a_valid_i && (onehot_empty_or_almost_empty_ptr == 1<<i);
        a_try_hit_nonempty = a_valid_i && (onehot_empty_or_almost_empty_ptr == 1<<i);
        a_hit_nonempty = ~empty && a_ready_i && a_valid_i && (a_id_i==id);
        r_hit_nonempty = ~empty && b_valid_i && (b_id_i==id);
        almost_empty = ~empty && r_hit_nonempty && ~a_hit_nonempty && (cnt=='b1);
        ost_col_stall = a_try_hit_nonempty && (cnt==MAX_OST_PER_THREAD);
        deadlock_stall = a_try_hit_nonempty && (slave!=a_target_slave_i);
    end
    
    always @ (posedge clk_i or negedge reset_n_i) begin
        if(~reset_n_i)
            empty <= #`RD 1'b1;
        else if(a_hit_empty)
            empty <= #`RD 1'b0;
        else if(almost_empty)
            empty <= #`RD 1'b1;
    end

    always @ (posedge clk_i or negedge reset_n_i) begin
        if(~reset_n_i)
            {slave, id} <= #`RD '0;
        else if(a_hit_empty)
            {slave, id} <= #`RD {a_target_slave_i, a_id_i};
    end

    always @ (posedge clk_i or negedge reset_n_i) begin
        if(~reset_n_i)
            cnt <= #`RD '0;
        else if(a_hit && r_hit)
            cnt <= #`RD cnt;
        else if(a_hit && ~r_hit)
            cnt <= #`RD (cnt==MAX_OST_PER_THREAD) ? cnt : cnt + 'b1;
        else if(~a_hit && r_hit)
            cnt <= #`RD (cnt=='0) ? cnt : cnt - 'b1;
    end

    always @ (posedge clk_i or negedge reset_n_i) begin
        if(~reset_n_i)
            timeout_cnt <= #`RD '0;
        else if(timeout_clr_i)
            timeout_cnt <= #`RD '0;
        else if(~empty)
            timeout_cnt <= #`RD (timeout_cnt==TIMEOUT_MAX_CNT) ? timeout_cnt : timeout_cnt + 'b1;
        else if(r_hit_nonempty)
            timeout_cnt <= #`RD '0;
    end

    always_comb begin
        timeout_valid = timeout_cnt==TIMEOUT_MAX_CNT;
        timeout_slave = slave;
        timeout_id = id;
    end

end
endgenerate


endmodule
