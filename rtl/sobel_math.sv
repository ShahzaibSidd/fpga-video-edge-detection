module sobel_math #(
    parameter int DATA_WIDTH
) (
    input logic [2:0][DATA_WIDTH-1:0] top_row,
    // The Sobel kernels have a zero weight at the center column, so the center
    // pixel mid_row[1] is intentionally never read.
    /* verilator lint_off UNUSEDSIGNAL */
    input logic [2:0][DATA_WIDTH-1:0] mid_row,
    /* verilator lint_on UNUSEDSIGNAL */
    input logic [2:0][DATA_WIDTH-1:0] bot_row,

    output logic [DATA_WIDTH-1:0] pixel_out
);

  logic signed [10:0] Gx, Gy;
  logic [10:0] abs_Gx, abs_Gy, magnitude;

  always_comb begin
    // Zero-extend each 8-bit pixel into the 11-bit signed accumulation domain
    // before the kernel arithmetic. Max |G| = 255*4 = 1020, which fits in
    // signed 11 bits ([-1024, 1023]).
    Gx = (11'(top_row[0]) + (11'(mid_row[0]) << 1) + 11'(bot_row[0])) -
         (11'(top_row[2]) + (11'(mid_row[2]) << 1) + 11'(bot_row[2]));
    Gy = (11'(top_row[0]) + (11'(top_row[1]) << 1) + 11'(top_row[2])) -
         (11'(bot_row[0]) + (11'(bot_row[1]) << 1) + 11'(bot_row[2]));

    abs_Gx = (Gx[10]) ? unsigned'(-Gx) : unsigned'(Gx);
    abs_Gy = (Gy[10]) ? unsigned'(-Gy) : unsigned'(Gy);
    magnitude = abs_Gx + abs_Gy;

    pixel_out = (magnitude > 11'd100) ? 8'hFF : 8'h00;
  end
endmodule
