#!/bin/bash

usage() {
    cat << 'EOF'
    ###########################
    ###     FLAG SYSTEM     ###
    ###########################
    -m, --mode <test type>    Execution mode: csim, rtl, or all (default: all)
    -s, --size <problem size>    Dataset size: tiny, small, or all (default: all)

    If no flag was given, all combinations are executed.
EOF
}

MODE="all"
SIZE="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode) MODE=$2; shift ;;
        -s|--size) SIZE=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: Unknown flag '$1'"; usage; exit 1 ;;
    esac
    shift
done

case $MODE in
    all|csim|rtl) ;;
    *) echo "Error: Invalid test mode $MODE"; usage; exit 1 ;;
esac
case $SIZE in
    all|tiny|small) ;;
    *) echo "Error: Invalid problem size $SIZE"; usage; exit 1 ;;
esac

set -e

CPU_DIR="cpu_impl"
CHECK_SCRIPT="test_files/check_correctness.py"

TESTS=("tiny_mountains" "tiny_dam" "small_mountains" "small_dam")

run_test() {
    local label=$1
    local ref=$2
    local target=$3
    local test_case=$4

    if [[ -f "$ref" && -f "$target" ]]; then
        echo "Running $label: $test_case"
        python3 "$CHECK_SCRIPT" "$ref" "$target" || echo "WARNING: Verification failed for $test_case"
        echo "$label: $test_case COMPLETED"
    else
        echo -e "SKIPPING $label: $test_case\n Due to missing files:"
        [[ ! -f "$ref" ]] && echo " - Missing: $ref"
        [[ ! -f "$target" ]] && echo " - Missing: $target"
    fi
}

for test_name in "${TESTS[@]}"; do
    case $test_name in
        tiny*) [[ "$SIZE" == "all" || "$SIZE" == "tiny" ]] || continue ;;
        small*) [[ "$SIZE" == "all" || "$SIZE" == "small" ]] || continue ;;
    esac

    CSIM_DIR="FLOOD_HLS_base_${test_name}/solution_FLOOD_HLS_base_${test_name}/csim/build"
    RTL_DIR="FLOOD_HLS_base_${test_name}/solution_FLOOD_HLS_base_${test_name}/sim/wrapc_pc"

    echo -e "\n========================================"
    echo "Starting: ${test_name} ..."
    echo "========================================"

    cpu_out="${CPU_DIR}/${test_name}.out"
    if [[ "$MODE" == "all" || "$MODE" == "csim" ]]; then
        csim_out="${CSIM_DIR}/${test_name}.out"
        run_test "C-Simulation" "$cpu_out" "$csim_out" "$test_name"
    fi
    if [[ "$MODE" == "all" || "$MODE" == "rtl" ]]; then
        rtl_out="${RTL_DIR}/${test_name}.out"
        run_test "RTL Co-simulation" "$cpu_out" "$rtl_out"  "$test_name"
    fi
done
