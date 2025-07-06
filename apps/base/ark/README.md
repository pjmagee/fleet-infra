# ARK Survival Evolved - Ragnarok Server

This configuration deploys a single ARK Survival Evolved Ragnarok server using the [SickHub ARK Server Charts](https://github.com/SickHub/ark-server-charts).

## Overview

The setup includes:

- **HelmRepository**: ARK charts from SickHub
- **HelmRelease**: Single Ragnarok server
- **Persistence**: Persistent volumes for game files, cluster data, and save files
- **Networking**: HostPort configuration for local development

## Server Configuration

### Ragnarok Server

- **Purpose**: Single ARK server running the Ragnarok map
- **Map**: Ragnarok (free DLC map with diverse biomes)
- **Ports**:
  - Game: 7777/UDP
  - Query: 27015/UDP  
  - RCON: 32330/TCP
- **Status**: Starts automatically with `updateOnStart: true`
- **Settings**: Enhanced rates for faster gameplay

## Persistence Volumes

The chart creates 3 types of persistent volumes:

1. **Game Files** (`docker-desktop-ark-game`): 50GB
   - Contains ARK installation and mods
   - Shared server files
   - Largest volume requirement

2. **Cluster Data** (`docker-desktop-ark-cluster`): 1GB
   - Cluster configuration (for future expansion)
   - Character/item transfer support

3. **Save Data** (`docker-desktop-ark-ragnarok`): 5GB
   - World save files for Ragnarok
   - Server-specific configurations

## Mods Included

Popular mods are pre-configured:

- **Structures Plus (S+)**: Enhanced building
- **Awesome SpyGlass**: Creature inspection tool
- **Stack Mods**: Increased stack sizes

## Resource Requirements

- **CPU**: 1.5-2 cores
- **Memory**: 6-8GB RAM
- **Storage**: ~56GB total (50GB game + 5GB saves + 1GB cluster)

## Deployment Steps

1. **Infrastructure First**: Flux deploys the HelmRepository
2. **App Deployment**: Flux deploys the HelmRelease
3. **Initial Setup**: Server downloads ARK (~25GB) and mods
4. **Ready to Play**: Connect once download completes

## Management Commands

### Server Control

```bash
# Check server status
kubectl get pods -n ark

# Stop server
kubectl scale deployment docker-desktop-ark-ragnarok -n ark --replicas=0

# Start server
kubectl scale deployment docker-desktop-ark-ragnarok -n ark --replicas=1

# Restart server
kubectl rollout restart deployment/docker-desktop-ark-ragnarok -n ark
```

### Check Status

```bash
# Check pods
kubectl get pods -n ark

# Check persistent volumes
kubectl get pv | grep ark

# Check deployments
kubectl get deployments -n ark
```

### Access Logs

```bash
# Server logs
kubectl logs -n ark deployment/docker-desktop-ark-ragnarok

# Follow logs
kubectl logs -n ark deployment/docker-desktop-ark-ragnarok -f
```

### RCON Access

```bash
# Port forward RCON
kubectl port-forward -n ark deployment/docker-desktop-ark-ragnarok 32330:32330

# Use RCON client with password: arkadmin123
```

## Connecting to Server

### Direct Connection (Recommended)

- **Ragnarok**: `localhost:7777` or `127.0.0.1:7777`

### Steam Server Browser

The server should appear in the Steam server browser when running.

## Customization

### Adding More Servers

Edit `apps/base/ark/release.yaml` and add new server entries:

```yaml
servers:
  ragnarok:
    # ... existing config
  
  newmap:
    map: ScorchedEarth_P  # or CrystalIsles, Aberration_P, etc.
    ports:
      gameudp: 7778
      queryudp: 27016
      rcon: 32331
    # ... other settings
```

### Modifying Settings

Game settings can be customized in the `customConfigMap` sections:

- `GameIni`: Core game mechanics
- `GameUserSettingsIni`: Server settings and multipliers

### Resource Adjustment

For better performance, adjust resources in the `resources` section.

## Troubleshooting

### Common Issues

1. **Long Startup Time**: ARK takes 5-15 minutes to start initially
2. **Storage Space**: Ensure at least 60GB free space
3. **Memory Usage**: ARK server uses 6-8GB RAM
4. **Port Conflicts**: Ensure ports 7777, 27015, 32330 are free

### Useful Commands

```bash
# Check ARK server status
kubectl describe pod -n ark -l app.kubernetes.io/name=ark-cluster

# Check persistent volume claims
kubectl get pvc -n ark

# Force restart server
kubectl rollout restart deployment/docker-desktop-ark-ragnarok -n ark
```

## Configuration Files

- `infrastructure/docker-desktop/ark/`: HelmRepository configuration
- `apps/base/ark/`: HelmRelease and application configuration
- Applied via Flux GitOps from the main kustomization files

## Notes

- Server starts with `replicas: 1` by default
- `updateOnStart: true` ensures game and mods are updated
- Cluster name is `docker-desktop-ark` for local development
- Default RCON password is `arkadmin123` (change for production)
- Ragnarok map includes diverse biomes and excellent for single-player/small groups
