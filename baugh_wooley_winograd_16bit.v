module baugh_wooley_winograd_16bit (
    input  signed [15:0] A,
    input  signed [15:0] B,
    output signed [31:0] P
);
    wire signed [3:0] A0 = A[3:0];
    wire signed [3:0] A1 = A[7:4];
    wire signed [3:0] A2 = A[11:8];
    wire signed [3:0] A3 = A[15:12];

    wire signed [3:0] B0 = B[3:0];
    wire signed [3:0] B1 = B[7:4];
    wire signed [3:0] B2 = B[11:8];
    wire signed [3:0] B3 = B[15:12];

    // Intermediate wires for partial Winograd products
    wire signed [7:0] m1, m2, m3;

    // Temp sums
    wire signed [3:0] A0_plus_A2 = A0 + A2;
    wire signed [3:0] A1_minus_A2 = A1 - A2;
    wire signed [3:0] A0_minus_A1 = A0 - A1;

    wire signed [3:0] B0_plus_B2 = B0 + B2;
    wire signed [3:0] B1_plus_B2 = B1 + B2;
    wire signed [3:0] B0_plus_B1 = B0 + B1;

    // Instantiate submultipliers
    mult4_signed m1_inst (.a(A0_plus_A2),  .b(B0_plus_B2),  .p(m1));
    mult4_signed m2_inst (.a(A1_minus_A2), .b(B1_plus_B2),  .p(m2));
    mult4_signed m3_inst (.a(A0_minus_A1), .b(B0_plus_B1),  .p(m3));

    wire signed [31:0] result = m1 + m2 + m3; // Winograd approximation

    assign P = result; // Approximate product (use as optimization path)

endmodule


// 4x4 Signed Multiplier Module
module mult4_signed (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [7:0] p
);
    assign p = a * b;
endmodule
