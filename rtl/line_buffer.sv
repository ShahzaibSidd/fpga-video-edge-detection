module line_buffer #(
    parameter logic SCREEN_WIDTH,
    parameter logic DATA_WIDTH
) (
    input  logic                  clk,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out
);

  logic [          DATA_WIDTH-1:0] buffer      [SCREEN_WIDTH];

  logic [$clog2(SCREEN_WIDTH)-1:0] counter = 0;

  always_ff @(posedge clk) begin
    buffer[counter] <= data_in;
    data_out        <= buffer[counter];
    if (counter == SCREEN_WIDTH - 1) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
endmodule
