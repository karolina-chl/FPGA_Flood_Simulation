#!/bin/sh
#SBATCH --time=00:45:00         
#SBATCH --nodes=1 

module load vivado/2024.1

### Tiny mountains 
PROJECT_NAME="FLOOD_HLS_optimized_tiny_mountains" \
INPUT_FILE="test_files/tiny_mountains6c.in" \
NROWS="40" \
NCOLS="40" \
NCLOUDS="6" \
NUM_MIN="10" \
AUTOPIPELINE="false" \
vitis_hls -f run_FLOOD_HLS_optimized.tcl | grep -v "OPMODE Input Warning" | grep -v "Time: "