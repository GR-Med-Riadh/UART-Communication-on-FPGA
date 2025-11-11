`timescale 1ns / 1ps

module UART_PARITY #(
    parameter DATA_WIDTH  = 8,
    parameter PARITY_TYPE = "none"  // "none", "even", "odd", "mark", "space"
)(
    input  wire [DATA_WIDTH-1:0] DATA_IN,
    output reg  PARITY_OUT
);

    integer i;
    reg parity_temp;

    always @(*) begin
        case (PARITY_TYPE)
            "even": begin
                parity_temp = 1'b0;
                for (i = 0; i < DATA_WIDTH; i = i + 1)
                    parity_temp = parity_temp ^ DATA_IN[i];
                PARITY_OUT = parity_temp;
            end
            "odd": begin
                parity_temp = 1'b1;
                for (i = 0; i < DATA_WIDTH; i = i + 1)
                    parity_temp = parity_temp ^ DATA_IN[i];
                PARITY_OUT = parity_temp;
            end
            "mark": begin
                PARITY_OUT = 1'b1;
            end
            "space": begin
                PARITY_OUT = 1'b0;
            end
            default: begin // "none"
                PARITY_OUT = 1'b0;
            end
        endcase
    end

endmodule