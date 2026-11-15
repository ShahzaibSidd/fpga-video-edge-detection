module sobel_math #(
    parameter int DATA_WIDTH
) (
    input logic [2:0][DATA_WIDTH-1:0] top_row,
    input logic [2:0][DATA_WIDTH-1:0] mid_row,
    input logic [2:0][DATA_WIDTH-1:0] bot_row,

    output logic [DATA_WIDTH-1:0] pixel_out
);

  logic signed [10:0] Gx, Gy;
  logic [10:0] abs_Gx, abs_Gy, magnitude;

  always_comb begin
    Gx = (top_row[0] + (mid_row[0] << 1) + bot_row[0]) -
         (top_row[2] + (mid_row[2] << 1) + bot_row[2]);
    Gy = (top_row[0] + (top_row[1] << 1) + top_row[2]) -
         (bot_row[0] + (bot_row[1] << 1) + bot_row[2]);

    abs_Gx = (Gx[10]) ? -Gx : Gx;
    abs_Gy = (Gy[10]) ? -Gy : Gy;
    magnitude = abs_Gx + abs_Gy;

    pixel_out = (magnitude > 8'd100) ? 8'hFF : 8'h00;
  end
endmodule
