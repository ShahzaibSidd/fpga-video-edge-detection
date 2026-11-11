#include "Vsobel_top.h" // Verilator-generated header for your SV module
#include "verilated.h"
#include "verilated_vcd_c.h" // For GTKWave waveform generation
#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  // Instantiate the hardware module
  Vsobel_top *top = new Vsobel_top;

  // Set up GTKWave tracing
  VerilatedVcdC *tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open("../data/output/wave.vcd");

  // Open file streams
  std::ifstream infile("../data/input/frame_in.hex");
  std::ofstream outfile("../data/output/frame_out.hex");

  if (!infile.is_open() || !outfile.is_open()) {
    std::cerr << "Fatal: Could not open hex files." << std::endl;
    return -1;
  }

  int sim_time = 0;
  std::string line;

  // Hardware Reset Sequence
  top->clk = 0;
  top->rst = 1;
  top->valid_in = 0;
  top->pixel_in = 0;

  for (int i = 0; i < 10; i++) {
    top->clk = !top->clk;
    top->eval();
    tfp->dump(sim_time++);
  }
  top->rst = 0;

  // Main Video Streaming Loop
  while (std::getline(infile, line) && !Verilated::gotFinish()) {
    int pixel_val = std::stoi(line, nullptr, 16);

    // Falling edge: Drive the input signals
    top->clk = 0;
    top->pixel_in = pixel_val;
    top->valid_in = 1;
    top->eval();
    tfp->dump(sim_time++);

    // Rising edge: Hardware latches data and computes
    top->clk = 1;
    top->eval();
    tfp->dump(sim_time++);

    // If the hardware asserts valid_out, capture the processed pixel
    if (top->valid_out) {
      char hex_str[4];
      snprintf(hex_str, sizeof(hex_str), "%02X", top->pixel_out);
      outfile << hex_str << "\n";
    }
  }

  // Pipeline Flush
  // When the file ends, the last two rows of the image are still trapped inside
  // the line buffers. We must clock the system empty.
  top->valid_in = 0;
  top->pixel_in = 0;

  int flush_cycles = (640 * 2) + 10; // 2 rows + margin for the 3x3 grid

  for (int i = 0; i < flush_cycles; i++) {
    top->clk = 0;
    top->eval();
    tfp->dump(sim_time++);
    top->clk = 1;
    top->eval();
    tfp->dump(sim_time++);

    if (top->valid_out) {
      char hex_str[4];
      snprintf(hex_str, sizeof(hex_str), "%02X", top->pixel_out);
      outfile << hex_str << "\n";
    }
  }

  // Cleanup
  top->final();
  tfp->close();
  infile.close();
  outfile.close();
  delete top;
  delete tfp;

  return 0;
}
