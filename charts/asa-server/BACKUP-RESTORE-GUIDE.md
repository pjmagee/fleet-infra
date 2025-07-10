# ARK Server Backup/Restore Guide

## Backup Structure (Optimized for Essential Data)

The backup system has been optimized to only backup essential data that cannot be re-downloaded:

- **ARK Saves** (`ark-saves.tar.gz`): World data, player data, tribe data, structures - the most critical data
- **ARK Plugins** (`ark-plugins.tar.gz`): Installed mods and plugins (if any)
- **Config Files** (`config/`): Game.ini and GameUserSettings.ini (if customized)
- **Metadata** (`backup-metadata.json`): Backup information and verification data

**NOT backed up**: Server binaries, SteamCMD, and other downloadable files that can be re-downloaded during server startup.

**Benefits**:
- 90%+ smaller backup files (typically MB instead of GB)
- Faster backup and restore operations
- Reduced storage requirements
- Only essential data is preserved

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
        ├── ark-saves.tar.gz        # Save games, player data (essential)
        ├── ark-plugins.tar.gz      # Mods/plugins (if any)
        ├── config\
        │   ├── Game.ini            # Game configuration
        │   └── GameUserSettings.ini # Server settings
        ├── backup-metadata.json    # Backup metadata
        └── no-plugins.txt          # Created if no plugins to backup
```

## Scheduled Backups (Automatic daily backups)

1. **Enable scheduled backups:**
```yaml
backup:
  enabled: true
  hostPath: "/run/desktop/mnt/host/d/ark-backups"
  schedule:
    enabled: true
    cron: "0 3 * * *"  # Daily at 3 AM
    retention: 7       # Keep last 7 backups
```

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

1. **Place your backup in C:\ark-backups\**

2. **Enable restore in release.yaml:**
```yaml
restore:
  enabled: true
  backupName: "ark-server-backup-20250709-143022"  # Directory name
  hostPath: "C:/ark-backups"
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
