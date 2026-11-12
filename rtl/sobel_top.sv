module sobel_top #(
    parameter int SCREEN_WIDTH,
    parameter int DATA_WIDTH
) (
    input logic                  clk,
    input logic                  rst,
    input logic                  valid_in,
    input logic [DATA_WIDTH-1:0] pixel_in,

    output logic                  valid_out,
    output logic [DATA_WIDTH-1:0] pixel_out
);

  logic [2:0][DATA_WIDTH-1:0] top_row;
  logic [2:0][DATA_WIDTH-1:0] mid_row;
  logic [2:0][DATA_WIDTH-1:0] bot_row;

  logic [DATA_WIDTH-1:0] top_out;
  logic [DATA_WIDTH-1:0] mid_out;

  logic [DATA_WIDTH-1:0] chosen_in = (valid_in) ? pixel_in : 'd0;

  line_buffer #(
      .SCREEN_WIDTH(SCREEN_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH)
  ) buff_top (
      .clk(clk),
      .data_in(mid_out),
      .data_out(top_out)
  );

  line_buffer #(
      .SCREEN_WIDTH(SCREEN_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH)
  ) buff_mid (
      .clk(clk),
      .data_in(chosen_in),
      .data_out(mid_out)
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      top_row <= '0;
      mid_row <= '0;
      bot_row <= '0;
    end else begin
      top_row <= {top_row[1:0], top_out};
      mid_row <= {mid_row[1:0], mid_out};
      bot_row <= {bot_row[1:0], chosen_in};
    end
  end

endmodule
