param(
    [ValidateSet('cpu', 'memory', 'network', 'all')]
    [string]$Type = 'all',
    
    [int]$Duration = 60,
    
    [ValidateRange(1, 100)]
    [int]$Intensity = 50
)

function Show-Help {
    @"
CrossStress - Cross-platform system stress testing tool

Usage: .\crossstress.ps1 [OPTIONS]

Options:
    -Type TYPE         Stress test type: cpu, memory, network, all (default: all)
    -Duration SECS     Test duration in seconds (default: 60)
    -Intensity PCT     Intensity percentage 1-100 (default: 50)

Examples:
    .\crossstress.ps1
    .\crossstress.ps1 -Type cpu -Duration 120 -Intensity 75
    .\crossstress.ps1 -Type memory -Duration 300 -Intensity 80

To stop a running test, press Ctrl+C

"@
}

function Invoke-StressTest {
    param(
        [string]$TestType,
        [int]$Duration,
        [int]$Intensity
    )
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "scripts\windows\$TestType.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "Test script not found: $scriptPath"
        return
    }
    
    & $scriptPath -Duration $Duration -Intensity $Intensity
}

$ErrorActionPreference = 'Stop'

if ($Duration -lt 1) {
    Write-Error "Duration must be a positive number"
    exit 1
}

$testTypes = switch ($Type) {
    'all' { @('cpu', 'memory', 'network') }
    default { @($Type) }
}

$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host ""
    Write-Host "Stopping stress test..."
    exit 0
}

foreach ($test in $testTypes) {
    try {
        Invoke-StressTest -TestType $test -Duration $Duration -Intensity $Intensity
    }
    catch {
        Write-Error "Error running $test stress test: $_"
    }
    Write-Host ""
}

Write-Host "All stress tests completed successfully"
