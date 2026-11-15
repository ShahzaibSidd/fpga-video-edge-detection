module sobel_top #(
    parameter int SCREEN_WIDTH = 640,
    parameter int DATA_WIDTH   = 8
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

  localparam int PIPELINE_DELAY = (2 * SCREEN_WIDTH) + 2;
  logic [11:0] pixel_count;

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

  sobel_math #(
      .DATA_WIDTH(DATA_WIDTH)
  ) inst_math (
      .top_row  (top_row),
      .mid_row  (mid_row),
      .bot_row  (bot_row),
      .pixel_out(pixel_out)
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

  always_ff @(posedge clk) begin
    if (rst) begin
      pixel_count <= '0;
      valid_out   <= 1'b0;
    end else if (valid_in) begin
      if (pixel_count < PIPELINE_DELAY) begin
        pixel_count <= pixel_count + 1;
        valid_out   <= 1'b0;
      end else begin
        valid_out <= 1'b1;
      end
    end else begin
      valid_out <= 1'b0;
    end
  end

endmodule
