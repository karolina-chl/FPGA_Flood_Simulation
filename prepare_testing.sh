#!/bin/bash

###########################
###     FLAG SYSTEM     ###
###########################
# r: Rebuild CPU binary
# c: Run CPU Job
# b: Run Base FPGA Job
# o: Run Optimised FPGA Job

REMAKE_CPU=false
RUN_CPU=false
RUN_FPGA_BASE=false
RUN_FPGA_OPT=false
while getopts "rcbo" opt; do
    case $opt in
        r) REMAKE_CPU=true ;;
        c) RUN_CPU=true ;;
        b) RUN_FPGA=true ;;
        o) RUN_FPGA_OPT=true ;;
        *) usage ;;
    esac
done

if [[ $OPTIND -eq 1 ]]; then usage; fi

set -e

CPU_DIR="cpu_impl"
CPU_BINARY="flood"

# CPU binary building
if [[ "$REMAKE_CPU" == true ]]; then
    echo "Rebuilding CPU flood binary ..."
    cd "$CPU_DIR"
    make clean  # Cleaner than rm
    make flood
    cd ..
elif [[ ! -x "$CPU_DIR/$CPU_BINARY" ]]; then
    echo "CPU flood binary missing. Building now..."
    cd "$CPU_DIR" && make flood && cd ..
fi

# CPU job launch
if [[ "$RUN_CPU" == true ]]; then
    echo "Submitting CPU job..."
    cd "$CPU_DIR"
    CPU_JOB_ID=$(sbatch --parsable job.sh)
    echo "CPU job submitted with ID: ${CPU_JOB_ID}"
    cd ..
fi

# Base FPGA job launch
if [[ "$RUN_FPGA" == true ]]; then
    echo "Submitting Base FPGA job..."
    FPGA_JOB_ID=$(sbatch --parsable job_base.sh)
    echo "Base FPGA job submitted with ID: ${FPGA_JOB_ID}"
fi

# Optimised FPGA job launch
if [[ "$RUN_FPGA" == true ]]; then
    echo "NOT Implemented Yet"
fi
