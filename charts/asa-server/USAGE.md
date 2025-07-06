# ASA Server Helm Chart - Usage Guide

This guide demonstrates how to use the ASA Server Helm chart with Zerschranzer/Linux-ASA-Server-Manager in a Kubernetes environment. The chart provides Kubernetes-native equivalents for all Zerschranzer interactive features.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Interactive Management Features](#interactive-management-features)
3. [Server Configuration](#server-configuration)
4. [Instance Management](#instance-management)
5. [Backup & Restore](#backup--restore)
6. [Automated Restarts](#automated-restarts)
7. [RCON Console](#rcon-console)
8. [Clustering](#clustering)
9. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
10. [Migration Guide](#migration-guide)

## Quick Start

1. **Install the chart:**
   ```bash
   helm install my-asa-server ./charts/asa-server
   ```

2. **Check the server status:**
   ```bash
   kubectl get pods -l app.kubernetes.io/name=asa-server
   kubectl logs -l app.kubernetes.io/name=asa-server -f
   ```

3. **Access the server:**
   - Game Port: 7777 (default)
   - Query Port: 7778 (default)
   - RCON Port: 27020 (default)

## Interactive Management Features

This section maps Zerschranzer's interactive menu options to Kubernetes/Helm equivalents:

### 1. Install/Update Base Server
**Zerschranzer:** Interactive menu option "Install/Update Base Server"
**Kubernetes:** Handled automatically by the container image
```bash
# Update to latest server version
helm upgrade my-asa-server ./charts/asa-server --set image.tag=latest
kubectl rollout restart deployment/my-asa-server
```

### 2. List Instances
**Zerschranzer:** "List Instances" menu option
**Kubernetes:** List all ASA server deployments
```bash
# List all ASA server instances
kubectl get deployments -l app.kubernetes.io/name=asa-server
kubectl get pods -l app.kubernetes.io/name=asa-server

# Show detailed instance information
kubectl describe deployment my-asa-server
```

### 3. Create New Instance
**Zerschranzer:** "Create New Instance" menu option
**Kubernetes:** Deploy a new Helm release with unique configuration
```bash
# Create a new instance with custom values
helm install island-pvp ./charts/asa-server -f custom-values.yaml

# Quick create with inline values
helm install scorched-pve ./charts/asa-server \
  --set server.mapName=ScorchedEarth_WP \
  --set server.serverName="Scorched Earth PvE" \
  --set server.saveDir="scorched-pve" \
  --set server.ports.game=7787 \
  --set server.ports.query=7788 \
  --set server.ports.rcon=27021
```

### 4. Manage Instance
**Zerschranzer:** "Manage Instance" submenu with start/stop/restart options
**Kubernetes:** Standard Kubernetes deployment management
```bash
# Start instance (scale up)
kubectl scale deployment my-asa-server --replicas=1

# Stop instance (scale down)
kubectl scale deployment my-asa-server --replicas=0

# Restart instance
kubectl rollout restart deployment/my-asa-server

# Check instance status
kubectl get pods -l app.kubernetes.io/instance=my-asa-server
```

### 5. Show Running Instances
**Zerschranzer:** "Show Running" command
**Kubernetes:** Check running pods and their status
```bash
# Show all running ASA instances
kubectl get pods -l app.kubernetes.io/name=asa-server --field-selector=status.phase=Running

# Detailed status with resource usage
kubectl top pods -l app.kubernetes.io/name=asa-server
```

### 6. Delete Instance
**Zerschranzer:** "Delete Instance" with confirmation
**Kubernetes:** Uninstall Helm release (preserves PVCs by default)
```bash
# Delete instance but keep data (PVCs remain)
helm uninstall my-asa-server

# Delete instance and all data
helm uninstall my-asa-server
kubectl delete pvc -l app.kubernetes.io/instance=my-asa-server
```

## Server Configuration

### Basic Settings (instance_config.ini equivalent)
The chart uses Zerschranzer's configuration format in `values.yaml`:

```yaml
server:
  # Basic server identity
  serverName: "My ASA Server"
  serverPassword: ""  # Leave empty for no password
  serverAdminPassword: "adminpassword"
  maxPlayers: 70
  
  # World settings
  mapName: "TheIsland_WP"  # TheIsland_WP, ScorchedEarth_WP, etc.
  saveDir: "asa-server"    # Must be unique per instance
  
  # Network configuration
  ports:
    game: 7777      # Main game port
    query: 7778     # Query port (typically game + 1)
    rcon: 27020     # RCON administration port
  
  # Content and features
  modIDs: ""  # Comma-separated mod IDs: "123456,789012"
  clusterID: ""  # For cross-server transfers
  customStartParameters: "-NoBattlEye -crossplay -NoHangDetection"
```

### Advanced Configuration (GameUserSettings.ini & Game.ini)
**Zerschranzer:** Manual editing of config files
**Kubernetes:** ConfigMap-based configuration
```bash
# Edit game settings
kubectl edit configmap my-asa-server-config

# Apply configuration changes
kubectl rollout restart deployment/my-asa-server
```

Example advanced settings:
```yaml
gameSettings:
  GameUserSettings:
    ServerSettings:
      TamingSpeedMultiplier: 3.0
      XPMultiplier: 2.0
      HarvestAmountMultiplier: 2.0
      PlayerLevelEngramPointsMultiplier: 2.0
      
  Game:
    # Advanced engram and spawn configurations
    OverrideNPCNetworkStasisRangeScale: 1.0
```

## Instance Management

### Multi-Instance Setup
**Zerschranzer:** Multiple instance directories
**Kubernetes:** Multiple Helm releases with unique configurations

```bash
# Create multiple instances for a cluster
helm install island-server ./charts/asa-server \
  --values island-values.yaml

helm install scorched-server ./charts/asa-server \
  --values scorched-values.yaml

helm install aberration-server ./charts/asa-server \
  --values aberration-values.yaml
```

Example cluster configuration files:
```yaml
# island-values.yaml
server:
  serverName: "Island Cluster"
  mapName: "TheIsland_WP"
  saveDir: "island-cluster"
  clusterID: "MyCluster"
  ports: { game: 7777, query: 7778, rcon: 27020 }

# scorched-values.yaml  
server:
  serverName: "Scorched Cluster"
  mapName: "ScorchedEarth_WP"
  saveDir: "scorched-cluster"
  clusterID: "MyCluster"
  ports: { game: 7787, query: 7788, rcon: 27021 }
```

## Backup & Restore

### Manual Backup
**Zerschranzer:** "Backup a World from Instance" menu option
**Kubernetes:** PVC backup using kubectl
```bash
# Create backup
kubectl exec deployment/my-asa-server -- tar -czf /tmp/world-backup.tar.gz -C /ark/instance .
kubectl cp my-asa-server-pod:/tmp/world-backup.tar.gz ./asa-backup-$(date +%Y%m%d-%H%M).tar.gz

# List available backups
ls -la asa-backup-*.tar.gz
```

### Automated Backup with CronJob
**Zerschranzer:** Manual backup scheduling
**Kubernetes:** CronJob resource for automated backups
```yaml
# backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: asa-server-backup
spec:
  schedule: "0 4 * * *"  # Daily at 4 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: alpine:latest
            command:
            - /bin/sh
            - -c
            - |
              apk add --no-cache tar gzip
              tar -czf /backups/asa-backup-$(date +%Y%m%d-%H%M).tar.gz -C /ark/instance .
              # Keep only last 7 days
              find /backups -name "asa-backup-*.tar.gz" -mtime +7 -delete
            volumeMounts:
            - name: instance-data
              mountPath: /ark/instance
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: instance-data
            persistentVolumeClaim:
              claimName: my-asa-server-instance
          - name: backup-storage
            persistentVolumeClaim:
              claimName: asa-backups
          restartPolicy: OnFailure
```

### Restore from Backup
**Zerschranzer:** "Load Backup to Instance" menu option
**Kubernetes:** Manual restore process
```bash
# Stop the server
kubectl scale deployment my-asa-server --replicas=0

# Restore from backup
kubectl cp ./asa-backup-20240115-0400.tar.gz my-asa-server-pod:/tmp/restore.tar.gz
kubectl exec deployment/my-asa-server -- bash -c "cd /ark/instance && rm -rf * && tar -xzf /tmp/restore.tar.gz"

# Start the server
kubectl scale deployment my-asa-server --replicas=1
```

## Automated Restarts

### Scheduled Restart with CronJob
**Zerschranzer:** "Configure Restart Manager" with announcements
**Kubernetes:** CronJob with RCON announcements
```yaml
# restart-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: asa-server-restart
spec:
  schedule: "0 4 * * *"  # Daily at 4 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: restart-manager
            image: python:3.9-alpine
            command:
            - /bin/sh
            - -c
            - |
              pip install python-valve
              # 30 minute warning
              python /scripts/rcon.py my-asa-server:27020 -p "$ADMIN_PASSWORD" -c "broadcast Server restart in 30 minutes!"
              sleep 1800
              # 10 minute warning  
              python /scripts/rcon.py my-asa-server:27020 -p "$ADMIN_PASSWORD" -c "broadcast Server restart in 10 minutes!"
              sleep 600
              # Save and restart
              python /scripts/rcon.py my-asa-server:27020 -p "$ADMIN_PASSWORD" -c "SaveWorld"
              sleep 30
              kubectl rollout restart deployment/my-asa-server
            env:
            - name: ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: my-asa-server-secret
                  key: adminPassword
            volumeMounts:
            - name: rcon-scripts
              mountPath: /scripts
          volumes:
          - name: rcon-scripts
            configMap:
              name: rcon-scripts
          restartPolicy: OnFailure
```

### Manual Restart with Grace Period
**Zerschranzer:** Graceful restart with warnings
**Kubernetes:** Manual restart with RCON announcements
```bash
# Announce restart
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "broadcast Server restart in 5 minutes!"
sleep 300

# Save and restart
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "SaveWorld"
kubectl rollout restart deployment/my-asa-server
```

## RCON Console

### Interactive RCON Session
**Zerschranzer:** `rcon.py` interactive console
**Kubernetes:** kubectl exec with RCON tools
```bash
# Enter interactive RCON session
kubectl exec -it deployment/my-asa-server -- bash

# Inside container, use RCON (if rcon tools are available)
rcon-cli -a 127.0.0.1:27020 -p adminpassword

# Or use direct commands
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "ListPlayers"
```

### External RCON Access
**Zerschranzer:** Remote RCON connection
**Kubernetes:** Expose RCON port and use external client
```yaml
# Enable external RCON access
service:
  type: LoadBalancer  # or NodePort
  rcon:
    enabled: true
    port: 27020
```

```bash
# Connect with external RCON client
rcon-cli -a <external-ip>:27020 -p adminpassword
```

### Common RCON Commands
```bash
# Server management
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "SaveWorld"
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "ListPlayers"
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "broadcast Welcome to our server!"

# Player management
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "KickPlayer PlayerName"
kubectl exec deployment/my-asa-server -- rcon-cli -a 127.0.0.1:27020 -p adminpassword "BanPlayer PlayerName"
```

## Clustering

### Cross-Server Transfer Setup
**Zerschranzer:** Shared ClusterID configuration
**Kubernetes:** Multiple instances with shared cluster storage
```yaml
# Cluster storage for character/item transfers
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: asa-cluster-shared
spec:
  accessModes:
  - ReadWriteMany  # Requires RWX storage class
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-client  # Example RWX storage class
```

```yaml
# Each server in cluster needs shared volume and same clusterID
server:
  clusterID: "MyCluster"
  
persistence:
  cluster:
    enabled: true
    existingClaim: asa-cluster-shared
```

## Monitoring & Troubleshooting

### Server Health Monitoring
**Zerschranzer:** Manual log checking
**Kubernetes:** Built-in health checks and monitoring
```bash
# Check pod health
kubectl get pods -l app.kubernetes.io/name=asa-server
kubectl describe pod -l app.kubernetes.io/name=asa-server

# Monitor resource usage
kubectl top pods -l app.kubernetes.io/name=asa-server

# Stream logs
kubectl logs -f deployment/my-asa-server
```

### Common Issues & Solutions

1. **Server won't start (Zerschranzer equivalent: Check dependencies)**
   ```bash
   # Check resource limits
   kubectl describe pod -l app.kubernetes.io/name=asa-server
   
   # Verify PVC binding
   kubectl get pvc
   
   # Check configuration
   kubectl get configmap my-asa-server-config -o yaml
   ```

2. **High memory usage (Zerschranzer equivalent: Monitor system resources)**
   ```bash
   # Check current usage
   kubectl top pods
   
   # Increase memory limits
   helm upgrade my-asa-server ./charts/asa-server \
     --set resources.limits.memory=32Gi
   ```

3. **Port conflicts (Zerschranzer equivalent: Unique ports per instance)**
   ```bash
   # Check service endpoints
   kubectl get svc,endpoints
   
   # Verify port configuration
   kubectl get svc my-asa-server -o yaml
   ```

### Debug Commands
```bash
# Full pod description
kubectl describe pod -l app.kubernetes.io/name=asa-server

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Exec into container for debugging
kubectl exec -it deployment/my-asa-server -- bash

# Check mounted volumes
kubectl exec deployment/my-asa-server -- df -h

# Test network connectivity
kubectl exec deployment/my-asa-server -- netstat -tlnp
```

## Migration Guide

### From Zerschranzer Native to Kubernetes
1. **Export configuration:** Save your `instance_config.ini` settings
2. **Backup worlds:** Use Zerschranzer's backup feature before migration
3. **Create values.yaml:** Map your settings to the Helm chart format
4. **Deploy chart:** `helm install` with your configuration
5. **Restore worlds:** Copy world saves to the new PVC

### From Legacy acekorneya/asa_server Chart
1. **Backup existing data** before migration
2. **Update values.yaml** to remove acekorneya-specific settings:
   - Remove `api.*` configuration
   - Remove `performance.*` settings
   - Remove `update.*` settings
3. **Convert to Zerschranzer format:**
   ```yaml
   # Old acekorneya format
   config:
     serverName: "My Server"
   
   # New Zerschranzer format
   server:
     serverName: "My Server"
   ```
4. **Test deployment** with a backup first

## Helper Script

The chart includes a helper script (`asa-server-manager.sh`) that provides Zerschranzer-like commands:

```bash
# Make script executable
chmod +x ./asa-server-manager.sh

# Usage examples
./asa-server-manager.sh list                    # List instances
./asa-server-manager.sh start my-asa-server     # Start instance
./asa-server-manager.sh stop my-asa-server      # Stop instance
./asa-server-manager.sh restart my-asa-server   # Restart instance
./asa-server-manager.sh backup my-asa-server    # Create backup
./asa-server-manager.sh logs my-asa-server      # View logs
./asa-server-manager.sh rcon my-asa-server "SaveWorld"  # Send RCON command
```

## Support

For issues specific to:
- **Zerschranzer functionality:** [Zerschranzer GitHub Repository](https://github.com/Zerschranzer/Linux-ASA-Server-Manager)
- **ARK server configuration:** [ASA Dedicated Server Documentation](https://ark.wiki.gg/wiki/Dedicated_server_setup)
- **Kubernetes/Helm:** [Kubernetes Documentation](https://kubernetes.io/docs/) | [Helm Documentation](https://helm.sh/docs/)
- **Chart issues:** Open an issue in the chart's repository

This guide provides Kubernetes-native equivalents for all Zerschranzer interactive features while maintaining the same functionality and flexibility.
kubectl scale deployment asa-server -n asa-server --replicas=0

# Restart a server
kubectl rollout restart deployment/asa-server -n asa-server

# Start/Stop all servers
kubectl get deployments -A -l app.kubernetes.io/name=asa-server -o name | \
  xargs -I {} kubectl scale {} --replicas=1

kubectl get deployments -A -l app.kubernetes.io/name=asa-server -o name | \
  xargs -I {} kubectl scale {} --replicas=0
```

### Checking Running Instances

```bash
# Show all running ASA servers
kubectl get pods -A -l app.kubernetes.io/name=asa-server

# Get detailed status
kubectl get pods -A -l app.kubernetes.io/name=asa-server -o wide

# Check resource usage
kubectl top pods -A -l app.kubernetes.io/name=asa-server
```

### Deleting Instances

```bash
# Delete a specific server instance
helm uninstall asa-server -n asa-server

# Delete namespace too (removes persistent data!)
kubectl delete namespace asa-server
```

---

## Configuration

### Updating Server Configuration

Equivalent to editing `instance_config.ini` in Zerschranzer:

```bash
# Update server settings
helm upgrade asa-server charts/asa-server -n asa-server \
  --set server.serverName="Updated Server Name" \
  --set server.maxPlayers=50 \
  --set server.customStartParameters="-NoBattlEye -crossplay -ForceAllowCaveFlyers"

# Update with values file
helm upgrade asa-server charts/asa-server -n asa-server -f my-server-config.yaml
```

### Maps and Mods

```bash
# Change map
helm upgrade asa-server charts/asa-server -n asa-server \
  --set server.mapName="ScorchedEarth_WP"

# Add mods
helm upgrade asa-server charts/asa-server -n asa-server \
  --set server.modIDs="731604991,889745138,123456789"

# Update both map and mods
helm upgrade asa-server charts/asa-server -n asa-server \
  --set server.mapName="Extinction_WP" \
  --set server.modIDs="731604991"
```

### Advanced Configuration (Game.ini / GameUserSettings.ini)

Create a custom values file for advanced settings:

```yaml
# custom-config.yaml
server:
  serverName: "Advanced PvE Server"
  mapName: "TheCenter_WP"
  
# Override ConfigMap with custom Game.ini and GameUserSettings.ini
configOverride:
  gameIni: |
    [/script/shootergame.shootergamemode]
    bPvEDisableFriendlyFire=true
    bDisableStructureDecayPvE=true
    
  gameUserSettingsIni: |
    [ServerSettings]
    XPMultiplier=2.0
    TamingSpeedMultiplier=3.0
    HarvestAmountMultiplier=2.0
    ShowMapPlayerLocation=true
    AllowFlyerCarryPvE=true
```

```bash
helm upgrade asa-server charts/asa-server -n asa-server -f custom-config.yaml
```

### Clustering

Set up server clusters for character transfers:

```bash
# Server 1 (Island)
helm install cluster-island charts/asa-server -n cluster-island --create-namespace \
  --set server.mapName="TheIsland_WP" \
  --set server.clusterID="MyCluster" \
  --set server.ports.game=7777

# Server 2 (Ragnarok) 
helm install cluster-ragnarok charts/asa-server -n cluster-ragnarok --create-namespace \
  --set server.mapName="Ragnarok_WP" \
  --set server.clusterID="MyCluster" \
  --set server.ports.game=7787 \
  --set server.ports.query=7788 \
  --set server.ports.rcon=27030
```

---

## Server Operations

### Graceful Restart with Announcements

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n asa-server -l app.kubernetes.io/name=asa-server -o jsonpath='{.items[0].metadata.name}')

# Send RCON announcements before restart
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "ServerChat Server restart in 10 minutes!"
sleep 300  # 5 minutes
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "ServerChat Server restart in 5 minutes!"
sleep 240  # 4 minutes  
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "ServerChat Server restarting in 1 minute!"
sleep 60   # 1 minute

# Save world and restart
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "SaveWorld"
kubectl rollout restart deployment/asa-server -n asa-server
```

### Scheduled Automated Restarts

Create a CronJob for automated restarts:

```yaml
# restart-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: asa-server-restart
  namespace: asa-server
spec:
  schedule: "0 4 * * *"  # Daily at 4 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: restart-manager
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              # Announce restart
              kubectl exec deployment/asa-server -- /opt/rcon/rcon.py localhost:27020 -p "$ADMIN_PASSWORD" -c "ServerChat Scheduled restart in 10 minutes!"
              sleep 600
              kubectl exec deployment/asa-server -- /opt/rcon/rcon.py localhost:27020 -p "$ADMIN_PASSWORD" -c "ServerChat Restarting now!"
              kubectl exec deployment/asa-server -- /opt/rcon/rcon.py localhost:27020 -p "$ADMIN_PASSWORD" -c "SaveWorld"
              sleep 30
              kubectl rollout restart deployment/asa-server
            env:
            - name: ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: asa-server-secrets
                  key: adminPassword
          restartPolicy: OnFailure
          serviceAccountName: asa-server-restart-sa
```

---

## RCON Console

### Interactive RCON

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n asa-server -l app.kubernetes.io/name=asa-server -o jsonpath='{.items[0].metadata.name}')

# Interactive RCON session
kubectl exec -it -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "YOUR_ADMIN_PASSWORD"

# Single RCON command
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "YOUR_ADMIN_PASSWORD" -c "ListPlayers"
```

### Common RCON Commands

```bash
# Save world
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "SaveWorld"

# Broadcast message
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "ServerChat Welcome to our server!"

# List players
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "ListPlayers"

# Server info
kubectl exec -n asa-server $POD_NAME -- /opt/rcon/rcon.py localhost:27020 -p "ADMIN_PASSWORD" -c "GetServerVersion"
```

---

## Backups & Restores

### Manual Backups

```bash
# Create backup of saves
kubectl exec -n asa-server $POD_NAME -- tar czf /tmp/backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /ark/instance/Saved/SavedArks .

# Copy backup to local machine
kubectl cp asa-server/$POD_NAME:/tmp/backup-20250106-120000.tar.gz ./backup-20250106-120000.tar.gz
```

### Automated Backups with CronJob

```yaml
# backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: asa-server-backup
  namespace: asa-server
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: alpine:latest
            command:
            - /bin/sh
            - -c
            - |
              apk add --no-cache tar gzip
              TIMESTAMP=$(date +%Y%m%d-%H%M%S)
              tar czf /backups/asa-backup-$TIMESTAMP.tar.gz -C /ark/instance/Saved/SavedArks .
              # Keep only last 7 days of backups
              find /backups -name "asa-backup-*.tar.gz" -mtime +7 -delete
            volumeMounts:
            - name: ark-instance
              mountPath: /ark/instance
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: ark-instance
            persistentVolumeClaim:
              claimName: asa-server-instance
          - name: backup-storage
            persistentVolumeClaim:
              claimName: asa-server-backups
          restartPolicy: OnFailure
```

### Restore from Backup

```bash
# Stop server
kubectl scale deployment asa-server -n asa-server --replicas=0

# Copy backup to pod (assuming using hostPath storage)
kubectl run restore-pod --image=alpine --rm -it --overrides='
{
  "spec": {
    "volumes": [
      {
        "name": "ark-instance",
        "hostPath": {"path": "/run/desktop/mnt/host/m/docker/asa-server/instance"}
      }
    ],
    "containers": [
      {
        "name": "restore",
        "image": "alpine",
        "command": ["/bin/sh"],
        "stdin": true,
        "tty": true,
        "volumeMounts": [
          {"name": "ark-instance", "mountPath": "/ark/instance"}
        ]
      }
    ]
  }
}' -- /bin/sh

# Inside the pod:
# cd /ark/instance/Saved/SavedArks
# rm -rf *
# tar xzf /path/to/backup.tar.gz
# exit

# Restart server
kubectl scale deployment asa-server -n asa-server --replicas=1
```

---

## Monitoring & Logs

### View Server Logs

```bash
# Real-time logs
kubectl logs -n asa-server deployment/asa-server -f

# Recent logs
kubectl logs -n asa-server deployment/asa-server --tail=100

# Logs from specific time
kubectl logs -n asa-server deployment/asa-server --since=1h
```

### Server Performance Monitoring

```bash
# Resource usage
kubectl top pods -n asa-server

# Detailed pod info
kubectl describe pod -n asa-server -l app.kubernetes.io/name=asa-server

# Events
kubectl get events -n asa-server --sort-by='.firstTimestamp'
```

### Health Checks

```bash
# Check pod health
kubectl get pods -n asa-server -o wide

# Check readiness/liveness probe status
kubectl describe pod -n asa-server -l app.kubernetes.io/name=asa-server | grep -A 10 "Conditions:"
```

---

## Troubleshooting

### Common Issues

#### Server Won't Start
```bash
# Check pod events
kubectl describe pod -n asa-server -l app.kubernetes.io/name=asa-server

# Check logs for errors
kubectl logs -n asa-server deployment/asa-server

# Check resource limits
kubectl describe pod -n asa-server -l app.kubernetes.io/name=asa-server | grep -A 5 "Limits:"
```

#### Permission Issues
```bash
# Check security context
kubectl get pod -n asa-server -l app.kubernetes.io/name=asa-server -o yaml | grep -A 5 securityContext

# Fix permissions (for hostPath storage)
kubectl run debug-pod --image=alpine --rm -it --privileged --overrides='
{
  "spec": {
    "volumes": [
      {
        "name": "ark-instance", 
        "hostPath": {"path": "/run/desktop/mnt/host/m/docker/asa-server/instance"}
      }
    ],
    "containers": [
      {
        "name": "debug",
        "image": "alpine", 
        "command": ["/bin/sh"],
        "stdin": true,
        "tty": true,
        "securityContext": {"privileged": true},
        "volumeMounts": [
          {"name": "ark-instance", "mountPath": "/ark/instance"}
        ]
      }
    ]
  }
}' -- /bin/sh

# Inside pod: chown -R 7777:7777 /ark/instance
```

#### Memory Issues
```bash
# Check if container is being OOM killed
kubectl describe pod -n asa-server -l app.kubernetes.io/name=asa-server | grep -i "oom"

# Increase memory limits
helm upgrade asa-server charts/asa-server -n asa-server \
  --set resources.limits.memory=16Gi \
  --set resources.requests.memory=12Gi
```

#### Network Issues
```bash
# Check service
kubectl get svc -n asa-server -o wide

# Test connectivity
kubectl run test-pod --image=busybox --rm -it -- nslookup asa-server.asa-server.svc.cluster.local

# Check hostPort conflicts
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].ports[*].hostPort}{"\n"}{end}' | grep 7777
```

---

This usage guide provides Kubernetes-native equivalents to all the Zerschranzer management features, allowing you to manage your ARK servers effectively using Helm and kubectl commands instead of their interactive shell scripts.
