#!/bin/bash

usage() {
    cat <<'EOF'
    ###########################
    ###     FLAG SYSTEM     ###
    ###########################
    # --c-sim: Test the result of the C-Simulation
    # --rtl-cosim: Test the result of the RTL Co-simulation
EOF
}

if [[ $# -eq 0]]; then
    echo "No flags provided. Displaying help:"
    usage
    exit 0
fi

TEST_C=false
TEST_RTL=false
while [[]]

set -e

CPU_DIR="cpu_impl"
CHECK_SCRIPT="test_files/check_correctness.py"
CSIM_DIR="FLOOD_HLS_base/solution_FLOOD_HLS_base/csim/build"
RTL_DIR="FLOOD_HLS_base/solution_FLOOD_HLS_base/sim/wrapc_pc"

TESTS=("tiny_mountains" "tiny_dam" "small_mountains" "small_dam")

run_test() {
    local label=$1
    local ref=$2
    local target=$3
    local test_case=$4

    if [[ -f "$ref" && -f "$target" ]]; then
        echo "Running $label: $test_case"
        python3 "$CHECK_SCRIPT" "$ref" "$target"
        echo "$label: $test_case COMPLETED"
    else
        echo -e "SKIPPING $label: $test_case\n Due to missing files:"
        [[ ! -f "$ref" ]]    && echo "  - Missing: $ref"
        [[ ! -f "$target" ]] && echo "  - Missing: $target"
    fi
}

for test_name in "${TESTS[@]}"; do
    echo -e "\n========================================"
    echo "Starting: ${test_name} ..."
    echo "========================================"

    cpu_out="${CPU_DIR}/${test_name}.out"
    csim_out="${CSIM_DIR}/${test_name}.out"
    rtl_out="${RTL_DIR}/${test_name}.out"

    run_test "C-Simulation" "$cpu_out" "$csim_out" "$test_name"
    run_test "RTL Co-simulation" "$cpu_out" "$rtl_out"  "$test_name"
done
