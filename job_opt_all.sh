#!/bin/sh
#SBATCH --time=12:00:00         
#SBATCH --nodes=1
#SBATCH --nodelist=node034

module load vivado/2024.1

# Run the HLS synthesis for all test files: 
# tiny_mountains, tiny_dam, small_mountains, small_dam

### Tiny mountains 
PROJECT_NAME="FLOOD_HLS_optimized_tiny_mountains" \
INPUT_FILE="test_files/tiny_mountains6c.in" \
NROWS="40" \
NCOLS="40" \
NCLOUDS="6" \
NUM_MIN="10" \
AUTOPIPELINE="false" \
vitis_hls -f run_FLOOD_HLS_optimized.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "

### Tiny Dam 
PROJECT_NAME="FLOOD_HLS_optimized_tiny_dam" \
INPUT_FILE="test_files/tiny_dam7c.in" \
NROWS="50" \
NCOLS="50" \
NCLOUDS="7" \
NUM_MIN="10" \
AUTOPIPELINE="false" \
vitis_hls -f run_FLOOD_HLS_optimized.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "

### Small Mountains 
PROJECT_NAME="FLOOD_HLS_optimized_small_mountains" \
INPUT_FILE="test_files/small_mountains9c.in" \
NROWS="60" \
NCOLS="80" \
NCLOUDS="9" \
NUM_MIN="100" \
AUTOPIPELINE="false" \
vitis_hls -f run_FLOOD_HLS_optimized.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "

### Small Dam
PROJECT_NAME="FLOOD_HLS_optimized_small_dam" \
INPUT_FILE="test_files/small_dam9c.in" \
NROWS="90" \
NCOLS="90" \
NCLOUDS="9" \
NUM_MIN="120" \
AUTOPIPELINE="false" \
vitis_hls -f run_FLOOD_HLS_optimized.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "