#!/bin/sh
#SBATCH --time=00:45:00         
#SBATCH --nodes=1 

######### Tiny mountains 
#Evaluate the correctness of the C-Simulation 
python3 test_files/check_correctness.py cpu_impl/tiny_mountains.out FLOOD_HLS_base_tiny_mountains/solution_FLOOD_HLS_base_tiny_mountains/csim/build/tiny_mountains.out
# Evaluate the correctness of the RTL Co-simulation 
python3 test_files/check_correctness.py cpu_impl/tiny_mountains.out FLOOD_HLS_base_tiny_mountains/solution_FLOOD_HLS_base_tiny_mountains/sim/wrapc_pc/tiny_mountains.out 

######## Tiny Dam 
#Evaluate the correctness of the C-Simulation 
python3 test_files/check_correctness.py cpu_impl/tiny_dam.out FLOOD_HLS_base_tiny_dam/solution_FLOOD_HLS_base_tiny_dam/csim/build/tiny_dam.out
# Evaluate the correctness of the RTL Co-simulation 
python3 test_files/check_correctness.py cpu_impl/tiny_dam.out FLOOD_HLS_base_tiny_dam/solution_FLOOD_HLS_base_tiny_dam/sim/wrapc_pc/tiny_dam.out 

####### Small Mountains
#Evaluate the correctness of the C-Simulation 
python3 test_files/check_correctness.py cpu_impl/small_mountains.out FLOOD_HLS_base_small_mountains/solution_FLOOD_HLS_base_small_mountains/csim/build/small_mountains.out
# Evaluate the correctness of the RTL Co-simulation 
python3 test_files/check_correctness.py cpu_impl/small_mountains.out FLOOD_HLS_base_small_mountains/solution_FLOOD_HLS_base_small_mountains/sim/wrapc_pc/small_mountains.out 

####### Small Dam
#Evaluate the correctness of the C-Simulation 
python3 test_files/check_correctness.py cpu_impl/small_dam.out FLOOD_HLS_base_small_dam/solution_FLOOD_HLS_base_small_dam/csim/build/small_dam.out
# Evaluate the correctness of the RTL Co-simulation 
python3 test_files/check_correctness.py cpu_impl/small_dam.out FLOOD_HLS_base_small_dam/solution_FLOOD_HLS_base_small_dam/sim/wrapc_pc/small_dam.out 