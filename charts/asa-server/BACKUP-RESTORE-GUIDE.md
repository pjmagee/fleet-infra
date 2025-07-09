# ARK Server Backup/Restore Guide

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
└── ark-server-backup-20250709-143022\
    ├── ark-instance.tar.gz    # Save games, configs, logs
    ├── ark-binaries.tar.gz    # Server files (large!)
    └── backup-info.txt        # Backup metadata
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

## Backup Contents

- **ark-instance.tar.gz**: Instance-specific data
  - Save games (.ark files)
  - Configuration files (Game.ini, GameUserSettings.ini)
  - Server logs
  - Player data

- **ark-binaries.tar.gz**: Server installation (large)
  - ARK server files
  - Installed mods
  - Steam compatibility data
