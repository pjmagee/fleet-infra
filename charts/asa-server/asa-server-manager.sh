#!/bin/bash
# ASA Server Management Helper Script
# This script provides Zerschranzer-like commands for managing ASA servers via Helm/Kubernetes

set -e

NAMESPACE=${ASA_NAMESPACE:-"asa-server"}
RELEASE_NAME=${ASA_RELEASE:-"asa-server"}
CHART_PATH=${ASA_CHART_PATH:-"charts/asa-server"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo -e "${BLUE}ASA Server Management Tool${NC}"
    echo -e "Kubernetes/Helm wrapper for Zerschranzer-like server management"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Server Management:${NC}"
    echo "  install [name]          Install a new ASA server instance"
    echo "  start [name]           Start server instance"
    echo "  stop [name]            Stop server instance"
    echo "  restart [name]         Restart server instance"
    echo "  delete [name]          Delete server instance"
    echo "  list                   List all server instances"
    echo "  status [name]          Show server status"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  config [name]          Show current server configuration"
    echo "  update [name] [values] Update server configuration"
    echo ""
    echo -e "${YELLOW}Operations:${NC}"
    echo "  logs [name]            Show server logs"
    echo "  rcon [name] [command]  Execute RCON command"
    echo "  backup [name]          Create server backup"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 install ragnarok-server --set server.mapName=Ragnarok_WP"
    echo "  $0 rcon ragnarok-server 'ListPlayers'"
    echo "  $0 backup ragnarok-server"
    echo ""
    echo -e "${YELLOW}Environment Variables:${NC}"
    echo "  ASA_NAMESPACE          Kubernetes namespace (default: asa-server)"
    echo "  ASA_RELEASE            Default release name (default: asa-server)"
    echo "  ASA_CHART_PATH         Path to chart (default: charts/asa-server)"
}

get_pod_name() {
    local name=${1:-$RELEASE_NAME}
    local namespace=${2:-$NAMESPACE}
    kubectl get pods -n "$namespace" -l "app.kubernetes.io/name=asa-server,app.kubernetes.io/instance=$name" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo ""
}

install_server() {
    local name=${1:-$RELEASE_NAME}
    shift
    
    echo -e "${GREEN}Installing ASA server: $name${NC}"
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    helm install "$name" "$CHART_PATH" -n "$NAMESPACE" "$@"
    
    echo -e "${GREEN}✓ Server '$name' installed successfully${NC}"
    echo "Use '$0 status $name' to check deployment status"
}

start_server() {
    local name=${1:-$RELEASE_NAME}
    
    echo -e "${GREEN}Starting server: $name${NC}"
    kubectl scale deployment "$name" -n "$NAMESPACE" --replicas=1
    echo -e "${GREEN}✓ Server '$name' started${NC}"
}

stop_server() {
    local name=${1:-$RELEASE_NAME}
    
    echo -e "${YELLOW}Stopping server: $name${NC}"
    
    # Try graceful shutdown via RCON first
    local pod_name=$(get_pod_name "$name")
    if [[ -n "$pod_name" ]]; then
        echo "Attempting graceful shutdown..."
        kubectl exec -n "$NAMESPACE" "$pod_name" -- /opt/rcon/rcon.py localhost:27020 -p "admin" -c "SaveWorld" 2>/dev/null || true
        sleep 5
    fi
    
    kubectl scale deployment "$name" -n "$NAMESPACE" --replicas=0
    echo -e "${GREEN}✓ Server '$name' stopped${NC}"
}

restart_server() {
    local name=${1:-$RELEASE_NAME}
    
    echo -e "${YELLOW}Restarting server: $name${NC}"
    
    # Graceful restart with announcement
    local pod_name=$(get_pod_name "$name")
    if [[ -n "$pod_name" ]]; then
        echo "Sending restart announcement..."
        kubectl exec -n "$NAMESPACE" "$pod_name" -- /opt/rcon/rcon.py localhost:27020 -p "admin" -c "ServerChat Server restarting in 30 seconds!" 2>/dev/null || true
        sleep 30
        kubectl exec -n "$NAMESPACE" "$pod_name" -- /opt/rcon/rcon.py localhost:27020 -p "admin" -c "SaveWorld" 2>/dev/null || true
        sleep 5
    fi
    
    kubectl rollout restart deployment/"$name" -n "$NAMESPACE"
    echo -e "${GREEN}✓ Server '$name' restarted${NC}"
}

delete_server() {
    local name=${1:-$RELEASE_NAME}
    
    echo -e "${RED}Deleting server: $name${NC}"
    read -p "Are you sure? This will delete all server data! (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        helm uninstall "$name" -n "$NAMESPACE"
        echo -e "${GREEN}✓ Server '$name' deleted${NC}"
    else
        echo "Cancelled"
    fi
}

list_servers() {
    echo -e "${BLUE}ASA Server Instances:${NC}"
    helm list -n "$NAMESPACE" 2>/dev/null || echo "No servers found in namespace '$NAMESPACE'"
    
    echo ""
    echo -e "${BLUE}Pod Status:${NC}"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=asa-server 2>/dev/null || echo "No pods found"
}

show_status() {
    local name=${1:-$RELEASE_NAME}
    
    echo -e "${BLUE}Status for server: $name${NC}"
    
    # Helm status
    echo -e "\n${YELLOW}Helm Release:${NC}"
    helm status "$name" -n "$NAMESPACE" 2>/dev/null || echo "Release not found"
    
    # Pod status
    echo -e "\n${YELLOW}Pod Status:${NC}"
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$name" -o wide 2>/dev/null || echo "No pods found"
    
    # Service status
    echo -e "\n${YELLOW}Service:${NC}"
    kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$name" 2>/dev/null || echo "No services found"
}

show_logs() {
    local name=${1:-$RELEASE_NAME}
    
    echo -e "${BLUE}Logs for server: $name${NC}"
    kubectl logs -n "$NAMESPACE" "deployment/$name" -f --tail=100
}

rcon_command() {
    local name=${1:-$RELEASE_NAME}
    local command="$2"
    
    if [[ -z "$command" ]]; then
        echo -e "${RED}Error: RCON command required${NC}"
        echo "Usage: $0 rcon [server] [command]"
        return 1
    fi
    
    local pod_name=$(get_pod_name "$name")
    if [[ -z "$pod_name" ]]; then
        echo -e "${RED}Error: No running pod found for server '$name'${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Executing RCON command on $name: $command${NC}"
    kubectl exec -n "$NAMESPACE" "$pod_name" -- /opt/rcon/rcon.py localhost:27020 -p "admin" -c "$command"
}

backup_server() {
    local name=${1:-$RELEASE_NAME}
    
    local pod_name=$(get_pod_name "$name")
    if [[ -z "$pod_name" ]]; then
        echo -e "${RED}Error: No running pod found for server '$name'${NC}"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="asa-backup-$name-$timestamp.tar.gz"
    
    echo -e "${BLUE}Creating backup for server: $name${NC}"
    
    # Save world first
    echo "Saving world..."
    kubectl exec -n "$NAMESPACE" "$pod_name" -- /opt/rcon/rcon.py localhost:27020 -p "admin" -c "SaveWorld" 2>/dev/null || true
    sleep 10
    
    # Create backup
    echo "Creating backup archive..."
    kubectl exec -n "$NAMESPACE" "$pod_name" -- tar czf "/tmp/$backup_name" -C /ark/instance/Saved/SavedArks .
    
    # Download backup
    echo "Downloading backup..."
    kubectl cp "$NAMESPACE/$pod_name:/tmp/$backup_name" "./$backup_name"
    
    # Cleanup temp file
    kubectl exec -n "$NAMESPACE" "$pod_name" -- rm -f "/tmp/$backup_name"
    
    echo -e "${GREEN}✓ Backup created: $backup_name${NC}"
}

# Main command dispatcher
case "$1" in
    install)
        shift
        install_server "$@"
        ;;
    start)
        start_server "$2"
        ;;
    stop)
        stop_server "$2"
        ;;
    restart)
        restart_server "$2"
        ;;
    delete)
        delete_server "$2"
        ;;
    list)
        list_servers
        ;;
    status)
        show_status "$2"
        ;;
    config)
        helm get values "$2" -n "$NAMESPACE"
        ;;
    update)
        name="$2"
        shift 2
        helm upgrade "$name" "$CHART_PATH" -n "$NAMESPACE" "$@"
        ;;
    logs)
        show_logs "$2"
        ;;
    rcon)
        rcon_command "$2" "$3"
        ;;
    backup)
        backup_server "$2"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        usage
        exit 1
        ;;
esac
