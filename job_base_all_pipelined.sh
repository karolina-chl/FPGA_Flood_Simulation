#!/bin/sh
#SBATCH --time=12:00:00         
#SBATCH --nodes=1              

module load vivado/2024.1

# Run the HLS synthesis for all test files: 
# tiny_mountains, tiny_dam, small_mountains, small_dam

### Tiny mountains 
PROJECT_NAME="FLOOD_HLS_base_tiny_mountains_pipelined" \
INPUT_FILE="test_files/tiny_mountains6c.in" \
NROWS="40" \
NCOLS="40" \
NCLOUDS="6" \
NUM_MIN="10" \
AUTOPIPELINE="true" \
vitis_hls -f run_FLOOD_HLS_base.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "

### Tiny Dam 
PROJECT_NAME="FLOOD_HLS_base_tiny_dam_pipelined" \
INPUT_FILE="test_files/tiny_dam7c.in" \
NROWS="50" \
NCOLS="50" \
NCLOUDS="7" \
NUM_MIN="10" \
AUTOPIPELINE="true" \
vitis_hls -f run_FLOOD_HLS_base.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "

### Small Mountains 
PROJECT_NAME="FLOOD_HLS_base_small_mountains_pipelined" \
INPUT_FILE="test_files/small_mountains9c.in" \
NROWS="60" \
NCOLS="80" \
NCLOUDS="9" \
NUM_MIN="100" \
AUTOPIPELINE="true" \
vitis_hls -f run_FLOOD_HLS_base.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "

### Small Dam
PROJECT_NAME="FLOOD_HLS_base_small_dam_pipelined" \
INPUT_FILE="test_files/small_dam9c.in" \
NROWS="90" \
NCOLS="90" \
NCLOUDS="9" \
NUM_MIN="120" \
AUTOPIPELINE="true" \
vitis_hls -f run_FLOOD_HLS_base.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "