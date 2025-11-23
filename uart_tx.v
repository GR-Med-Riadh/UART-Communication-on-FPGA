`timescale 1ns / 1ps

module UART_TX #(
    parameter CLK_DIV_VAL = 434,
    parameter PARITY_BIT  = "none"  // "none", "even", "odd", "mark", "space"
)(
    input  wire CLK,          // system clock
    input  wire RST,          // synchronous reset
    input  wire UART_CLK_EN,  // oversampling (16x) UART clock enable
    output reg  UART_TXD,     // serial transmit data
    input  wire [7:0] DIN,    // input data to transmit
    input  wire DIN_VLD,      // input data valid
    output wire DIN_RDY       // transmitter ready
);

    // ------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------
    reg [2:0] tx_bit_count;
    reg [7:0] tx_data;
    reg tx_bit_count_en;
    reg tx_ready;
    reg tx_parity_bit;
    reg [1:0] tx_data_out_sel;
    reg tx_clk_div_clr;

    // FSM states (Verilog 2001)
    localparam [2:0] IDLE     = 3'b000;
    localparam [2:0] TXSYNC   = 3'b001;
    localparam [2:0] STARTBIT = 3'b010;
    localparam [2:0] DATABITS = 3'b011;
    localparam [2:0] PARITYBIT= 3'b100;
    localparam [2:0] STOPBIT  = 3'b101;

    reg [2:0] tx_pstate, tx_nstate;

    assign DIN_RDY = tx_ready;

    // ------------------------------------------------------
    // RX Clock Enable (simple divider)
    // ------------------------------------------------------
    reg [15:0] clk_div_cnt;
    wire tx_clk_en;

    always @(posedge CLK) begin
        if (RST)
            clk_div_cnt <= 0;
        else if (clk_div_cnt == CLK_DIV_VAL-1)
            clk_div_cnt <= 0;
        else if (UART_CLK_EN)
            clk_div_cnt <= clk_div_cnt + 1;
    end

    assign tx_clk_en = (clk_div_cnt == 0);

    // ------------------------------------------------------
    // Input Data Register
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (DIN_VLD && tx_ready)
            tx_data <= DIN;
    end

    // ------------------------------------------------------
    // Bit Counter
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (RST)
            tx_bit_count <= 3'b0;
        else if (tx_bit_count_en && tx_clk_en) begin
            if (tx_bit_count == 3'b111)
                tx_bit_count <= 3'b0;
            else
                tx_bit_count <= tx_bit_count + 1'b1;
        end
    end

    // ------------------------------------------------------
    // Parity Generator
    // ------------------------------------------------------
    always @(*) begin
        case (PARITY_BIT)
            "even":  tx_parity_bit = ^tx_data;   // XOR of all bits
            "odd":   tx_parity_bit = ~(^tx_data);
            "mark":  tx_parity_bit = 1'b1;
            "space": tx_parity_bit = 1'b0;
            default: tx_parity_bit = 1'b0;
        endcase
    end

    // ------------------------------------------------------
    // Output Data Selection
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (RST)
            UART_TXD <= 1'b1;
        else begin
            case (tx_data_out_sel)
                2'b01: UART_TXD <= 1'b0;             // Start bit
                2'b10: UART_TXD <= tx_data[tx_bit_count]; // Data bits
                2'b11: UART_TXD <= tx_parity_bit;    // Parity bit
                default: UART_TXD <= 1'b1;           // Stop bit / Idle
            endcase
        end
    end

    // ------------------------------------------------------
    // FSM: Present State Register
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (RST)
            tx_pstate <= IDLE;
        else
            tx_pstate <= tx_nstate;
    end

    // ------------------------------------------------------
    // FSM: Next State & Outputs Logic
    // ------------------------------------------------------
    always @(*) begin
        // default assignments
        tx_ready        = 0;
        tx_data_out_sel = 2'b00;
        tx_bit_count_en = 0;
        tx_clk_div_clr  = 0;
        tx_nstate       = tx_pstate;

        case (tx_pstate)
            IDLE: begin
                tx_ready        = 1;
                tx_data_out_sel = 2'b00;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 1;
                if (DIN_VLD)
                    tx_nstate = TXSYNC;
            end
            TXSYNC: begin
                tx_ready = 0;
                if (tx_clk_en)
                    tx_nstate = STARTBIT;
            end
            STARTBIT: begin
                tx_ready        = 0;
                tx_data_out_sel = 2'b01;
                if (tx_clk_en)
                    tx_nstate = DATABITS;
            end
            DATABITS: begin
                tx_ready        = 0;
                tx_data_out_sel = 2'b10;
                tx_bit_count_en = 1;
                if (tx_clk_en && tx_bit_count == 3'b111)
                    tx_nstate = (PARITY_BIT == "none") ? STOPBIT : PARITYBIT;
            end
            PARITYBIT: begin
                tx_ready        = 0;
                tx_data_out_sel = 2'b11;
                if (tx_clk_en)
                    tx_nstate = STOPBIT;
            end
            STOPBIT: begin
                tx_ready = 1;
                if (DIN_VLD)
                    tx_nstate = TXSYNC;
                else if (tx_clk_en)
                    tx_nstate = IDLE;
            end
        endcase
    end

endmodule

