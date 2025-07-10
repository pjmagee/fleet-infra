#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check ARK server status and player count
.DESCRIPTION
    Connects to the ARK server via kubectl and checks server status, player count, and resource usage
.PARAMETER Namespace
    Kubernetes namespace (default: asa-server)
.PARAMETER ReleaseName
    Helm release name (default: asa-server)
#>
param(
    [string]$Namespace = "asa-server",
    [string]$ReleaseName = "asa-server"
)

Write-Host "=== ARK Server Status ===" -ForegroundColor Green

# Check if pod is running
$podStatus = kubectl get pod "$ReleaseName-0" -n $Namespace -o jsonpath='{.status.phase}' 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pod not found or not accessible" -ForegroundColor Red
    exit 1
}

Write-Host "Pod Status: $podStatus" -ForegroundColor $(if ($podStatus -eq "Running") { "Green" } else { "Yellow" })

if ($podStatus -eq "Running") {
    # Check container status
    $containerReady = kubectl get pod "$ReleaseName-0" -n $Namespace -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
    Write-Host "Container Ready: $containerReady" -ForegroundColor $(if ($containerReady -eq "true") { "Green" } else { "Yellow" })
    
    # Get resource usage
    Write-Host "`n=== Resource Usage ===" -ForegroundColor Green
    kubectl top pod "$ReleaseName-0" -n $Namespace 2>$null
    
    # Check service ports
    Write-Host "`n=== Service Ports ===" -ForegroundColor Green
    kubectl get svc "$ReleaseName-service" -n $Namespace -o wide 2>$null
    
    # Try to get player count via RCON (requires port-forward)
    Write-Host "`n=== RCON Status ===" -ForegroundColor Green
    Write-Host "To check players, run: ./ark-players.ps1" -ForegroundColor Yellow
    
    # Show recent logs
    Write-Host "`n=== Recent Logs (last 10 lines) ===" -ForegroundColor Green
    kubectl logs "$ReleaseName-0" -n $Namespace --tail=10 2>$null
} else {
    Write-Host "`n=== Pod Events ===" -ForegroundColor Yellow
    kubectl describe pod "$ReleaseName-0" -n $Namespace 2>$null | Select-String -Pattern "Events:" -A 10
}
