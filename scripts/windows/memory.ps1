param(
    [int]$Duration = 60,
    [int]$Intensity = 50
)

function Stress-Memory {
    param(
        [int]$Duration,
        [int]$Intensity
    )
    
    $totalMemMB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB
    $memToUseMB = [Math]::Max(10, [Math]::Floor($totalMemMB * $Intensity / 100))
    
    Write-Host "Starting memory stress test"
    Write-Host "Duration: ${Duration}s, Intensity: ${Intensity}%, Allocating: ${memToUseMB}MB"
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    
    try {
        $memArray = New-Object byte[] ($memToUseMB * 1MB)
        
        for ($i = 0; $i -lt $memArray.Length; $i += 65536) {
            $memArray[$i] = 1
        }
        
        while ((Get-Date) -lt $endTime) {
            $remaining = [Math]::Ceiling(($endTime - (Get-Date)).TotalSeconds)
            Write-Host "Memory stress in progress... ${remaining}s remaining"
            
            for ($i = 0; $i -lt $memArray.Length; $i += 1024) {
                $memArray[$i] = [byte]((Get-Random -Minimum 0 -Maximum 256))
            }
            
            Start-Sleep -Seconds 5
        }
        
        Write-Host "Memory stress test completed"
    }
    finally {
        $memArray = $null
        [GC]::Collect()
    }
}

Stress-Memory -Duration $Duration -Intensity $Intensity
