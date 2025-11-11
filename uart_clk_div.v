`timescale 1ns / 1ps

module UART_CLK_DIV #(
    parameter DIV_MAX_VAL  = 16,
    parameter DIV_MARK_POS = 1
)(
    input  wire CLK,       // system clock
    input  wire RST,       // high active synchronous reset
    input  wire CLEAR,     // clock divider counter clear
    input  wire ENABLE,    // clock divider counter enable
    output reg  DIV_MARK   // output divider mark (divided clock enable)
);

    // Calculate width of counter
    localparam CLK_DIV_WIDTH = $clog2(DIV_MAX_VAL);

    reg [CLK_DIV_WIDTH-1:0] clk_div_cnt;
    wire clk_div_cnt_mark;

    // Counter process
    always @(posedge CLK) begin
        if (CLEAR) begin
            clk_div_cnt <= {CLK_DIV_WIDTH{1'b0}};
        end else if (ENABLE) begin
            if (clk_div_cnt == DIV_MAX_VAL-1)
                clk_div_cnt <= {CLK_DIV_WIDTH{1'b0}};
            else
                clk_div_cnt <= clk_div_cnt + 1'b1;
        end
    end

    // Mark signal
    assign clk_div_cnt_mark = (clk_div_cnt == DIV_MARK_POS) ? 1'b1 : 1'b0;

    // Output process
    always @(posedge CLK) begin
        DIV_MARK <= ENABLE & clk_div_cnt_mark;
    end

endmodule