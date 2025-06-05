#!/usr/bin/env bash

set -euo pipefail

# -------------------------
# Config
# -------------------------
DEFAULT_NAMESPACE="default"
DEFAULT_RELEASE_NAME="deploy-chart"
DEFAULT_HELM_DIR="$(pwd)"
DEFAULT_VALUES_FILE="values.yaml"

# -------------------------
# Helper Functions
# -------------------------
function usage() {
    cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
  install       Install the Helm chart
  upgrade       Upgrade the Helm release
  uninstall     Uninstall the Helm release
  logs          Tail logs from the release pod
  describe      Describe the main pod in the release
  status        Show status of Helm release
  help          Show this help message

Options:
  -n, --namespace     Kubernetes namespace (default: $DEFAULT_NAMESPACE)
  -r, --release       Helm release name (default: $DEFAULT_RELEASE_NAME)
  -d, --dir           Helm chart directory (default: current directory)
  -f, --values        Custom values file path (relative to --dir or absolute)
  -s, --stage         Deployment stage (uses values.<stage>.yaml in --dir)
  -p, --repo          Remote Helm repo URL (optional)
  -m, --repo-name     Helm repo alias (default: "remote")
  -c, --chart         Chart name in remote repo (required with --repo)

Examples:
  $0 install --stage dev
  $0 upgrade --repo https://charts.example.com/ --repo-name myrepo --chart mychart
  $0 logs -r deploy-chart
EOF
}

function parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -n | --namespace)
            NAMESPACE="$2"
            shift
            ;;
        -r | --release)
            RELEASE_NAME="$2"
            shift
            ;;
        -d | --dir)
            HELM_DIR="$2"
            shift
            ;;
        -f | --values)
            VALUES_FILE="$2"
            shift
            ;;
        -s | --stage)
            STAGE="$2"
            shift
            ;;
        -p | --repo)
            HELM_REPO="$2"
            shift
            ;;
        -m | --repo-name)
            HELM_REPO_NAME="$2"
            shift
            ;;
        -c | --chart)
            CHART_NAME="$2"
            shift
            ;;
        install | upgrade | uninstall | logs | describe | status | help)
            COMMAND="$1"
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        esac
        shift
    done

    RELEASE_NAME="${RELEASE_NAME:-$DEFAULT_RELEASE_NAME}"
    HELM_DIR="${HELM_DIR:-$DEFAULT_HELM_DIR}"
    HELM_REPO_NAME="${HELM_REPO_NAME:-remote}"

    if [[ -n "${STAGE:-}" ]]; then
        NAMESPACE="${NAMESPACE:-$DEFAULT_NAMESPACE}-${STAGE}"
        VALUES_FILE="${HELM_DIR}/values.${STAGE}.yaml"
    else
        NAMESPACE="${NAMESPACE:-$DEFAULT_NAMESPACE}"
        VALUES_FILE="${VALUES_FILE:-${HELM_DIR}/${DEFAULT_VALUES_FILE}}"
    fi

    echo -e "\n📦 Deployment Summary"
    echo -e "────────────────────────────────────────"
    printf "📛 Namespace:   %s\n" "$NAMESPACE"
    printf "🚀 Release:     %s\n" "$RELEASE_NAME"
    [[ -n "${HELM_REPO:-}" ]] && printf "🌐 Chart Repo:  %s\n" "$HELM_REPO"
    [[ -n "${HELM_REPO_NAME:-}" ]] && printf "📚 Repo Alias:  %s\n" "$HELM_REPO_NAME"
    [[ -n "${CHART_NAME:-}" ]] && printf "📦 Chart Name:  %s\n" "$CHART_NAME"
    printf "📂 Chart Dir:   %s\n" "$HELM_DIR"
    printf "📄 Values File: %s\n" "$VALUES_FILE"
    printf "🔧 Stage:       %s\n" "${STAGE:-<none>}"
    echo -e "────────────────────────────────────────\n"
}

function get_chart_source() {
    if [[ -n "${HELM_REPO:-}" && -n "${CHART_NAME:-}" ]]; then
        helm repo add "$HELM_REPO_NAME" "$HELM_REPO" >/dev/null
        helm repo update >/dev/null
        echo "$HELM_REPO_NAME/$CHART_NAME"
    else
        echo "$HELM_DIR"
    fi
}

# -------------------------
# Command Implementations
# -------------------------
function helm_install() {
    helm install "$RELEASE_NAME" "$(get_chart_source)" \
        --namespace "$NAMESPACE" \
        --create-namespace \
        -f "$VALUES_FILE" \
        --debug
}

function helm_upgrade() {
    helm upgrade --install "$RELEASE_NAME" "$(get_chart_source)" \
        --namespace "$NAMESPACE" \
        --create-namespace \
        -f "$VALUES_FILE" \
        --debug
}

function helm_uninstall() {
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE"
}

function helm_logs() {
    POD=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath="{.items[0].metadata.name}")
    kubectl logs -f -n "$NAMESPACE" "$POD"
}

function helm_describe() {
    POD=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath="{.items[0].metadata.name}")
    kubectl describe pod "$POD" -n "$NAMESPACE"
}

function helm_status() {
    helm status "$RELEASE_NAME" -n "$NAMESPACE"
}

# -------------------------
# Main Execution
# -------------------------
COMMAND="${1:-help}"
shift || true
parse_args "$@"

case "$COMMAND" in
install) helm_install ;;
upgrade) helm_upgrade ;;
uninstall) helm_uninstall ;;
logs) helm_logs ;;
describe) helm_describe ;;
status) helm_status ;;
help | *) usage ;;
esac
