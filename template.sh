#!/usr/bin/env bash
set -euo pipefail

# ===================================
# GLOBAL CONFIGURATION
# ===================================
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0.0"
DEBUG=false
SILENT=false

# ===================================
# UTILITIES
# ===================================

abort() {
    echo "ERROR: $1" >&2
    exit 1
}

info() {
    if [[ "$SILENT" == false ]]; then
        echo "INFO: $1"
    fi
}

debug() {
    if [[ "$DEBUG" == true ]]; then
        echo "DEBUG: $1"
    fi
}

success() {
    if [[ "$SILENT" == false ]]; then
        echo "SUCCESS: $1"
    fi
}

require_sudo() {
    if [[ $EUID -ne 0 ]]; then
        abort "This script must be run as root (use sudo)."
    fi
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || abort "'$1' is not installed or not in PATH."
}

require_flag_value() {
    local value="$1"
    local name="$2"

    if [[ -z "$value" ]]; then
        abort "Missing value for required flag: --$name"
    fi
}

# ===================================
# COMMANDS
# ===================================

cmd_help() {
    cat <<EOF
Usage:
  $SCRIPT_NAME <command> [options]

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
