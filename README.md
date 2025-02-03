# GitOps for docker-desktop Kubernetes

This repo is my playground for FluxCD configured docker-desktop K8s.

> Since we're using hostPath for the volumes, make sure to create the directories on the host or the pods will not start. If you're running this setup on another desktop, update all the chart volume mount paths to use the correct hostPath.

```sh
flux bootstrap github --context=docker-desktop --owner=pjmagee --repository=fleet-infra --branch=main --path=./clusters/docker-desktop --personal
```