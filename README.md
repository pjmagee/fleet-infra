# GitOps for docker-desktop Kubernetes

This repo is my playground for FluxCD configured docker-desktop K8s.

> Since we're using hostPath for the volumes, make sure to create the directories on the host or the pods will not start. If you're running this setup on another desktop, update all the chart volume mount paths to use the correct hostPath.

```sh
flux bootstrap github --context=docker-desktop --owner=pjmagee --repository=fleet-infra --branch=main --path=./clusters/docker-desktop --personal
```

## 1Password Connect and Operator

```sh
# Create the 1Password namespace
kubectl create namespace 1password
```

```sh
# Create the 1Password credentials secret
kubectl create secret generic op-credentials --namespace 1password \
  --from-file=1password-credentials.json=/path/to/1password-credentials.json
```

```sh
# Create the operator token secret
kubectl create secret generic op-operator-token --namespace 1password \
  --from-literal=token=<your-token-value>
```

## Dagger

If using Dagger in local K8s, you need to set the `_EXPERIMENTAL_DAGGER_ENGINE_HOST` environment variable to the address of the Dagger engine.

See [Dagger Kubernetes Integration](https://docs.dagger.io/integrations/kubernetes/) for more information.