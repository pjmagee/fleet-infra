# ASA Server Helm Chart

This Helm chart deploys an ARK: Survival Ascended server using the `acekorneya/asa_server` Docker image.

## Features

- **Full ASA Server Support**: Uses the latest ASA server image with Wine/Proton compatibility
- **Persistent Storage**: Configurable persistent volumes for server files, saves, and cluster data
- **AsaApi Support**: Optional AsaApi plugin system for server management and mods
- **Resource Management**: Configurable CPU and memory limits
- **Auto Updates**: Built-in server update management with configurable windows
- **RCON Support**: Remote console access for server management
- **Mod Support**: Support for both active and passive mods
- **Cluster Support**: Multi-server cluster configuration

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- At least 8GB RAM and 50GB storage available
- Docker Desktop (for local development)

## Installation

### Quick Start (Local Development)

```bash
# Add the chart repository (if using from a repository)
helm repo add fleet-infra file://./charts

# Install with default values
helm install my-asa-server fleet-infra/asa-server
```

### Custom Installation

```bash
# Create a values file
cat > my-values.yaml <<EOF
server:
  sessionName: "My Custom ASA Server"
  mapName: "Ragnarok_WP"
  maxPlayers: 20
  adminPassword: "mysecretpassword"
  
resources:
  limits:
    memory: 12Gi
    cpu: 3
  requests:
    memory: 8Gi
    cpu: 2

persistence:
  serverFiles:
    size: 80Gi
EOF

# Install with custom values
helm install my-asa-server fleet-infra/asa-server -f my-values.yaml
```

## Configuration

### Server Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `server.mapName` | Game map to use (ASA format: TheIsland_WP, TheCenter_WP, ScorchedEarth_WP, Aberration_WP, Extinction_WP, Ragnarok_WP) | `TheIsland_WP` |
| `server.sessionName` | Server name | `My ASA Server` |
| `server.password` | Server password (empty = no password) | `""` |
| `server.adminPassword` | Admin password for RCON | `arkadmin123` |
| `server.maxPlayers` | Maximum players | `70` |
| `server.ports.game` | Game port | `7777` |
| `server.ports.rcon` | RCON port | `27020` |

### API Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.enabled` | Enable AsaApi plugin system | `false` |

### Performance Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `performance.cpuOptimization` | Enable CPU optimization | `false` |
| `performance.randomStartupDelay` | Random startup delay | `true` |

### Persistence Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.serverFiles.size` | Server files volume size | `50Gi` |
| `persistence.saved.size` | Saved data volume size | `5Gi` |
| `persistence.cluster.size` | Cluster data volume size | `1Gi` |

### Resource Limits

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.memory` | Memory limit | `16Gi` |
| `resources.limits.cpu` | CPU limit | `2` |
| `resources.requests.memory` | Memory request | `8Gi` |
| `resources.requests.cpu` | CPU request | `1` |

### Password Management

The chart supports both plain text passwords and secure 1Password integration:

#### Plain Text (Development/Testing)

```yaml
server:
  password: "myserverpass"
  adminPassword: "myadminpass"
onePassword:
  enabled: false
```

#### 1Password Integration (Recommended)

```yaml
server:
  password: ""  # Fallback value
  adminPassword: "fallback-admin"  # Fallback value
onePassword:
  enabled: true
  itemPath: "vaults/your-vault-id/items/your-item-id"
  adminPasswordKey: "adminPassword"  # Key name in 1Password item
  serverPasswordKey: "serverPassword"  # Key name in 1Password item
```

When 1Password is enabled, the chart creates a `OnePasswordItem` resource that retrieves passwords from your 1Password vault, ensuring sensitive credentials are not stored in Git.

## Available Maps

The following official maps are currently supported in ARK: Survival Ascended:

- `TheIsland_WP` (default) - The classic ARK experience
- `TheCenter_WP` - Large underground and floating biomes
- `ScorchedEarth_WP` - Desert survival challenge
- `Aberration_WP` - Underground radiation and rock drakes
- `Extinction_WP` - Post-apocalyptic wasteland
- `Ragnarok_WP` - Norse-themed map with ruins, longhouses, and hot springs (Released June 2025)

**Additional Maps Coming Soon:**

- Valguero (August 2025) - Diverse map with underground trenches and dungeons
- Genesis Part 1 (April 2026) - Five different simulated biomes
- Genesis Part 2 (August 2026) - Colony ship in space
- Fjordur (December 2026) - Viking/fantasy map with portals to different realms
- Crystal Isles & Lost Island (2027+) - Currently delayed

## Mods

Configure mods using the `server.modIds` parameter:

```yaml
server:
  modIds: "731604991,889745138,893904615"  # S+, Awesome SpyGlass, Stack Mods
  passiveMods: "123456789"  # Passive mods that don't affect gameplay
```

## Clustering

For multi-server clusters, set a cluster ID:

```yaml
server:
  clusterId: "mycluster"
```

## Monitoring

The chart includes health probes to monitor server status:

- **Startup Probe**: Waits for the server to start (up to 10 minutes)
- **Liveness Probe**: Checks if the server process is running
- **Readiness Probe**: Checks if the server is accepting connections

## Troubleshooting

### Server Won't Start

1. Check pod logs: `kubectl logs -l app.kubernetes.io/name=asa-server`
2. Verify resource limits are sufficient (minimum 8GB RAM)
3. Check persistent volume claims are bound

### Connection Issues

1. Verify ports are accessible: `kubectl get svc`
2. For local development, ensure hostPort is enabled
3. Check firewall rules for game port (default 7777)

### Performance Issues

1. Enable CPU optimization: `performance.cpuOptimization: true`
2. Increase resource limits
3. Monitor resource usage: `kubectl top pods`

## Upgrading

```bash
# Update chart
helm upgrade my-asa-server fleet-infra/asa-server

# Upgrade with new values
helm upgrade my-asa-server fleet-infra/asa-server -f my-values.yaml
```

## Uninstalling

```bash
# Remove the release
helm uninstall my-asa-server

# Optionally remove persistent volumes
kubectl delete pvc -l app.kubernetes.io/name=asa-server
```

## Storage Configuration

The chart supports two storage types:

#### PVC Storage (Default)

Uses Kubernetes PersistentVolumeClaims with the default storage class:

```yaml
persistence:
  enabled: true
  type: "pvc"
  serverFiles:
    size: 50Gi
```

#### HostPath Storage (Direct Host Control)

Maps volumes directly to host filesystem paths (like Docker bind mounts):

```yaml
persistence:
  enabled: true
  type: "hostPath"
  hostPaths:
    serverFiles: "/run/desktop/mnt/host/m/docker/asa-server/server"
    saved: "/run/desktop/mnt/host/m/docker/asa-server/saved"
    cluster: "/run/desktop/mnt/host/m/docker/asa-server/cluster"
    apiLogs: "/run/desktop/mnt/host/m/docker/asa-server/api-logs"
```

**HostPath Benefits:**

- Direct control over where data is stored on the host
- Easy access to files from host system
- Consistent with other services (like changedetection)
- Better for backup/restore operations

**PVC Benefits:**

- Kubernetes-native storage management
- Better for cloud deployments
- Automatic storage provisioning

## Support

For issues related to:

- **Chart**: Create an issue in this repository
- **ASA Server Image**: See [acekorneya/asa_server](https://github.com/Acekorneya/Ark-Survival-Ascended-Server)
- **Game Server**: Check ARK: Survival Ascended official documentation
