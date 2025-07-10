#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Trigger manual backup of ARK server
.DESCRIPTION
    Creates a manual backup job from the scheduled backup CronJob
.PARAMETER Namespace
    Kubernetes namespace (default: asa-server)
.PARAMETER ReleaseName
    Helm release name (default: asa-server)
#>
param(
    [string]$Namespace = "asa-server",
    [string]$ReleaseName = "asa-server"
)

Write-Host "=== ARK Server Manual Backup ===" -ForegroundColor Green

# Generate unique job name
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jobName = "$ReleaseName-backup-manual-$timestamp"

Write-Host "Creating backup job from CronJob template: $jobName" -ForegroundColor Yellow
Write-Host "Note: This creates a one-time Job using the same logic as scheduled backups" -ForegroundColor Gray

# Create backup job from CronJob template (reuses the same backup logic)
$result = kubectl create job $jobName --from=cronjob/$ReleaseName-scheduled-backup -n $Namespace 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Backup job created successfully!" -ForegroundColor Green
    Write-Host "Job name: $jobName" -ForegroundColor Green
    
    Write-Host "`nMonitoring backup progress..." -ForegroundColor Yellow
    Write-Host "To follow logs, run:" -ForegroundColor Yellow
    Write-Host "  kubectl logs -f job/$jobName -n $Namespace" -ForegroundColor Yellow
    
    Write-Host "`nTo check job status:" -ForegroundColor Yellow
    Write-Host "  kubectl get job $jobName -n $Namespace" -ForegroundColor Yellow
    
    # Wait a moment and show initial status
    Start-Sleep -Seconds 2
    kubectl get job $jobName -n $Namespace 2>$null
    
} else {
    Write-Host "❌ Failed to create backup job:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    
    Write-Host "`nChecking if CronJob exists..." -ForegroundColor Yellow
    kubectl get cronjob "$ReleaseName-scheduled-backup" -n $Namespace 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CronJob not found. Make sure backup.enabled=true and backup.schedule.enabled=true in values.yaml" -ForegroundColor Red
    }
}
