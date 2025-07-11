# ARK Server Backup/Restore Guide

## Simplified Backup System

The backup system uses a **single CronJob template** for both scheduled and manual backups:

- **Scheduled backups**: CronJob runs automatically on schedule → `/host-backups/scheduled/`
- **Manual backups**: Created on-demand using `kubectl create job --from=cronjob` → `/host-backups/manual/`

**Benefits**:
- Single source of truth for backup logic
- No template duplication
- Consistent backup behavior between manual and scheduled backups
- Easier maintenance and updates

## Backup Structure (Saves-Only, Ultra Fast)

The backup system now only backs up **ARK save data** - the most critical information:

- **ARK Saves** (`ark-saves.tar.gz`): World data, player data, tribe data, structures
- **Metadata** (`backup-metadata.json`): Backup information and verification data

**NOT backed up**:
- Server binaries (can be re-downloaded)
- SteamCMD files (can be re-downloaded) 
- Config files (managed by Helm/ConfigMap)
- Plugins/mods (can be re-downloaded)

**Benefits**:

- ⚡ **Ultra-fast backups** (typically a few MB, completed in seconds)
- 💾 **Minimal storage** requirements (99%+ smaller than full backups)
- 🚀 **Fast restores** (only essential data)
- 🔄 **Consistent configuration** (config comes from Helm values/1Password)
- 🎯 **Focus on what matters** (your world progress)

## Docker Desktop WSL Path Mapping

Docker Desktop runs in WSL, so the paths are mapped as follows:

- Windows `D:\ark-backups` → WSL `/run/desktop/mnt/host/d/ark-backups`
- Windows `C:\ark-backups` → WSL `/run/desktop/mnt/host/c/ark-backups`

## Manual Backup (Export PVC data to Windows host)

1. **Create backup directory on Windows:**

```powershell
mkdir D:\ark-backups
```

2. **Enable backup in release.yaml:**

```yaml
backup:
  enabled: true
  hostPath: "/run/desktop/mnt/host/d/ark-backups"  # WSL path mapping to D:\ark-backups
  schedule: ""  # Leave empty for manual backups only
  # schedule: "0 3 * * *"  # Set cron expression to enable scheduled backups
```

2. **Apply the configuration:**

```powershell
git add -A
git commit -m "Enable ARK server backup"
git push
flux reconcile source git flux-system
flux reconcile kustomization apps
```

3. **The backup Job will run automatically and create:**

```
D:\ark-backups\
└── manual\
    └── ark-server-backup-20250709-143022\
        ├── ark-saves.tar.gz        # World save data (only essential data)
        ├── backup-metadata.json    # Backup information and file sizes
        └── no-saves-found.txt      # Created if no save data found (new server)
```

## Scheduled Backups (Automatic daily backups)

1. **Enable scheduled backups:**

```yaml
backup:
  enabled: true
  schedule: "0 3 * * *"  # Daily at 3 AM (if empty, no scheduled backups)
  hostPath: "/run/desktop/mnt/host/d/ark-backups"
  retention: 7           # Keep last 7 scheduled backups
```

**Note**: This creates both scheduled backups AND enables manual backups using the same template.

2. **This creates automated backups in:**

```
D:\ark-backups\scheduled\
├── ark-server-20250709-030000\
│   ├── ark-saves.tar.gz        # Save games, player data
│   ├── ark-plugins.tar.gz      # Mods/plugins (if any)
│   ├── config\
│   │   ├── Game.ini            # Game configuration
│   │   └── GameUserSettings.ini # Server settings
│   └── backup-metadata.json    # Backup metadata
├── ark-server-20250710-030000\
└── ark-server-20250711-030000\
```

## Restore from Host Backup

1. **Place your backup in C:\ark-backups\ (maps to WSL path automatically)**

2. **Enable restore in release.yaml:**

```yaml
restore:
  enabled: true
  backupName: "ark-server-backup-20250709-143022"  # Directory name
  hostPath: "/run/desktop/mnt/host/c/ark-backups"  # WSL path mapping to C:\ark-backups
  restoreInstance: true   # Restore saves/configs
  restoreBinaries: false  # Usually not needed
```

3. **Apply and the restore Job will run:**

```powershell
git add -A
git commit -m "Restore ARK server from backup"
git push
flux reconcile source git flux-system
flux reconcile kustomization apps
```

4. **After restore, restart the server:**

```powershell
kubectl delete pod asa-server-0 -n asa-server
# Pod will restart automatically with restored data
```

## Manual Commands

**Start manual backup:**

```powershell
kubectl create job --from=cronjob/asa-server-scheduled-backup asa-server-manual-backup -n asa-server
```

**Monitor backup progress:**

```powershell
kubectl logs -f job/asa-server-manual-backup -n asa-server
```

**Check backup files on host:**

```powershell
dir C:\ark-backups
```

**Copy saves manually (alternative method):**

```powershell
# Export saves only
kubectl cp asa-server-0:/ark/binaries/ShooterGame/Saved ./ark-saves -n asa-server

# Import saves only  
kubectl cp ./ark-saves asa-server-0:/ark/binaries/ShooterGame/Saved -n asa-server
```

## Backup Contents (Current Structure)

The optimized backup now includes only essential data:

- **ark-saves.tar.gz**: World saves from `/ark/binaries/ShooterGame/Saved/`
  - World files (.ark files)
  - Player data
  - Tribe data
  - Structure data
  
- **ark-plugins.tar.gz**: Mods and plugins from `/ark/binaries/ShooterGame/Plugins/` (if any)
  - Custom mods
  - Plugin configurations
  
- **config/**: Server configuration files (only if customized)
  - Game.ini (if contains custom settings)
  - GameUserSettings.ini (if contains custom settings)
  
- **backup-metadata.json**: Backup information and verification
  - Backup timestamp
  - File sizes
  - Server configuration at backup time

**Excluded from backup**:

- Server binaries (Engine/, ShooterGame/Binaries/, etc.)
- SteamCMD files
- Steam compatibility data
- Downloadable content that can be re-acquired
