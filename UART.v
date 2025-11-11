module UART #
(
    parameter CLK_FREQ      = 50000000,
    parameter BAUD_RATE     = 115200,
    parameter PARITY_BIT    = "none", // "none", "even", "odd", "mark", "space"
    parameter USE_DEBOUNCER = 1       // 1 = true, 0 = false
)
(
    input  wire CLK,
    input  wire RST,
    output wire UART_TXD,
    input  wire UART_RXD,
    input  wire [7:0] DIN,
    input  wire DIN_VLD,
    output wire DIN_RDY,
    output wire [7:0] DOUT,
    output wire DOUT_VLD,
    output wire FRAME_ERROR,
    output wire PARITY_ERROR
);

    // -----------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------
    localparam OS_CLK_DIV_VAL   = CLK_FREQ / (16*BAUD_RATE);
    localparam UART_CLK_DIV_VAL = CLK_FREQ / (OS_CLK_DIV_VAL*BAUD_RATE);

    // -----------------------------------------------------------
    // Internal signals
    // -----------------------------------------------------------
    wire os_clk_en;
    reg  uart_rxd_meta_n;
    reg  uart_rxd_synced_n;
    wire uart_rxd_debounced_n;
    wire uart_rxd_debounced;

    // -----------------------------------------------------------
    //  UART OVERSAMPLING CLOCK DIVIDER
    // -----------------------------------------------------------
    UART_CLK_DIV #(
        .DIV_MAX_VAL(OS_CLK_DIV_VAL),
        .DIV_MARK_POS(OS_CLK_DIV_VAL-1)
    ) os_clk_divider_i (
        .CLK(CLK),
        .RST(RST),
        .CLEAR(RST),
        .ENABLE(1'b1),
        .DIV_MARK(os_clk_en)
    );

    // -----------------------------------------------------------
    //  UART RXD CROSS DOMAIN SYNCH
    // -----------------------------------------------------------
    always @(posedge CLK) begin
        uart_rxd_meta_n   <= ~UART_RXD;
        uart_rxd_synced_n <= uart_rxd_meta_n;
    end

    // -----------------------------------------------------------
    //  UART RXD DEBOUNCER
    // -----------------------------------------------------------
    generate
        if (USE_DEBOUNCER) begin
            UART_DEBOUNCER #(
                .LATENCY(4)
            ) debouncer_i (
                .CLK(CLK),
                .DEB_IN(uart_rxd_synced_n),
                .DEB_OUT(uart_rxd_debounced_n)
            );
        end else begin
            assign uart_rxd_debounced_n = uart_rxd_synced_n;
        end
    endgenerate

    assign uart_rxd_debounced = ~uart_rxd_debounced_n;

    // -----------------------------------------------------------
    //  UART RECEIVER
    // -----------------------------------------------------------
    UART_RX #(
        .CLK_DIV_VAL(UART_CLK_DIV_VAL),
        .PARITY_BIT(PARITY_BIT)
    ) uart_rx_i (
        .CLK(CLK),
        .RST(RST),
        .UART_CLK_EN(os_clk_en),
        .UART_RXD(uart_rxd_debounced),
        .DOUT(DOUT),
        .DOUT_VLD(DOUT_VLD),
        .FRAME_ERROR(FRAME_ERROR),
        .PARITY_ERROR(PARITY_ERROR)
    );

    // -----------------------------------------------------------
    //  UART TRANSMITTER
    // -----------------------------------------------------------
    UART_TX #(
        .CLK_DIV_VAL(UART_CLK_DIV_VAL),
        .PARITY_BIT(PARITY_BIT)
    ) uart_tx_i (
        .CLK(CLK),
        .RST(RST),
        .UART_CLK_EN(os_clk_en),
        .UART_TXD(UART_TXD),
        .DIN(DIN),
        .DIN_VLD(DIN_VLD),
        .DIN_RDY(DIN_RDY)
    );

endmodule