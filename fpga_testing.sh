#!/bin/bash

set -e

CPU_DIR="cpu_impl"
CHECK_SCRIPT="test_files/check_correctness.py"
CSIM_DIR="FLOOD_HLS_base/solution_FLOOD_HLS_base/csim/build"
RTL_DIR="FLOOD_HLS_base/solution_FLOOD_HLS_base/sim/wrapc_pc"

declare -A TESTS

TESTS["tiny_mountains"]="\
${CPU_DIR}/tiny_mountains.out|\
${CSIM_DIR}/tiny_mountains.out|\
${RTL_DIR}/tiny_mountains.out"

TESTS["tiny_dam"]="\
${CPU_DIR}/tiny_dam.out|\
${CSIM_DIR}/tiny_dam.out|\
${RTL_DIR}/tiny_dam.out"

TESTS["small_mountains"]="\
${CPU_DIR}/small_mountains.out|\
${CSIM_DIR}/small_mountains.out|\
${RTL_DIR}/small_mountains.out"

TESTS["small_dam"]="\
${CPU_DIR}/small_dam.out|\
${CSIM_DIR}/small_dam.out|\
${RTL_DIR}/small_dam.out"

for test_name in "${!TESTS[@]}"; do

    echo ""
    echo "========================================"
    echo "Starting: ${test_name} ..."
    echo "========================================"

    IFS='|' read -r cpu_out csim_out rtl_out <<< "${TESTS[$test_name]}"

    missing_files=""
    [[ -f "$cpu_out" ]]  || missing_files+="  - CPU output: $cpu_out\n"
    [[ -f "$csim_out" ]] || missing_files+="  - CSIM output: $csim_out\n"
    [[ -f "$rtl_out" ]]  || missing_files+="  - RTL output: $rtl_out\n"
    if [[ -n "$missing_files" ]]; then
        echo -e "SKIPPING: ${test_name} due to missing files:\n${missing_files}"
        continue
    fi

    echo "Running C-Simulation: ${test_name}"
    python3 "$CHECK_SCRIPT" "$cpu_out" "$csim_out"
    echo "C-Simulation: ${test_name} DONE"

    echo "Running RTL Co-simulation: ${test_name}"
    python3 "$CHECK_SCRIPT" "$cpu_out" "$rtl_out"
    echo "RTL Co-simulation: ${test_name} DONE"
done
