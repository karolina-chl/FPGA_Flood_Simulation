#!/bin/bash

usage() {
    cat << 'EOF'
    ###########################
    ###     FLAG SYSTEM     ###
    ###########################
    # --build-cpu: Build CPU binary
    # --run-cpu: Run CPU Job
    # --base-non-pipelined: Run Non-Pipelined Base FPGA Job
    # --base-pipelined: Run Pipelined Base FPGA Job
    # --opt: Run Optimised FPGA Job
EOF
}

if [[ $# -eq 0 ]]; then
    echo "No flags provided. Displaying help:"
    usage
    exit 0
fi

MAKE_CPU=false
RUN_CPU=false
RUN_FPGA_NON_PIPE_BASE=false
RUN_FPGA_PIPE_BASE=false
RUN_FPGA_OPT=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-cpu) MAKE_CPU=true; shift ;;
        --run-cpu) RUN_CPU=true; shift ;;
        --base-non-pipelined) RUN_FPGA_NON_PIPE_BASE=true; shift ;;
        --base-pipelined) RUN_FPGA_PIPE_BASE=true; shift ;;
        --opt) RUN_FPGA_OPT=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: Unknown flag '$1'"; usage; exit 1 ;;
    esac
done

set -e

CPU_DIR="cpu_impl"
CPU_BINARY="flood"

# CPU binary building
if [[ "$MAKE_CPU" == true ]]; then
    echo "Rebuilding CPU flood binary ..."
    cd "$CPU_DIR"
    make clean
    make flood
    cd ..
fi

# CPU job launch
if [[ "$RUN_CPU" == true ]]; then
    if [[ ! -x "$CPU_DIR/$CPU_BINARY" ]]; then
        echo "CPU flood binary missing. Building now..."
        cd "$CPU_DIR"
        make flood
        cd ..
    fi
    echo "Submitting CPU job..."
    cd "$CPU_DIR"
    CPU_JOB_ID=$(sbatch --parsable job.sh)
    echo "CPU job submitted with ID: ${CPU_JOB_ID}"
    cd ..
fi

# Base non-pipelined FPGA job launch
if [[ "$RUN_FPGA_NON_PIPE_BASE" == true ]]; then
    echo "Submitting Non-Pipelined Base FPGA job..."
    FPGA_JOB_ID=$(sbatch --parsable job_base_all.sh)
    echo "Non-Pipelined Base FPGA job submitted with ID: ${FPGA_JOB_ID}"
fi

# Base pipelined FPGA job launch
if [[ "$RUN_FPGA_PIPE_BASE" == true ]]; then
    echo "Submitting Pipelined Base FPGA job..."
    FPGA_JOB_ID=$(sbatch --parsable job_base_all_pipelined.sh)
    echo "Pipelined Base FPGA job submitted with ID: ${FPGA_JOB_ID}"
fi

# Optimised FPGA job launch
if [[ "$RUN_FPGA_OPT" == true ]]; then
    echo "NOT There Yet"
fi
