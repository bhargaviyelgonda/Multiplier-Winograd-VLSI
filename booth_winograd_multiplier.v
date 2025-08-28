module booth_winograd_multiplier (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire signed [15:0] d0, d1, d2, d3,  // Data inputs
    input  wire signed [15:0] g0, g1, g2,      // Kernel weights
    output reg  signed [15:0] y0, y1,           // Output results
    output reg          done
);
    // ----- Stage 1: Input and Kernel Transformations -----
    // Input transformation (Winograd)
    wire signed [15:0] m0 = d0 - d2;
    wire signed [15:0] m1 = d1 + d2;
    wire signed [15:0] m2 = d2 - d1;
    wire signed [15:0] m3 = d1 - d3;
    
    // Kernel transformation
    wire signed [15:0] k0 = g0;
    wire signed [15:0] k1 = (g0 + g1 + g2) >> 1;
    wire signed [15:0] k2 = (g0 - g1 + g2) >> 1;
    wire signed [15:0] k3 = g2;
    
    // Registers for storing multiplication results (32-bit)
    reg signed [31:0] t0, t1, t2, t3;
    
    // Intermediate registers for fixed-point conversion.
    reg signed [31:0] sum0, sum1;
    
    // ----- Stage 2: FSM to Perform Multiplications -----
    // Define FSM states.
    localparam IDLE            = 4'd0;
    localparam MULT0_LAUNCH    = 4'd1;
    localparam MULT0_WAIT      = 4'd2;
    localparam MULT1_LAUNCH    = 4'd3;
    localparam MULT1_WAIT      = 4'd4;
    localparam MULT2_LAUNCH    = 4'd5;
    localparam MULT2_WAIT      = 4'd6;
    localparam MULT3_LAUNCH    = 4'd7;
    localparam MULT3_WAIT      = 4'd8;
    localparam OUTPUT_STATE    = 4'd9;
    
    reg [3:0] mult_state;
    
    // Control signals for the Booth multiplier instance.
    reg         mult_start;
    reg  signed [15:0] op_a, op_b;  // Operands for current multiplication.
    
    // Wires for the Booth multiplier outputs.
    wire signed [31:0] mult_product;
    wire               mult_done;
    
    // Instantiate the Booth multiplier.
    booth_multiplier_16 booth_mult_inst (
        .clk(clk),
        .rst(rst),
        .start(mult_start),
        .multiplicand(op_a),
        .multiplier(op_b),
        .product(mult_product),
        .done(mult_done)
    );
    
    // FSM: Sequencing the multiplications and output transformation.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mult_state <= IDLE;
            mult_start <= 1'b0;
            t0 <= 32'd0; t1 <= 32'd0; t2 <= 32'd0; t3 <= 32'd0;
            y0 <= 16'd0; y1 <= 16'd0;
            done <= 1'b0;
        end else begin
            case (mult_state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        mult_state <= MULT0_LAUNCH;
                    end
                end
                // Multiply m0 * k0.
                MULT0_LAUNCH: begin
                    op_a <= m0;
                    op_b <= k0;
                    mult_start <= 1'b1;
                    mult_state <= MULT0_WAIT;
                end
                MULT0_WAIT: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        t0 <= mult_product;
                        mult_state <= MULT1_LAUNCH;
                    end
                end
                // Multiply m1 * k1.
                MULT1_LAUNCH: begin
                    op_a <= m1;
                    op_b <= k1;
                    mult_start <= 1'b1;
                    mult_state <= MULT1_WAIT;
                end
                MULT1_WAIT: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        t1 <= mult_product;
                        mult_state <= MULT2_LAUNCH;
                    end
                end
                // Multiply m2 * k2.
                MULT2_LAUNCH: begin
                    op_a <= m2;
                    op_b <= k2;
                    mult_start <= 1'b1;
                    mult_state <= MULT2_WAIT;
                end
                MULT2_WAIT: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        t2 <= mult_product;
                        mult_state <= MULT3_LAUNCH;
                    end
                end
                // Multiply m3 * k3.
                MULT3_LAUNCH: begin
                    op_a <= m3;
                    op_b <= k3;
                    mult_start <= 1'b1;
                    mult_state <= MULT3_WAIT;
                end
                MULT3_WAIT: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        t3 <= mult_product;
                        mult_state <= OUTPUT_STATE;
                    end
                end
                // OUTPUT_STATE: Compute the final output.
                OUTPUT_STATE: begin
                    // Compute intermediate sums.
                    sum0 = t0 + t1 + t2;
                    sum1 = t1 - t2 - t3;
                    // Fixed-point conversion: arithmetic right shift by 16 bits.
                   y0 <= sum0 >>> 16;
                   y1 <= sum1 >>> 16;


                    done <= 1'b1;
                    mult_state <= IDLE;
                end
                default: mult_state <= IDLE;
            endcase
        end
    end
endmodule
