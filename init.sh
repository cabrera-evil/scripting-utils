#!/usr/bin/env bash
set -euo pipefail

# ===================================
# METADATA
# ===================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"

# ===================================
# COLORS
# ===================================
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
	readonly RED=$'\033[0;31m'
	readonly GREEN=$'\033[0;32m'
	readonly YELLOW=$'\033[0;33m'
	readonly BLUE=$'\033[0;34m'
	readonly MAGENTA=$'\033[0;35m'
	readonly BOLD=$'\033[1m'
	readonly DIM=$'\033[2m'
	readonly NC=$'\033[0m'
else
	readonly RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' BOLD='' DIM='' NC=''
fi

# ===================================
# CONFIGURATION
# ===================================
DEBUG=false
QUIET=false
BASE_DIR="$(pwd)"

# ===================================
# LOGGING FUNCTIONS
# ===================================
log() { [[ "$QUIET" != true ]] && printf "${BLUE}▶${NC} %s\n" "$*" || true; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$*" >&2; }
error() { printf "${RED}✗${NC} %s\n" "$*" >&2; }
success() { [[ "$QUIET" != true ]] && printf "${GREEN}✓${NC} %s\n" "$*" || true; }
debug() { [[ "$DEBUG" == true ]] && printf "${MAGENTA}⚈${NC} DEBUG: %s\n" "$*" >&2 || true; }
die() {
	error "$*"
	exit 1
}

# ===================================
# UTILITIES
# ===================================
require_sudo() {
	if [[ $EUID -ne 0 ]]; then
		die "This script must be run as root (use sudo)."
	fi
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "'$1' is not installed or not in PATH."
}

require_flag_value() {
	local value="$1"
	local name="$2"
	if [[ -z "$value" ]]; then
		die "Missing value for required flag: --$name"
	fi
}

# ===================================
# COMMANDS
# ===================================
cmd_help() {
	cat <<EOF
${BOLD}${SCRIPT_NAME}${NC} - A script to create symbolic links for executable scripts in the current directory and its subdirectories.

${BOLD}USAGE:${NC}
  $SCRIPT_NAME [OPTIONS] COMMAND

${BOLD}COMMANDS:${NC}
  ${GREEN}link${NC}           Create symbolic links for all executable scripts in the current directory and subdirectories
  ${GREEN}help${NC}           Show this help message
  ${GREEN}version${NC}        Show script version

${BOLD}OPTIONS:${NC}
  ${YELLOW}-q, --quiet${NC}                  Minimize output
  ${YELLOW}-d, --debug${NC}                  Enable debug output
  ${YELLOW}-h, --help${NC}                   Show help
  ${YELLOW}-v, --version${NC}                Show version

${BOLD}EXAMPLES:${NC}
  # Create symbolic links for all executable scripts
  $SCRIPT_NAME link 
EOF
}

cmd_create_links() {
	log "Creating symbolic links for scripts in the '$BASE_DIR' directory and its subdirectories..."

	# Function to create symbolic links for all scripts in the directory
	create_symlinks() {
		local dir=$1
		for file in "$dir"/*; do
			if [ -f "$file" ] && [ -x "$file" ]; then
				sudo ln -sfv "$file" "/usr/local/bin/$(basename "$file")"
			elif [ -d "$file" ]; then
				create_symlinks "$file"
			fi
		done
	}

	# Start the process from the base directory
	create_symlinks "$BASE_DIR"

	success "Symbolic links creation completed."
}

cmd_version() {
	printf "%s %s\n" "$SCRIPT_NAME" "$VERSION"
}

# ===================================
# ARGUMENT PARSING
# ===================================
parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-q | --quiet)
			QUIET=true
			shift
			;;
		-d | --debug)
			DEBUG=true
			shift
			;;
		-h | --help)
			cmd_help
			exit 0
			;;
		-v | --version)
			cmd_version
			exit 0
			;;
		-*)
			die "Unknown option: $1"
			;;
		*)
			shift
			;;
		esac
	done
}

# ===================================
# MAIN
# ===================================
main() {
	local command="${1:-help}"
	parse_arguments "$@"

	case "$command" in
	link)
		cmd_create_links "$@"
		;;
	help)
		cmd_help
		;;
	version)
		cmd_version "$@"
		;;
	*)
		die "Unknown command: '$command'. Use '$SCRIPT_NAME help'."
		;;
	esac
}

main "$@"
