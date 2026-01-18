![CrossStress Logo](CrossStress.png)

CrossStress is a lightweight, production-ready system stress testing tool for validating system stability and capacity. It stresses CPU, memory, and network resources with configurable intensity and duration across Linux and Windows systems.

## What is CrossStress

CrossStress provides a simple command-line interface to stress test system components. Whether you need to validate hardware performance, test system stability under load, or simulate peak usage conditions, CrossStress delivers predictable, controllable stress with minimal dependencies.

The tool automatically detects your operating system and uses native scripting for maximum compatibility and zero external runtime dependencies.

## Supported Systems

CrossStress runs on the following platforms:

Linux systems with apt package manager (Debian, Ubuntu, Linux Mint, Kali)

Linux systems with yum package manager (Red Hat, CentOS, Fedora, Rocky)

Windows 7 and later (PowerShell 5.0 or later)

## Safety Considerations

Before running stress tests, understand these important points:

Stress testing places significant load on system hardware. Monitor system temperature and load during testing. Disable any power saving settings that might interfere with testing.

Start with conservative settings (low duration, moderate intensity) and gradually increase as needed. Avoid running multiple stress tests simultaneously unless you are testing multi-system scenarios.

Stress testing may consume significant system resources and can impact other running applications. Do not run stress tests on production systems handling live traffic without careful planning and monitoring.

The tool attempts to handle interrupts gracefully. If a test hangs, use Ctrl+C to stop it or kill the process. Resources are freed automatically after the process terminates.

## Installation

Clone the repository to your system:

\\\
git clone https://github.com/Rishabh-Tamrakar/CrossStress.git
cd CrossStress
\\\

Make the scripts executable:

\\\
chmod +x *.sh scripts/linux/*.sh
\\\

On Windows, no additional setup is required. Open PowerShell and run the script directly.

## Usage

### Linux

Run the main stress testing script:

\\\
./crossstress.sh [OPTIONS]
\\\

Options:

--type TYPE (or -t TYPE) - Test type: cpu, memory, network, or all. Default is all.

--duration SECS (or -d SECS) - Duration of each stress test in seconds. Default is 60.

--intensity PCT (or -i PCT) - Intensity from 1 to 100 percent. Default is 50.

--help (or -h) - Display help information.

Examples:

\\\
./crossstress.sh
\\\

Runs all stress tests (CPU, memory, network) for 60 seconds at 50% intensity.

\\\
./crossstress.sh --type cpu --duration 300 --intensity 80
\\\

Runs CPU stress test for 300 seconds at 80% intensity.

\\\
./crossstress.sh -t memory -d 120 -i 100
\\\

Runs memory stress test for 120 seconds at maximum intensity.

\\\
./crossstress.sh --type network -d 60 -i 25
\\\

Runs network stress test for 60 seconds at 25% intensity.

### Windows

Run the main stress testing script using PowerShell:

\\\
.\crossstress.ps1 [OPTIONS]
\\\

Options:

-Type TYPE - Test type: cpu, memory, network, or all. Default is all.

-Duration SECS - Duration of each stress test in seconds. Default is 60.

-Intensity PCT - Intensity from 1 to 100 percent. Default is 50.

Examples:

\\\
.\crossstress.ps1
\\\

Runs all stress tests (CPU, memory, network) for 60 seconds at 50% intensity.

\\\
.\crossstress.ps1 -Type cpu -Duration 300 -Intensity 80
\\\

Runs CPU stress test for 300 seconds at 80% intensity.

\\\
.\crossstress.ps1 -Type memory -Duration 120 -Intensity 100
\\\

Runs memory stress test for 120 seconds at maximum intensity.

\\\
.\crossstress.ps1 -Type network -Duration 60 -Intensity 25
\\\

Runs network stress test for 60 seconds at 25% intensity.

## Stress Test Types

CPU stress test continuously performs mathematical calculations on available CPU cores. It scales the number of worker threads based on system CPU count and specified intensity.

Memory stress test allocates and exercises RAM. It allocates memory based on system RAM and specified intensity, then repeatedly reads and writes to exercise the memory subsystem.

Network stress test generates network traffic through repeated ping requests to a public DNS server. Intensity controls the number of concurrent requests.

## Stopping Tests

Press Ctrl+C at any time to stop a running stress test. The script catches the interrupt signal and terminates gracefully, cleaning up any background processes.

Alternatively, you can open a new terminal window and use operating system tools to terminate the process:

Linux:

\\\
pkill -f crossstress.sh
\\\

Windows:

\\\
Stop-Process -Name "powershell" -IncludeChildProcesses
\\\

Or use Task Manager to terminate the PowerShell process.

## Performance Baseline

To establish a baseline before stress testing:

On Linux, run \	op\ or \htop\ in another terminal to monitor resource usage during testing.

On Windows, open Task Manager and monitor CPU, Memory, and Network tabs while testing.

## Common Scenarios

Testing hardware limits: Start with high intensity (80-100) and moderate duration (120-300 seconds) to determine system breaking points.

Capacity planning: Run medium intensity (50-70) for extended duration (600+ seconds) to understand sustained load behavior.

Validation before deployment: Run moderate intensity (50%) for extended duration (1800+ seconds) to ensure stability under load.

## Troubleshooting

If tests fail to start, ensure you have appropriate permissions. Linux tests may require elevated privileges for some operations.

If memory stress test fails to allocate requested memory, the system may not have sufficient free memory. Either reduce intensity or close other applications.

If network stress test reports errors, the system may not have internet connectivity. Network tests work best with stable internet connection.

If CPU stress test uses less than expected CPU, the system may have thermal throttling enabled. Disable power saving and thermal throttling in BIOS if you need full stress testing.

## Architecture and Implementation

For developers interested in understanding how CrossStress works internally, refer to ARCHITECTURE.md. This document covers:

Script logic and implementation for CPU, memory, and network stress tests

How intensity and duration parameters are mapped to resource consumption

Design principles ensuring production readiness and safety

Performance characteristics of each stress test type

Troubleshooting guide for common issues

## License

CrossStress is released under the MIT License. See LICENSE file for details.

## Contributing

To contribute to CrossStress, submit pull requests or issues on the project repository. All contributions should maintain production-ready code quality and include appropriate testing.
