#!/bin/bash

stress_cpu() {
    local duration=$1
    local intensity=$2
    local num_cores=$(nproc 2>/dev/null || echo 4)
    local workers=$((num_cores * intensity / 100))
    
    workers=$((workers < 1 ? 1 : workers))
    
    echo "Starting CPU stress test"
    echo "Duration: ${duration}s, Intensity: ${intensity}%, Workers: ${workers}"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    for ((i = 0; i < workers; i++)); do
        while [ $(date +%s) -lt $end_time ]; do
            yes > /dev/null &
        done &
    done
    
    while [ $(date +%s) -lt $end_time ]; do
        local remaining=$((end_time - $(date +%s)))
        echo "CPU stress in progress... ${remaining}s remaining"
        sleep 5
    done
    
    pkill -P $$ yes 2>/dev/null
    wait 2>/dev/null
    echo "CPU stress test completed"
}

stress_cpu "$@"
