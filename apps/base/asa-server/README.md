# ARK: Survival Ascended Server

This directory contains the deployment configuration for ARK: Survival Ascended (ASA) server using a custom Helm chart and the `acekorneya/asa_server` Docker image.

## Overview

This deployment replaces the previous ARK: Survival Evolved setup with a modern ASA server that supports:

- **ARK: Survival Ascended** - The latest version of ARK
- **Docker-based deployment** using `acekorneya/asa_server`
- **AsaApi support** for server management and mods
- **Persistent storage** for server files, saves, and cluster data
- **RCON access** for remote server management
- **Mod support** for enhanced gameplay
- **Auto-updates** with configurable maintenance windows

## Configuration

The server is configured in `release.yaml` with the following key settings:

### Server Details

- **Map**: Ragnarok_WP (Norse-themed map with ruins, longhouses, and hot springs)
- **Session Name**: "Ragnarok Adventures"
- **Max Players**: 4 (suitable for local development)
- **Admin Password**: `arkadmin123` (change for production)
- **Ports**: 7777 (game), 27020 (RCON)

### Performance Optimizations

- **CPU Optimization**: Enabled for Docker Desktop
- **Memory**: 8Gi request, 12Gi limit
- **Storage**: 60Gi for server files, 8Gi for saves

### Mods Included

- **731604991**: Structures Plus (S+) - Enhanced building
- **889745138**: Awesome SpyGlass! - Advanced creature information

## Storage Volumes

The deployment creates several persistent volumes:

1. **Server Files** (60Gi): ARK server installation and mods
2. **Saved Data** (8Gi): Player saves, world data, configurations
3. **Cluster Data** (2Gi): For multi-server clusters (future use)

## Access

### Game Connection

- **Host**: `localhost` (or Docker Desktop VM IP)
- **Port**: `7777`
- **In-game**: Add server using IP `127.0.0.1:7777`

### RCON Management

- **Host**: `localhost`
- **Port**: `27020`
- **Password**: `arkadmin123`

Example RCON commands:

```bash
# Install RCON client
brew install rcon  # macOS
# or download from https://github.com/gorcon/rcon-cli

# Connect to server
rcon -a localhost:27020 -p arkadmin123

# Common commands
SaveWorld              # Save the game
ListPlayers           # Show connected players
Broadcast "Hello!"    # Send message to all players
SetPlayerPos 0 0 0    # Teleport admin to coordinates
```

## Deployment Status

Check deployment status:

```bash
# Check if pods are running
kubectl get pods -n asa-server

# Check persistent volumes
kubectl get pvc -n asa-server

# View server logs
kubectl logs -n asa-server -l app.kubernetes.io/name=asa-server -f

# Check service status
kubectl get svc -n asa-server
```

## Troubleshooting

### Server Not Starting

1. **Check logs**: `kubectl logs -n asa-server -l app.kubernetes.io/name=asa-server`
2. **Verify resources**: Ensure enough CPU/memory available
3. **Storage issues**: Check if PVCs are bound: `kubectl get pvc -n asa-server`
4. **Image pull**: Verify Docker image can be pulled

### Connection Issues

1. **Port forwarding**: `kubectl port-forward -n asa-server svc/asa-server 7777:7777`
2. **Check service**: `kubectl get svc -n asa-server asa-server`
3. **Host network**: Verify hostPort is working in Docker Desktop

### Performance Issues

1. **Resource monitoring**: `kubectl top pods -n asa-server`
2. **Increase limits** in `release.yaml` if needed
3. **Check Docker Desktop resource allocation**

### First-Time Setup Issues

- **Initial download**: Server files (40-50GB) download on first start
- **Startup time**: Can take 5-10 minutes for first launch
- **Mod downloads**: Additional time if mods are enabled

## Maintenance

### Server Updates

The server automatically checks for updates weekly between 2-4 AM with 15-minute player warnings.

### Manual Update

```bash
# Restart the pod to trigger update check
kubectl rollout restart deployment -n asa-server asa-server
```

### Configuration Changes

1. Edit `release.yaml`
2. Commit and push changes
3. FluxCD will automatically apply updates

### Mod Management

To add/remove mods:

1. Update `server.modIds` in `release.yaml`
2. Restart the deployment
3. Server will download new mods on startup

## Migration from ARK SE

This deployment completely replaces the previous ARK: Survival Evolved setup:

### What Changed

- **Game Version**: ARK SE → ARK: Survival Ascended
- **Docker Image**: `steamcmd/steamcmd` → `acekorneya/asa_server`
- **Helm Chart**: External SickHub chart → Custom local chart
- **Architecture**: Wine/Proton compatibility layer for Windows server

### Data Migration

- **No automatic migration** - ASA saves are incompatible with SE
- **Fresh start required** - New characters and world
- **Configuration preserved** - Server settings and mod preferences

### Removed Components

- ARK SE HelmRepository (SickHub)
- ARK SE namespace and resources
- Legacy ARK SE configuration files

## Future Enhancements

Potential improvements for this deployment:

1. **Multi-Server Clusters**: Deploy multiple maps with shared character transfer
2. **Backup System**: Automated world save backups to external storage
3. **Metrics Monitoring**: Prometheus metrics for server performance
4. **Web Dashboard**: Optional web UI for server management
5. **Discord Integration**: Server status and player notifications

## Support

For issues with:

- **Helm Chart**: Check this repository's issues
- **ASA Server Image**: See [acekorneya/asa_server](https://github.com/Acekorneya/Ark-Survival-Ascended-Server)
- **Game Issues**: ARK: Survival Ascended official support
- **Docker Desktop**: Docker Desktop documentation

## Links

- [ASA Server Docker Image](https://hub.docker.com/r/acekorneya/asa_server)
- [ASA Server Management Script](https://github.com/Acekorneya/Ark-Survival-Ascended-Server)
- [ARK: Survival Ascended Official](https://store.steampowered.com/app/2399830/ARK_Survival_Ascended/)
- [Structures Plus Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=731604991)
- [Awesome SpyGlass Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=889745138)
