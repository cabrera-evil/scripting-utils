#!/usr/bin/env bash
set -euo pipefail

# ===================================
# GLOBAL CONFIGURATION
# ===================================
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0.0"

# ===================================
# UTILITIES
# ===================================

abort() {
    echo "ERROR: $1" >&2
    exit 1
}

info() {
    echo "INFO: $1"
}

success() {
    echo "SUCCESS: $1"
}

require_sudo() {
    if [[ $EUID -ne 0 ]]; then
        abort "This script must be run as root (use sudo)."
    fi
}

# ===================================
# COMMANDS
# ===================================

cmd_help() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  help         Show this help message
  greet        Print a greeting message
  version      Show script version

Examples:
  $SCRIPT_NAME greet
  $SCRIPT_NAME version
EOF
}

cmd_greet() {
    echo "Hello, $(whoami)! Welcome to $SCRIPT_NAME."
}

cmd_version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
}

# ===================================
# MAIN LOGIC
# ===================================

main() {
    local cmd="${1:-}"

    case "$cmd" in
        help|"")
            cmd_help
            ;;
        greet)
            shift; cmd_greet "$@"
            ;;
        version)
            shift; cmd_version "$@"
            ;;
        *)
            abort "Unknown command: $cmd. Use '$SCRIPT_NAME help' to list available commands."
            ;;
    esac
}

main "$@"
