#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View ARK server logs
.DESCRIPTION
    Shows logs from the ARK server pod with various options
.PARAMETER Namespace
    Kubernetes namespace (default: asa-server)
.PARAMETER ReleaseName
    Helm release name (default: asa-server)
.PARAMETER Follow
    Follow logs in real-time
.PARAMETER Lines
    Number of lines to show (default: 100)
.PARAMETER Since
    Show logs since duration (e.g., "1h", "30m", "5s")
#>
param(
    [string]$Namespace = "asa-server",
    [string]$ReleaseName = "asa-server",
    [switch]$Follow,
    [int]$Lines = 100,
    [string]$Since = ""
)

Write-Host "=== ARK Server Logs ===" -ForegroundColor Green

# Build kubectl command
$kubectlArgs = @("logs", "$ReleaseName-0", "-n", $Namespace, "--tail", $Lines.ToString())

if ($Follow) {
    $kubectlArgs += "--follow"
}

if ($Since) {
    $kubectlArgs += "--since", $Since
}

Write-Host "Running: kubectl $($kubectlArgs -join ' ')" -ForegroundColor Gray

# Execute kubectl logs
& kubectl @kubectlArgs
