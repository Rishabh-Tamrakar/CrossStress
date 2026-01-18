param(
    [int]$Duration = 60,
    [int]$Intensity = 50
)

function Stress-CPU {
    param(
        [int]$Duration,
        [int]$Intensity
    )
    
    $numCores = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    $workers = [Math]::Max(1, [Math]::Floor($numCores * $Intensity / 100))
    
    Write-Host "Starting CPU stress test"
    Write-Host "Duration: ${Duration}s, Intensity: ${Intensity}%, Workers: ${workers}"
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    
    $jobs = @()
    for ($i = 0; $i -lt $workers; $i++) {
        $job = Start-Job -ScriptBlock {
            $endTime = [DateTime]::Parse($using:endTime.ToString('o'))
            while ((Get-Date) -lt $endTime) {
                [Math]::Sqrt([Math]::PI * 1000) | Out-Null
            }
        }
        $jobs += $job
    }
    
    while ((Get-Date) -lt $endTime) {
        $remaining = [Math]::Ceiling(($endTime - (Get-Date)).TotalSeconds)
        Write-Host "CPU stress in progress... ${remaining}s remaining"
        Start-Sleep -Seconds 5
    }
    
    $jobs | ForEach-Object { Stop-Job -Job $_ -Force }
    $jobs | Remove-Job -Force
    
    Write-Host "CPU stress test completed"
}

Stress-CPU -Duration $Duration -Intensity $Intensity
