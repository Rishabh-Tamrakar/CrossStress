#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts/linux"

DURATION=60
INTENSITY=50
TEST_TYPE=""

show_help() {
    cat << EOF
CrossStress - Cross-platform system stress testing tool

Usage: ./crossstress.sh [OPTIONS]

Options:
    -t, --type TYPE       Stress test type: cpu, memory, network, all (default: all)
    -d, --duration SECS   Test duration in seconds (default: 60)
    -i, --intensity PCT   Intensity percentage 1-100 (default: 50)
    -h, --help            Show this help message

Examples:
    ./crossstress.sh
    ./crossstress.sh --type cpu --duration 120 --intensity 75
    ./crossstress.sh -t memory -d 300 -i 80

To stop a running test, press Ctrl+C

EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TEST_TYPE="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -i|--intensity)
            INTENSITY="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$TEST_TYPE" ]; then
    TEST_TYPE="all"
fi

if ! [[ $DURATION =~ ^[0-9]+$ ]] || [ $DURATION -lt 1 ]; then
    echo "Error: Duration must be a positive number"
    exit 1
fi

if ! [[ $INTENSITY =~ ^[0-9]+$ ]] || [ $INTENSITY -lt 1 ] || [ $INTENSITY -gt 100 ]; then
    echo "Error: Intensity must be between 1 and 100"
    exit 1
fi

run_test() {
    local test_name=$1
    local script_path="$SCRIPTS_DIR/$test_name.sh"
    
    if [ ! -f "$script_path" ]; then
        echo "Error: Test script not found: $script_path"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi
    
    bash "$script_path" "$DURATION" "$INTENSITY"
}

trap 'echo ""; echo "Stopping stress test..."; exit 0' INT TERM

case "$TEST_TYPE" in
    cpu)
        run_test "cpu"
        ;;
    memory)
        run_test "memory"
        ;;
    network)
        run_test "network"
        ;;
    all)
        run_test "cpu"
        run_test "memory"
        run_test "network"
        ;;
    *)
        echo "Error: Unknown test type: $TEST_TYPE"
        show_help
        exit 1
        ;;
esac

echo ""
echo "All stress tests completed successfully"
