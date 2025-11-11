`timescale 1ns / 1ps

module UART_DEBOUNCER #(
    parameter LATENCY = 4  // latency of debouncer in clock cycles
)(
    input  wire CLK,       // system clock
    input  wire DEB_IN,    // input signal from outside FPGA
    output reg  DEB_OUT    // debounced output
);

    localparam SHREG_DEPTH = LATENCY - 1;

    // shift register
    reg [SHREG_DEPTH-1:0] input_shreg;
    wire output_reg_rst;
    wire output_reg_set;

    integer i;

    // input shift register process
    always @(posedge CLK) begin
        input_shreg <= {input_shreg[SHREG_DEPTH-2:0], DEB_IN};
    end

    // compute output_reg_rst: reset when all bits low
    assign output_reg_rst = ~(DEB_IN | |input_shreg);

    // compute output_reg_set: set when all bits high
    assign output_reg_set = DEB_IN & &input_shreg;

    // output register
    always @(posedge CLK) begin
        if (output_reg_rst)
            DEB_OUT <= 1'b0;
        else if (output_reg_set)
            DEB_OUT <= 1'b1;
    end

endmodule