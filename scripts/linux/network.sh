#!/bin/bash

stress_network() {
    local duration=$1
    local intensity=$2
    
    echo "Starting network stress test"
    echo "Duration: ${duration}s, Intensity: ${intensity}%"
    
    local pps=$((intensity * 100))
    
    if ! command -v ping &> /dev/null; then
        echo "Error: ping not available for network stress test"
        return 1
    fi
    
    local target="8.8.8.8"
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local remaining=$((end_time - $(date +%s)))
        echo "Network stress in progress... ${remaining}s remaining"
        
        for ((i = 0; i < $((intensity / 10)); i++)); do
            ping -c 1 -W 1 "$target" > /dev/null 2>&1 &
        done
        
        sleep 5
    done
    
    wait 2>/dev/null
    echo "Network stress test completed"
}

stress_network "$@"
