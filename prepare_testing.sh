#!/bin/bash

set -e

make_cpu_flood=false

CPU_DIR="cpu_impl"

if [[ "$make_cpu_flood" == true || ! -x "$CPU_BINARY" ]]; then
    echo "Building CPU flood binary..."
    cd "$CPU_DIR"
    make flood
    cd ..
else
    echo "Using existing CPU flood binary."
fi

echo "Submitting CPU job..."
CPU_JOB_ID=$(sbatch --parsable ${CPU_DIR}/job.sh)
echo "CPU job submitted with ID: ${CPU_JOB_ID}"

echo "Submitting FPGA job..."
FPGA_JOB_ID=$(sbatch --parsable job_base.sh)
echo "FPGA job submitted with ID: ${FPGA_JOB_ID}"
