#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Broadcast a message to all ARK server players
.DESCRIPTION
    Uses kubectl port-forward to connect to ARK server RCON and broadcast a message
.PARAMETER Message
    Message to broadcast to all players
.PARAMETER Namespace
    Kubernetes namespace (default: asa-server)
.PARAMETER ReleaseName
    Helm release name (default: asa-server)
.PARAMETER RconPort
    RCON port (default: 27020)
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [string]$Namespace = "asa-server",
    [string]$ReleaseName = "asa-server",
    [int]$RconPort = 27020
)

Write-Host "=== ARK Server Broadcast ===" -ForegroundColor Green

# Check if rcon-cli is available
$rconCli = Get-Command rcon-cli -ErrorAction SilentlyContinue
if (-not $rconCli) {
    Write-Host "❌ rcon-cli not found. Please install it from: https://github.com/itzg/rcon-cli/releases" -ForegroundColor Red
    exit 1
}

# Get admin password from secret
$adminPassword = kubectl get secret "$ReleaseName-secret" -n $Namespace -o jsonpath='{.data.adminPassword}' 2>$null | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

if (-not $adminPassword) {
    Write-Host "❌ Could not retrieve admin password from secret" -ForegroundColor Red
    exit 1
}

Write-Host "Setting up port-forward..." -ForegroundColor Yellow
$portForwardJob = Start-Job -ScriptBlock {
    param($ReleaseName, $Namespace, $RconPort)
    kubectl port-forward "pod/$ReleaseName-0" "${RconPort}:${RconPort}" -n $Namespace
} -ArgumentList $ReleaseName, $Namespace, $RconPort

# Wait for port-forward to establish
Start-Sleep -Seconds 3

try {
    Write-Host "Broadcasting message: '$Message'" -ForegroundColor Yellow
    
    # Broadcast message
    & rcon-cli --host localhost --port $RconPort --password $adminPassword broadcast $Message
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Message broadcasted successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to broadcast message. Server might be starting up or RCON disabled." -ForegroundColor Red
    }
    
} finally {
    # Cleanup port-forward
    Stop-Job $portForwardJob -ErrorAction SilentlyContinue
    Remove-Job $portForwardJob -ErrorAction SilentlyContinue
    Write-Host "Port-forward terminated" -ForegroundColor Gray
}
