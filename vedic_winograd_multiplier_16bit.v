module vedic_winograd_multiplier_16bit (
    input clk,
    input rst,
    input start,
    input signed [15:0] d0, d1, d2, d3,
    input signed [15:0] g0, g1, g2,
    output reg signed [31:0] y0,
    output reg signed [31:0] y1,
    output reg done
);

    // FSM States (parameter version for compatibility)
    parameter IDLE = 4'd0,
              LOAD = 4'd1,
              MUL0_SET = 4'd2, MUL0_WAIT = 4'd3,
              MUL1_SET = 4'd4, MUL1_WAIT = 4'd5,
              MUL2_SET = 4'd6, MUL2_WAIT = 4'd7,
              MUL3_SET = 4'd8, MUL3_WAIT = 4'd9,
              DONE = 4'd10;

    reg [3:0] state, next_state;

    // Internal wires and registers
    reg signed [15:0] m [0:3];
    reg signed [15:0] k [0:3];
    reg signed [15:0] A, B;
    wire signed [31:0] P;
    reg signed [31:0] t [0:3];

    // Instance of 16-bit Vedic multiplier
    vedic_multiplier_16bit mul (
        .A(A),
        .B(B),
        .P(P)
    );

    // State transitions
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM next state logic
    always @(*) begin
        case(state)
            IDLE: next_state = start ? LOAD : IDLE;
            LOAD: next_state = MUL0_SET;
            MUL0_SET: next_state = MUL0_WAIT;
            MUL0_WAIT: next_state = MUL1_SET;
            MUL1_SET: next_state = MUL1_WAIT;
            MUL1_WAIT: next_state = MUL2_SET;
            MUL2_SET: next_state = MUL2_WAIT;
            MUL2_WAIT: next_state = MUL3_SET;
            MUL3_SET: next_state = MUL3_WAIT;
            MUL3_WAIT: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Main logic
    always @(posedge clk) begin
        if (rst) begin
            y0 <= 0; y1 <= 0;
            done <= 0;
        end else begin
            case (state)
                LOAD: begin
                    m[0] <= d0 - d2;
                    m[1] <= d1 + d2;
                    m[2] <= d2 - d1;
                    m[3] <= d1 - d3;

                    k[0] <= g0;
                    k[1] <= (g0 + g1 + g2) >>> 1;
                    k[2] <= (g0 - g1 + g2) >>> 1;
                    k[3] <= g2;

                    t[0] <= 0; t[1] <= 0; t[2] <= 0; t[3] <= 0;
                    done <= 0;
                end
                MUL0_SET: begin A <= m[0]; B <= k[0]; end
                MUL0_WAIT: begin t[0] <= P; end
                MUL1_SET: begin A <= m[1]; B <= k[1]; end
                MUL1_WAIT: begin t[1] <= P; end
                MUL2_SET: begin A <= m[2]; B <= k[2]; end
                MUL2_WAIT: begin t[2] <= P; end
                MUL3_SET: begin A <= m[3]; B <= k[3]; end
                MUL3_WAIT: begin t[3] <= P; end
                DONE: begin
                    y0 <= t[0] + t[1] + t[2];
                    y1 <= t[1] - t[2] - t[3];
                    done <= 1;
                    // Debugging: print intermediate results
                    $display("DEBUG: t0=%d, t1=%d, t2=%d, t3=%d", t[0], t[1], t[2], t[3]);
                    $display("DEBUG: y0=%d, y1=%d", y0, y1);
                end
            endcase
        end
    end

endmodule

// Vedic 16-bit signed multiplier using behavioral model
module vedic_multiplier_16bit (
    input signed [15:0] A,
    input signed [15:0] B,
    output signed [31:0] P
);
    assign P = A * B;
endmodule
