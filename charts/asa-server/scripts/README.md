# ARK Server Management Scripts

This directory contains PowerShell scripts for managing the ARK server deployment. These scripts use `kubectl` and `helm` to interact with the Kubernetes cluster.

## Prerequisites

1. **kubectl** - Kubernetes command-line tool
2. **helm** - Helm package manager (for deployment operations)
3. **rcon-cli** - For RCON commands (optional, download from <https://github.com/itzg/rcon-cli/releases>)

## Available Scripts

### Server Status and Information

- `ark-status.ps1` - Check server status, resource usage, and recent logs
- `ark-players.ps1` - List online players (requires rcon-cli)
- `ark-logs.ps1` - View server logs with various options

### Server Management

- `ark-restart.ps1` - Restart the server pod
- `ark-save.ps1` - Trigger world save (requires rcon-cli)
- `ark-broadcast.ps1` - Broadcast message to all players (requires rcon-cli)

### Backup Operations

- `ark-backup.ps1` - Trigger manual backup

## Usage Examples

```powershell
# Check server status
.\ark-status.ps1

# View recent logs
.\ark-logs.ps1 -Lines 50

# Follow logs in real-time
.\ark-logs.ps1 -Follow

# List online players
.\ark-players.ps1

# Broadcast a message
.\ark-broadcast.ps1 -Message "Server restart in 5 minutes"

# Trigger world save
.\ark-save.ps1

# Restart server
.\ark-restart.ps1

# Create manual backup
.\ark-backup.ps1
```

## RCON Commands

Scripts that use RCON (`ark-players.ps1`, `ark-broadcast.ps1`, `ark-save.ps1`) require:

1. **rcon-cli** installed and available in PATH
2. The server must be running and RCON enabled
3. The admin password must be accessible via Kubernetes secret

If `rcon-cli` is not available, you can alternatively use:

```powershell
# Connect to server pod directly
kubectl exec -it asa-server-0 -n asa-server -- /bin/bash

# Or use port-forward for external RCON clients
kubectl port-forward asa-server-0 27020:27020 -n asa-server
```

## Directory Structure

```
scripts/
├── README.md              # This file
├── ark-status.ps1         # Server status check
├── ark-players.ps1        # List online players
├── ark-logs.ps1           # View server logs
├── ark-restart.ps1        # Restart server
├── ark-save.ps1           # Trigger world save
├── ark-broadcast.ps1      # Broadcast messages
└── ark-backup.ps1         # Manual backup
```

## Security Notes

- Scripts use your current `kubectl` context and credentials
- Admin password is retrieved from Kubernetes secrets
- RCON connections use port-forwarding for security
- No credentials are stored in scripts or logs
