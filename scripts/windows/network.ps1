param(
    [int]$Duration = 60,
    [int]$Intensity = 50
)

function Stress-Network {
    param(
        [int]$Duration,
        [int]$Intensity
    )
    
    Write-Host "Starting network stress test"
    Write-Host "Duration: ${Duration}s, Intensity: ${Intensity}%"
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $target = "8.8.8.8"
    
    $jobs = @()
    $pingCount = [Math]::Max(1, [Math]::Floor($Intensity / 10))
    
    while ((Get-Date) -lt $endTime) {
        $remaining = [Math]::Ceiling(($endTime - (Get-Date)).TotalSeconds)
        Write-Host "Network stress in progress... ${remaining}s remaining"
        
        for ($i = 0; $i -lt $pingCount; $i++) {
            $job = Start-Job -ScriptBlock {
                $target = $using:target
                try {
                    Test-Connection -ComputerName $target -Count 1 -TimeoutSeconds 1 -ErrorAction SilentlyContinue | Out-Null
                }
                catch {
                    $null
                }
            }
            $jobs += $job
        }
        
        Start-Sleep -Seconds 5
    }
    
    $jobs | ForEach-Object { Stop-Job -Job $_ -Force }
    $jobs | Remove-Job -Force
    
    Write-Host "Network stress test completed"
}

Stress-Network -Duration $Duration -Intensity $Intensity
