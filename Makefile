# --- Configuration ---
TOP_MODULE = sobel_top

# Directories
RTL_DIR = rtl
TB_DIR = tb
SCRIPT_DIR = scripts
DATA_DIR = data
OBJ_DIR = obj_dir

# --- Dynamic File Discovery ---
# Automatically grabs EVERY .sv and .cpp file currently in these folders
SV_FILES = $(wildcard $(RTL_DIR)/*.sv)
CPP_FILES = $(wildcard $(TB_DIR)/*.cpp)

# --- Verilator Compiler Flags ---
# -cc: Transpile to C++
# --exe: Generate a C++ wrapper executable
# --build: Tell Verilator to invoke GCC/Clang automatically
# --trace: Enable GTKWave .vcd waveform dumping
# -I: Tell Verilator where to look for imported SV modules
VFLAGS = -cc --exe --build --trace -Wall
VFLAGS += -j 0 
VFLAGS += -I$(RTL_DIR)
VFLAGS += --top-module $(TOP_MODULE)

# Define which targets are commands, not physical files
.PHONY: all hex build run video clean sim

# The master pipeline target
sim: hex build run video

# Step 1: Pre-processing
hex:
	python3 $(SCRIPT_DIR)/video2hex.py

# Step 2: Hardware Compilation
build:
	@echo "Compiling: $(SV_FILES) and $(CPP_FILES)"
	verilator $(VFLAGS) $(SV_FILES) $(CPP_FILES)

# Step 3: Execute Simulation
run:
	./$(OBJ_DIR)/V$(TOP_MODULE)

# Step 4: Post-processing
video:
	python3 $(SCRIPT_DIR)/hex2video.py

# Clean build artifacts
clean:
	rm -rf $(OBJ_DIR)
	rm -f $(DATA_DIR)/input/*.hex
	rm -f $(DATA_DIR)/output/*.hex
	rm -f $(DATA_DIR)/output/*.vcd
