# CrossStress Architecture and Implementation Guide

This document explains the internal logic and implementation of all CrossStress scripts.

## Entry Points

### crossstress.sh (Linux)
Detects OS type and routes to appropriate scripts. Parses command-line arguments for test type, duration, and intensity. Validates inputs and executes the selected stress test with proper error handling.

### crossstress.ps1 (Windows)
PowerShell equivalent that detects Windows OS and processes parameters. Handles script execution policy and invokes selected stress test modules with configuration.

---

## Linux Scripts

### scripts/linux/cpu.sh

**Logic:**

1. Calculates number of CPU cores using `nproc`
2. Determines worker count: `cores * (intensity / 100)`
3. Launches background processes running SHA256 hash calculations in infinite loops
4. Each worker executes: `echo "test" | sha256sum` repeatedly to consume CPU cycles
5. Monitors elapsed time every 5 seconds, prints progress
6. On timeout or Ctrl+C, kills all background workers using `kill`

**How it works:**

Hashing is CPU-intensive, deterministic, and requires no special tools. Multiple workers saturate all cores proportionally to intensity level. The script spawns background jobs that compute hashes continuously, each consuming approximately one CPU core worth of work. As workers complete their infinite loops (they don't), the parent process waits for the duration to expire, then terminates all children.

**Key implementation details:**

- Uses `nproc` to detect core count (falls back to 4 if unavailable)
- Worker calculation ensures partial intensity works smoothly (50% on 4 cores = 2 workers)
- Background processes are PIDs tracked and killed via `pkill -P $$`
- Progress reporting every 5 seconds shows remaining time

---

### scripts/linux/memory.sh

**Logic:**

1. Gets total system RAM in MB using `grep MemTotal /proc/meminfo`
2. Calculates allocation target: `total_ram * (intensity / 100)`
3. Creates temporary file for memory allocation
4. Uses `dd` to write zeros repeatedly, filling memory/swap space
5. Tracks bytes written every 5 seconds
6. Cleans up temporary file on completion

**How it works:**

Writing sequential zeros to disk forces system to allocate and manage memory. The intensity percentage determines how much total system RAM gets consumed. When the file exceeds available RAM, the OS swaps to disk, creating I/O pressure as well. This provides realistic memory stress while being safe—the temporary file can be deleted immediately without data loss.

**Key implementation details:**

- Temporary file created in /tmp with unique name `$(/tmp/crossstress_mem_$$)` to avoid collisions
- `dd if=/dev/zero of=file bs=1M count=N` efficiently allocates N megabytes
- File is only held for the test duration, then deleted
- Minimum 10MB allocation prevents undersized tests

---

### scripts/linux/network.sh

**Logic:**

1. Selects target: Google DNS (8.8.8.8) or localhost as fallback
2. Calculates concurrent ping count: `intensity / 10` (rounded up)
3. Launches background ping processes in parallel
4. Each ping runs: `ping -c 1 -W 1 target` in a loop
5. Counts successful pings every 5 seconds for progress display
6. Terminates all pings on exit

**How it works:**

Parallel ping requests generate network traffic and I/O load. Higher intensity means more concurrent ICMP echo requests hitting the network stack. Each ping takes ~1 second, so at 100% intensity with 10+ concurrent requests, the network interface experiences continuous traffic. Unlike network stress tools that flood raw packets, ping uses standard ICMP which is safe for production systems (respects rate limiting, doesn't trigger DDoS detection).

**Key implementation details:**

- Target 8.8.8.8 (Google DNS) chosen because it's reliable, public, and accepts pings
- `-W 1` timeout prevents hanging on unreachable hosts
- Parallel jobs run in background, controlled via `wait` and `pkill`
- Progress counts successful pings to show actual network activity

---

## Windows Scripts

### scripts/windows/cpu.ps1

**Logic:**

1. Gets CPU core count: `(Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors`
2. Calculates worker threads: `cores * (intensity / 100)`
3. Creates PowerShell jobs (runspaces)
4. Each thread runs infinite SHA256 hashing: `[Math]::Sqrt([Math]::PI * 1000)`
5. Tracks elapsed time, displays progress every 5 seconds
6. Gracefully stops all jobs on completion

**How it works:**

PowerShell jobs create true parallel threads via .NET runspaces. Each job runs mathematical calculations (square root of PI) repeatedly, which forces CPU to perform floating-point operations. While not as intensive as hashing, this approach is portable and doesn't depend on external tools. The loop runs until the timeout expires.

**Key implementation details:**

- Uses `Start-Job` to create background runspaces
- Each runspace receives the end time via `$using:` scope binding
- Runspaces run until time expires, then parent stops them
- Math operations prevent compiler optimization by using non-constant values
- All jobs are forcefully stopped and removed on exit

---

### scripts/windows/memory.ps1

**Logic:**

1. Gets available RAM: `(Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory`
2. Calculates target allocation in MB: `total_mb * (intensity / 100)`
3. Creates a single large byte array in memory
4. Initializes array pages by writing sequential values every 64KB
5. Continuously modifies random array elements for the test duration
6. Arrays are garbage collected when script exits

**How it works:**

Instantiating a large byte array forces .NET runtime to allocate heap memory. By holding this array for the entire test duration and continuously accessing it, the garbage collector cannot free the memory. The memory remains allocated and in use, simulating a memory leak or high-memory application. Random writes ensure memory pages are actually accessed (not just allocated), putting pressure on the memory subsystem.

**Key implementation details:**

- Single allocation approach is simpler and more reliable than iterative allocation
- Array initialization loop touches every 65KB to ensure OS commits the pages
- Random writes every 5 seconds throughout the test keep memory active
- Finally block ensures array is released even if script is interrupted
- GC.Collect() forces immediate garbage collection to free memory

---

### scripts/windows/network.ps1

**Logic:**

1. Sets target to Google's DNS (8.8.8.8)
2. Calculates concurrent ping jobs: `intensity / 10` (minimum 1)
3. Uses `Test-NetConnection` cmdlet in parallel jobs
4. Each job sends ICMP echo request with 1-second timeout
5. Counts successful connections every 5 seconds
6. Waits for all jobs to complete before cleanup

**How it works:**

PowerShell jobs provide true parallelism. Test-NetConnection is the PowerShell equivalent of ping—it sends ICMP echo requests and reports success/failure. By launching multiple concurrent jobs and waiting between iterations, we generate sustained network load. Each job attempts to contact the target, and results are accumulated to show progress.

**Key implementation details:**

- `Test-NetConnection -ComputerName target -Count 1 -TimeoutSeconds 1` sends one ping with timeout
- Multiple jobs launched in succession throughout the test duration
- Job results piped to null to prevent output clutter
- All jobs tracked in array and cleaned up at end
- Try/catch prevents errors from stopping the test

---

## Shared Implementation Patterns

### Duration Control
All scripts implement elapsed time tracking:
- Start time captured at beginning
- End time calculated as: `start_time + duration_seconds`
- Main loop condition checks: `current_time < end_time`
- Exit gracefully when duration expires

### Intensity Mapping

**CPU:** Worker process count
- 25% intensity on 4-core system = 1 worker
- 50% intensity on 4-core system = 2 workers
- 100% intensity on 4-core system = 4 workers

**Memory:** Percentage of total system RAM
- 25% intensity = 25% of system RAM allocated
- 50% intensity = 50% of system RAM allocated
- 100% intensity = 100% of system RAM allocated (or maximum available)

**Network:** Concurrent request multiplier
- 10% intensity = 1 concurrent request
- 50% intensity = 5 concurrent requests
- 100% intensity = 10+ concurrent requests

### Progress Display
All scripts print status every 5 seconds with:
- Test type and current operation
- Remaining time countdown
- Resource metrics (workers active, MB allocated, requests sent)

### Graceful Shutdown
Signal handling for clean termination:

**Linux:** `trap 'cleanup_action' INT TERM` catches Ctrl+C
**Windows:** Register-EngineEvent handles PSExitingEvent

---

## Design Principles

### Production Ready
- No placeholder code or pseudo implementations
- Actual resource consumption, not simulated
- Real system impact, measurable results
- Handles edge cases (no cores detected, memory full, network unreachable)

### Minimal Dependencies
- Linux: Uses only standard utilities (bash, nproc, dd, ping, grep)
- Windows: Uses only built-in PowerShell and .NET Framework

### Safety
- Temporary files are cleaned up automatically
- Background processes are properly terminated
- Memory is released after test
- Network traffic respects standard ICMP protocol (no raw packet injection)
- Intensity limits prevent accidental system damage

### Cross-Platform Consistency
- Same command-line interface on both OS
- Same duration and intensity semantics
- Same output format and progress reporting
- Equivalent stress levels across platforms

---

## Performance Characteristics

### CPU Stress
- Linear scaling with core count and intensity
- Uses ~100% CPU per worker thread
- Minimal memory consumption per worker

### Memory Stress
- Allocates continuous contiguous block (not fragmented)
- Forces OS page table management
- Can trigger swap usage if allocation > available RAM
- Memory remains locked, cannot be paged out

### Network Stress
- ICMP echo traffic (ping protocol)
- Respects network layer rate limiting
- No firewall rule violations (standard ICMP)
- Suitable for production environments

---

## Troubleshooting Guide

### CPU Test Not Using Expected CPU
- Check for thermal throttling in BIOS
- Disable power saving settings
- Ensure no other processes consuming CPU
- Verify nproc detects correct core count

### Memory Test Fails to Allocate
- System may not have sufficient free memory
- Close other applications
- Reduce intensity percentage
- Check available disk space for swap

### Network Test Shows No Activity
- Verify internet connectivity
- Check if ping/ICMP is blocked by firewall
- Try pinging localhost as fallback
- Ensure DNS is working on Linux

---

## Future Enhancement Opportunities

- Disk I/O stress testing
- GPU stress testing (CUDA/compute)
- Context switching stress (thread pool saturation)
- Lock contention stress (mutex/semaphore testing)
- Cache coherency stress (NUMA-aware testing)

