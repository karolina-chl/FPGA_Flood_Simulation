#!/bin/bash

usage() {
    cat << 'EOF'
    ###########################
    ###     FLAG SYSTEM     ###
    ###########################
    -m, --mode <execution type>      FPGA Running Mode: synth, or all (default: synth) To run RTL Co-Simulation as well set it to all.
    -t, --terrain <terrain>          Terrain to use for the execution: tiny_mountains, tiny_dam, small_mountains, or small_dam (default: tiny_mountains)
    -v, --version <fpga version>     FPGA Implementation Version: base, pipelined, opt, or all (default: all)
    -b, --build-cpu <build cpu bin>  To Build Binary for CPU Implementation: y, or n (default: y)
    -c, --run-cpu <run cpu impl>     To Run the CPU Implementation: y, or n (default: y)
EOF
}

if [[ $# -eq 0 ]]; then
    echo "No flags provided. Displaying help:"
    usage
    exit 0
fi

MODE="synth"
TERRAIN="tiny_mountains"
VERSION="all"
BUILD_BIN="y"
RUN_CPU="y"
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode) MODE=$2; shift ;;
        -t|--terrain) TERRAIN=$2; shift ;;
        -v|--version) VERSION=$2; shift ;;
        -b|--build-cpu) BUILD_BIN=$2; shift ;;
        -c|--run-cpu) RUN_CPU=$2; shift ;;
        *) echo "Error: Unknown flag '$1'"; usage; exit 1 ;;
    esac
    shift
done

case $MODE in
    synth|all) ;;
    *) echo "Error: Invalid execution mode $MODE"; usage; exit 1 ;;
esac
case $TERRAIN in
    tiny_mountains|tiny_dam|small_mountains|small_dam) ;;
    *) echo "Error: Invalid terrain $TERRAIN"; usage; exit 1 ;;
esac
case $VERSION in
    base|pipelined|opt|all) ;;
    *) echo "Error: Invalid FPGA version $VERSION"; usage; exit 1 ;;
esac
case $BUILD_BIN in
    y|n) ;;
    *) echo "Error: Invalid cpu binary flag $BUILD_BIN"; usage; exit 1 ;;
esac
case $RUN_CPU in
    y|n) ;;
    *) echo "Error: Invalid cpu implementation running flag $RUN_CPU"; usage; exit 1 ;;
esac

set -e

CPU_DIR="cpu_impl"
CPU_BINARY="flood"

# CPU binary building
if [[ "$BUILD_BIN" == "y" ]]; then
    echo "Rebuilding CPU flood binary ..."
    cd "$CPU_DIR"
    make clean
    make flood
    cd ..
fi

# CPU job launch
if [[ "$RUN_CPU" == "y" ]]; then
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
if [[ "$VERSION" == "all" || "$VERSION" == "base" ]]; then
    echo "Submitting Non-Pipelined Base FPGA job..."
    JOB=""
    case $MODE in
        synth) JOB="job_base_all.sh" ;;
        all) JOB="job_base_all_with_rtl.sh" ;;
    esac
    FPGA_JOB_ID=$(sbatch --parsable $JOB)
    echo "Non-Pipelined Base FPGA job submitted with ID: ${FPGA_JOB_ID}"
fi

# Base pipelined FPGA job launch
if [[ "$VERSION" == "all" || "$VERSION" == "pipelined" ]]; then
    echo "Submitting Pipelined Base FPGA job..."
    JOB=""
    case $MODE in
        synth) JOB="job_base_all_pipelined.sh" ;;
        all) JOB="job_base_all_pipelined_with_rtl.sh" ;;
    esac
    FPGA_JOB_ID=$(sbatch --parsable $JOB)
    echo "Pipelined Base FPGA job submitted with ID: ${FPGA_JOB_ID}"
fi

# Optimised FPGA job launch
if [[ "$VERSION" == "all" || "$VERSION" == "opt" ]]; then
    echo "Submitting Optimized FPGA job..."
    JOB=""
    case $MODE in
        synth) JOB="job_opt_all.sh" ;;
        all) JOB="job_opt_all_with_rtl.sh" ;;
    esac
    FPGA_JOB_ID=$(sbatch --parsable $JOB)
    echo "Optimized FPGA job submitted with ID: ${FPGA_JOB_ID}"
fi
