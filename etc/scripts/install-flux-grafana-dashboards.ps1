flux create kustomization monitoring-config `
  --depends-on=kube-prometheus-stack `
  --interval=1h `
  --prune=true `
  --source=flux-monitoring `
  --path='./manifests/monitoring/monitoring-config' `
  --health-check-timeout=1m `
  --wait


kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80