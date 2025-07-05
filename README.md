# GitOps for docker-desktop Kubernetes

This repo is my playground for FluxCD configured docker-desktop K8s.

> Since we're using hostPath for the volumes, make sure to create the directories on the host or the pods will not start. If you're running this setup on another desktop, update all the chart volume mount paths to use the correct hostPath.

## Flux Installation

For installing Flux on your docker-desktop Kubernetes cluster, see the [`install/`](./install/) directory which contains:

- **Automated installation script** (`install-flux.ps1`) - Recommended approach
- **FluxInstance configuration** (`flux-instance.yaml`) - Declarative Flux setup
- **Manual commands** (`manual-commands.md`) - Step-by-step instructions
- **Uninstall script** (`uninstall-flux.ps1`) - Clean removal

### Quick Start

```powershell
cd install
.\install-flux.ps1
kubectl apply -f flux-instance.yaml
```

The modern installation uses the **Flux Operator** which provides better lifecycle management and declarative configuration compared to the legacy `flux bootstrap` approach.

## 1Password Connect and Operator

For setting up 1Password integration, see the [`install/`](./install/) directory which contains:

- **1Password setup guide** (`1password-setup.md`) - Troubleshooting and manual steps
- **Automated setup script** (`setup-1password.ps1`) - Handles credentials validation and secret creation

### Quick Setup

```powershell
cd install
.\setup-1password.ps1
```

### Common Issues

The error `"illegal base64 data at input byte 0"` typically indicates:
- Corrupted 1Password credentials file
- Wrong file encoding (should be UTF-8)
- Invalid JSON format

The setup script automatically detects and fixes these issues.

## Dagger

If using Dagger in local K8s, you need to set the `_EXPERIMENTAL_DAGGER_ENGINE_HOST` environment variable to the address of the Dagger engine.

See [Dagger Kubernetes Integration](https://docs.dagger.io/integrations/kubernetes/) for more information.