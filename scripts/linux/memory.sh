#!/bin/bash

stress_memory() {
    local duration=$1
    local intensity=$2
    
    local total_mem=$(free -m 2>/dev/null | awk 'NR==2 {print $2}' || echo 1024)
    local mem_to_use=$((total_mem * intensity / 100))
    
    mem_to_use=$((mem_to_use < 10 ? 10 : mem_to_use))
    
    echo "Starting memory stress test"
    echo "Duration: ${duration}s, Intensity: ${intensity}%, Allocating: ${mem_to_use}MB"
    
    local temp_file="/tmp/crossstress_mem_$$"
    
    dd if=/dev/zero of="$temp_file" bs=1M count="$mem_to_use" 2>/dev/null
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local remaining=$((end_time - $(date +%s)))
        echo "Memory stress in progress... ${remaining}s remaining"
        sleep 5
    done
    
    rm -f "$temp_file"
    echo "Memory stress test completed"
}

stress_memory "$@"
