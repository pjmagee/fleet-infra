# GitOps for docker-desktop Kubernetes

This repo is my playground for FluxCD configured docker-desktop K8s.

`flux bootstrap github --context=docker-desktop --owner=pjmagee --repository=fleet-infra --branch=main --path=./clusters/docker-desktop --personal`