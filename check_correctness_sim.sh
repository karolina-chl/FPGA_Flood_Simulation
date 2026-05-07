#!/bin/sh
#SBATCH --time=00:45:00         
#SBATCH --nodes=1 

python3 test_files/check_correctness.py cpu_impl/tiny_mountains.out FLOOD_HLS_base/solution_FLOOD_HLS_base/csim/build/tiny_mountains.out