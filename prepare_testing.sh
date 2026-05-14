#!/bin/bash

set -e

make_cpu_flood=true

CPU_DIR="cpu_impl"

cd "$CPU_DIR"
if [[ "$make_cpu_flood" == true || ! -x "$CPU_BINARY" ]]; then
    echo "Building CPU flood binary..."
    rm flood
    make flood
else
    echo "Using existing CPU flood binary."
fi

echo "Submitting CPU job..."
CPU_JOB_ID=$(sbatch --parsable job.sh)
echo "CPU job submitted with ID: ${CPU_JOB_ID}"
cd ..

echo "Submitting FPGA job..."
FPGA_JOB_ID=$(sbatch --parsable job_base.sh)
echo "FPGA job submitted with ID: ${FPGA_JOB_ID}"
