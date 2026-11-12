module sobel_top #(
    parameter logic SCREEN_WIDTH,
    parameter logic DATA_WIDTH
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic [DATA_WIDTH-1:0] pixel_in,
    output logic [DATA_WIDTH-1:0] pixel_out
);

  logic [DATA_WIDTH-1:0] top_row [3];
  logic [DATA_WIDTH-1:0] mid_row [3];

  logic [DATA_WIDTH-1:0] top_out;
  logic [DATA_WIDTH-1:0] mid_out;

  line_buffer #(
      .SCREEN_WIDTH(SCREEN_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH)
  ) buff_top (
      .clk(clk),
      .data_in(mid_out),
      .data_out(top_out),
  );

  line_buffer #(
      .SCREEN_WIDTH(SCREEN_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH)
  ) buff_mid (
      .clk(clk),
      .data_in(pixel_in),
      .data_out(mid_out),
  );

  always_ff @(posedge clk) begin

  end

endmodule
