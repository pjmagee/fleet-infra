$DAGGER_ENGINE_POD_NAME=$(kubectl get pod --selector=name=dagger-dagger-helm-engine --namespace=dagger --output=jsonpath='{.items[0].metadata.name}')

Set-Item -Path "Env:_EXPERIMENTAL_DAGGER_RUNNER_HOST" -Value kube-pod://${DAGGER_ENGINE_POD_NAME}?namespace=dagger

$query = @"
{
    container {
        from(address:"alpine") {
            withExec(args: ["uname", "-a"]) { stdout }
        }
    }
}
"@

$query | dagger query