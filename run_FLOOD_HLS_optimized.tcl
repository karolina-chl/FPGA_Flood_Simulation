#project name and input file 
set project_name $::env(PROJECT_NAME)
set input_file $::env(INPUT_FILE)

# Define preprocessor macros for the number of rows, columns, and clouds
set defs "-DNROWS=$::env(NROWS) -DNCOLS=$::env(NCOLS) -DNCLOUDS=$::env(NCLOUDS) -DNUM_MIN=$::env(NUM_MIN)" 

# Create a new Vitis HLS project.
open_project -reset $project_name
set_top do_compute 

# Add files and testbed
add_files FLOOD.h -cflags $defs
add_files rng.cpp
add_files flood_HLS_optimized.cpp -cflags $defs
add_files -tb test_FLOOD_optimized.cpp -cflags $defs

# Read the input arguments from the file
set fp [open $input_file r]
set arg_string [read $fp]
close $fp

# Create a solution
open_solution -reset "solution_${project_name}"

# Set the target FPGA part (modify as needed)
set_part {virtexuplusHBM}

# Set clock
create_clock -period 250MHz

# Run C simulation
csim_design -argv "$arg_string"

# Disable automatic pipelining (what does it change if you remove/comment this command?)
if {$::env(AUTOPIPELINE) eq "false"} {
    config_compile -pipeline_loops 0
}

# Run High-Level Synthesis (HLS)
csynth_design

# Run co-simulation (Attention, this might require a long time, you may want to comment it out for development purposes)
cosim_design -argv "$arg_string" -trace_level none -enable_binary_tv 

exit

