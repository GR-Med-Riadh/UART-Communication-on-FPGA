`timescale 1ns / 1ps

module UART_RX #(
    parameter CLK_DIV_VAL = 16,
    parameter PARITY_BIT  = "none"  // "none", "even", "odd", "mark", "space"
)(
    input  wire CLK,          // system clock
    input  wire RST,          // synchronous reset
    input  wire UART_CLK_EN,  // oversampling (16x) UART clock enable
    input  wire UART_RXD,     // serial receive data
    output reg  [7:0] DOUT,   // received data
    output reg  DOUT_VLD,     // data valid (1 cycle)
    output reg  FRAME_ERROR,  // stop bit error (1 cycle)
    output reg  PARITY_ERROR  // parity error (1 cycle)
);

    // ------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------
    reg [2:0] rx_bit_count;
    reg [7:0] rx_data;
    reg rx_parity_bit;
    reg rx_parity_error;
    reg fsm_idle, fsm_databits, fsm_stopbit;

    // FSM states (Verilog 2001 style)
    localparam [2:0] IDLE     = 3'b000;
    localparam [2:0] STARTBIT = 3'b001;
    localparam [2:0] DATABITS = 3'b010;
    localparam [2:0] PARITYBIT= 3'b011;
    localparam [2:0] STOPBIT  = 3'b100;

    reg [2:0] fsm_pstate, fsm_nstate;

    // ------------------------------------------------------
    // RX Clock Enable (simple divider)
    // ------------------------------------------------------
    reg [15:0] clk_div_cnt;
    wire rx_clk_en;

    always @(posedge CLK) begin
        if (RST)
            clk_div_cnt <= 0;
        else if (clk_div_cnt == CLK_DIV_VAL-1)
            clk_div_cnt <= 0;
        else
            clk_div_cnt <= clk_div_cnt + 1;
    end

    assign rx_clk_en = (clk_div_cnt == 0);

    // ------------------------------------------------------
    // Bit counter
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (RST)
            rx_bit_count <= 3'b0;
        else if (rx_clk_en && fsm_databits) begin
            if (rx_bit_count == 3'b111)
                rx_bit_count <= 3'b0;
            else
                rx_bit_count <= rx_bit_count + 1'b1;
        end
    end

    // ------------------------------------------------------
    // Data shift register
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (rx_clk_en && fsm_databits)
            rx_data <= {UART_RXD, rx_data[7:1]};
    end

    // ------------------------------------------------------
    // Parity generator/check
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (rx_clk_en) begin
            case (PARITY_BIT)
                "even":  rx_parity_bit <= ^rx_data;  // XOR of all bits
                "odd":   rx_parity_bit <= ~(^rx_data);
                "mark":  rx_parity_bit <= 1'b1;
                "space": rx_parity_bit <= 1'b0;
                default: rx_parity_bit <= 1'b0;
            endcase

            if (PARITY_BIT != "none")
                rx_parity_error <= rx_parity_bit ^ UART_RXD;
            else
                rx_parity_error <= 1'b0;
        end
    end

    // ------------------------------------------------------
    // FSM: Present state
    // ------------------------------------------------------
    always @(posedge CLK) begin
        if (RST)
            fsm_pstate <= IDLE;
        else
            fsm_pstate <= fsm_nstate;
    end

    // ------------------------------------------------------
    // FSM: Next state & control signals
    // ------------------------------------------------------
    always @(*) begin
        // default
        fsm_idle     = 0;
        fsm_databits = 0;
        fsm_stopbit  = 0;
        fsm_nstate   = fsm_pstate;

        case (fsm_pstate)
            IDLE: begin
                fsm_idle = 1;
                if (UART_RXD == 0)
                    fsm_nstate = STARTBIT;
            end
            STARTBIT: begin
                if (rx_clk_en)
                    fsm_nstate = DATABITS;
            end
            DATABITS: begin
                fsm_databits = 1;
                if (rx_clk_en && rx_bit_count == 3'b111)
                    fsm_nstate = (PARITY_BIT == "none") ? STOPBIT : PARITYBIT;
            end
            PARITYBIT: begin
                if (rx_clk_en)
                    fsm_nstate = STOPBIT;
            end
            STOPBIT: begin
                fsm_stopbit = 1;
                if (rx_clk_en)
                    fsm_nstate = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------
    // Output registers
    // ------------------------------------------------------
    wire rx_done = rx_clk_en && fsm_stopbit;

    always @(posedge CLK) begin
        if (RST) begin
            DOUT         <= 0;
            DOUT_VLD     <= 0;
            FRAME_ERROR  <= 0;
            PARITY_ERROR <= 0;
        end else begin
            DOUT         <= rx_data;
            DOUT_VLD     <= rx_done && !rx_parity_error && UART_RXD;
            FRAME_ERROR  <= rx_done && !UART_RXD;
            PARITY_ERROR <= rx_done && rx_parity_error;
        end
    end

endmodule