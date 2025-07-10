#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restart ARK server pod
.DESCRIPTION
    Gracefully restarts the ARK server by deleting the pod (StatefulSet will recreate it)
.PARAMETER Namespace
    Kubernetes namespace (default: asa-server)
.PARAMETER ReleaseName
    Helm release name (default: asa-server)
.PARAMETER Force
    Force restart without confirmation
#>
param(
    [string]$Namespace = "asa-server",
    [string]$ReleaseName = "asa-server",
    [switch]$Force
)

Write-Host "=== ARK Server Restart ===" -ForegroundColor Green

if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to restart the ARK server? This will disconnect all players. (y/N)"
    if ($confirmation -ne "y" -and $confirmation -ne "Y") {
        Write-Host "Restart cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Checking current server status..." -ForegroundColor Yellow
kubectl get pod "$ReleaseName-0" -n $Namespace 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pod not found. Server might already be stopped." -ForegroundColor Red
    exit 1
}

Write-Host "Deleting pod to trigger restart..." -ForegroundColor Yellow
kubectl delete pod "$ReleaseName-0" -n $Namespace

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Pod deleted successfully!" -ForegroundColor Green
    Write-Host "The StatefulSet will automatically recreate the pod." -ForegroundColor Green
    
    Write-Host "`nMonitoring pod recreation..." -ForegroundColor Yellow
    $attempts = 0
    $maxAttempts = 30
    
    do {
        Start-Sleep -Seconds 2
        $podStatus = kubectl get pod "$ReleaseName-0" -n $Namespace -o jsonpath='{.status.phase}' 2>$null
        $attempts++
        
        if ($podStatus -eq "Running") {
            Write-Host "✅ Pod is running again!" -ForegroundColor Green
            break
        } elseif ($podStatus -eq "Pending") {
            Write-Host "⏳ Pod is pending..." -ForegroundColor Yellow
        } elseif ($podStatus -eq "ContainerCreating") {
            Write-Host "⏳ Container is being created..." -ForegroundColor Yellow
        } else {
            Write-Host "Pod status: $podStatus" -ForegroundColor Gray
        }
        
    } while ($attempts -lt $maxAttempts)
    
    if ($attempts -ge $maxAttempts) {
        Write-Host "⚠️ Pod restart is taking longer than expected. Check pod status with:" -ForegroundColor Yellow
        Write-Host "  kubectl get pod $ReleaseName-0 -n $Namespace" -ForegroundColor Yellow
        Write-Host "  kubectl describe pod $ReleaseName-0 -n $Namespace" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "❌ Failed to delete pod" -ForegroundColor Red
}
