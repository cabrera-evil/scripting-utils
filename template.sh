#!/usr/bin/env bash
set -euo pipefail

# ===================================
# METADATA
# ===================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"
readonly DESCRIPTION="Professional CLI script template"
readonly AUTHOR="Your Name"
readonly PID_FILE="/tmp/${SCRIPT_NAME}.pid"

# ===================================
# COLORS
# ===================================
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
	readonly RED=$'\033[0;31m'
	readonly GREEN=$'\033[0;32m'
	readonly YELLOW=$'\033[0;33m'
	readonly BLUE=$'\033[0;34m'
	readonly MAGENTA=$'\033[0;35m'
	readonly CYAN=$'\033[0;36m'
	readonly BOLD=$'\033[1m'
	readonly DIM=$'\033[2m'
	readonly NC=$'\033[0m'
else
	readonly RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' DIM='' NC=''
fi

# ===================================
# CONFIGURATION
# ===================================
# Default configuration values
CONFIG_VALUE="default"
NUMERIC_OPTION=10
FLAG_OPTION=false
QUIET=false
DEBUG=false
DRY_RUN=false

# ===================================
# LOGGING FUNCTIONS
# ===================================
log() { [[ "$QUIET" != true ]] && printf "${BLUE}▶${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$*" >&2; }
error() { printf "${RED}✗${NC} %s\n" "$*" >&2; }
success() { [[ "$QUIET" != true ]] && printf "${GREEN}✓${NC} %s\n" "$*"; }
debug() { [[ "$DEBUG" == true ]] && printf "${MAGENTA}⚈${NC} DEBUG: %s\n" "$*" >&2; }
info() { [[ "$QUIET" != true ]] && printf "${CYAN}ℹ${NC} %s\n" "$*"; }

die() {
	error "$*"
	cleanup
	exit 1
}

# ===================================
# UTILITY FUNCTIONS
# ===================================
require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		die "'$1' not found. Install with: sudo apt install ${2:-$1}"
	fi
}

is_running() {
	[[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

cleanup() {
	[[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
	debug "Cleanup completed"
}

show_progress() {
	local current="$1"
	local total="$2"
	local width=50
	local percent=$((current * 100 / total))
	local filled=$((current * width / total))

	printf "\r${BLUE}Progress: ${NC}["
	printf "%*s" "$filled" | tr ' ' '█'
	printf "%*s" $((width - filled)) | tr ' ' '░'
	printf "] ${BOLD}%d%%${NC} (%d/%d)" "$percent" "$current" "$total"

	[[ "$current" -eq "$total" ]] && printf "\n"
}

# ===================================
# SIGNAL HANDLERS
# ===================================
trap 'die "Interrupted by user"' INT TERM
trap cleanup EXIT

# ===================================
# VALIDATION FUNCTIONS
# ===================================
validate_positive_integer() {
	local value="$1"
	local name="$2"

	if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
		die "Invalid $name: '$value' (must be positive integer)"
	fi
}

validate_file_exists() {
	local file="$1"
	[[ -f "$file" ]] || die "File not found: $file"
}

validate_directory_exists() {
	local dir="$1"
	[[ -d "$dir" ]] || die "Directory not found: $dir"
}

validate_config() {
	debug "Validating configuration..."

	# Add your validation logic here
	case "$CONFIG_VALUE" in
	option1 | option2 | option3) ;;
	*) die "Invalid config value: '$CONFIG_VALUE' (use: option1, option2, option3)" ;;
	esac

	validate_positive_integer "$NUMERIC_OPTION" "numeric option"

	debug "Configuration validation passed"
}

# ===================================
# CORE BUSINESS LOGIC
# ===================================
do_main_task() {
	local input="$1"

	log "Starting main task with input: $input"

	if [[ "$DRY_RUN" == true ]]; then
		info "[DRY RUN] Would process: $input"
		return 0
	fi

	# Simulate some work with progress
	for i in {1..10}; do
		show_progress "$i" 10
		sleep 0.1
	done

	success "Main task completed successfully"
}

process_batch() {
	local items=("$@")
	local total="${#items[@]}"

	log "Processing batch of $total items"

	for i in "${!items[@]}"; do
		local item="${items[$i]}"
		debug "Processing item $((i + 1))/$total: $item"

		if [[ "$DRY_RUN" == true ]]; then
			info "[DRY RUN] Would process: $item"
		else
			# Your processing logic here
			sleep 0.2 # Simulate work
		fi

		show_progress $((i + 1)) "$total"
	done

	success "Batch processing completed"
}

# ===================================
# COMMAND IMPLEMENTATIONS
# ===================================
cmd_start() {
	if is_running; then
		die "Service already running (PID: $(cat "$PID_FILE"))"
	fi

	validate_config

	# Create PID file
	echo $$ >"$PID_FILE"

	printf "\n${BOLD}Starting Service${NC}\n"
	printf "Config:  ${GREEN}%s${NC}\n" "$CONFIG_VALUE"
	printf "Option:  ${GREEN}%s${NC}\n" "$NUMERIC_OPTION"
	printf "Flag:    ${GREEN}%s${NC}\n" "$FLAG_OPTION"
	printf "\nPress ${BOLD}Ctrl+C${NC} to stop\n\n"

	# Main service loop
	local iteration=0
	while true; do
		((++iteration))

		log "Service iteration #$iteration"
		do_main_task "service-data-$iteration"

		sleep "$NUMERIC_OPTION"
	done
}

cmd_stop() {
	if ! is_running; then
		warn "Service is not running"
		exit 1
	fi

	local pid
	pid=$(cat "$PID_FILE")

	if kill "$pid" 2>/dev/null; then
		success "Service stopped successfully (PID: $pid)"
		rm -f "$PID_FILE"
	else
		die "Failed to stop service (PID: $pid)"
	fi
}

cmd_status() {
	if is_running; then
		local pid uptime
		pid=$(cat "$PID_FILE")
		uptime=$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ' || echo "unknown")

		printf "\n${BOLD}Service Status${NC}\n"
		printf "Status:  ${GREEN}Running${NC}\n"
		printf "PID:     ${GREEN}%s${NC}\n" "$pid"
		printf "Uptime:  ${GREEN}%s${NC}\n" "$uptime"
		printf "Config:  ${GREEN}%s${NC}\n" "$CONFIG_VALUE"
		printf "\n"
	else
		printf "\n${BOLD}Service Status${NC}\n"
		printf "Status:  ${YELLOW}Not running${NC}\n\n"
		exit 1
	fi
}

cmd_process() {
	local input_file="${1:?Missing input file argument}"
	validate_file_exists "$input_file"
	validate_config

	log "Processing file: $input_file"

	# Read file into array (example)
	mapfile -t lines <"$input_file"

	if [[ "${#lines[@]}" -eq 0 ]]; then
		warn "Input file is empty"
		exit 1
	fi

	process_batch "${lines[@]}"
}

cmd_batch() {
	local directory="${1:?Missing directory argument}"
	validate_directory_exists "$directory"
	validate_config

	log "Processing directory: $directory"

	local files=()
	while IFS= read -r -d '' file; do
		files+=("$file")
	done < <(find "$directory" -name "*.txt" -print0 2>/dev/null)

	if [[ "${#files[@]}" -eq 0 ]]; then
		warn "No .txt files found in directory"
		exit 1
	fi

	info "Found ${#files[@]} files to process"
	process_batch "${files[@]}"
}

cmd_test() {
	printf "\n${BOLD}Running Tests${NC}\n\n"

	# Test 1: Configuration validation
	log "Testing configuration validation..."
	validate_config
	success "Configuration validation test passed"

	# Test 2: Main task functionality
	log "Testing main task functionality..."
	do_main_task "test-input"
	success "Main task test passed"

	# Test 3: Batch processing
	log "Testing batch processing..."
	local test_items=("item1" "item2" "item3")
	process_batch "${test_items[@]}"
	success "Batch processing test passed"

	printf "\n${GREEN}${BOLD}All tests passed!${NC}\n\n"
}

cmd_config() {
	local subcommand="${1:-show}"

	case "$subcommand" in
	show)
		printf "\n${BOLD}Current Configuration${NC}\n"
		printf "Config Value:    ${GREEN}%s${NC}\n" "$CONFIG_VALUE"
		printf "Numeric Option:  ${GREEN}%s${NC}\n" "$NUMERIC_OPTION"
		printf "Flag Option:     ${GREEN}%s${NC}\n" "$FLAG_OPTION"
		printf "Debug Mode:      ${GREEN}%s${NC}\n" "$DEBUG"
		printf "Quiet Mode:      ${GREEN}%s${NC}\n" "$QUIET"
		printf "Dry Run:         ${GREEN}%s${NC}\n" "$DRY_RUN"
		printf "\n"
		;;
	reset)
		info "Resetting configuration to defaults..."
		CONFIG_VALUE="default"
		NUMERIC_OPTION=10
		FLAG_OPTION=false
		success "Configuration reset to defaults"
		;;
	*)
		die "Unknown config subcommand: '$subcommand' (use: show, reset)"
		;;
	esac
}

# ===================================
# HELP & VERSION
# ===================================
show_help() {
	cat <<EOF

${BOLD}${SCRIPT_NAME}${NC} - ${DESCRIPTION}

${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] COMMAND [ARGS]

${BOLD}COMMANDS:${NC}
    ${GREEN}start${NC}             Start the service daemon
    ${GREEN}stop${NC}              Stop the running service
    ${GREEN}status${NC}            Show current service status
    ${GREEN}process${NC} FILE      Process a single file
    ${GREEN}batch${NC} DIR         Process all files in directory
    ${GREEN}test${NC}              Run built-in tests
    ${GREEN}config${NC} [show|reset] Manage configuration
    ${GREEN}help${NC}              Show this help message
    ${GREEN}version${NC}           Show version information

${BOLD}OPTIONS:${NC}
    ${YELLOW}-c, --config${NC} VALUE      Set config value (default: $CONFIG_VALUE)
    ${YELLOW}-n, --number${NC} NUM        Set numeric option (default: $NUMERIC_OPTION)
    ${YELLOW}-f, --flag${NC}              Enable flag option
    ${YELLOW}-q, --quiet${NC}             Minimize output messages
    ${YELLOW}-d, --debug${NC}             Enable debug output
    ${YELLOW}-n, --dry-run${NC}           Show what would be done
    ${YELLOW}-h, --help${NC}              Show this help message
    ${YELLOW}-v, --version${NC}           Show version information

${BOLD}EXAMPLES:${NC}
    $SCRIPT_NAME start                      ${DIM}# Start service with defaults${NC}
    $SCRIPT_NAME start -c option1 -n 30    ${DIM}# Start with custom config${NC}
    $SCRIPT_NAME process data.txt           ${DIM}# Process single file${NC}
    $SCRIPT_NAME batch /path/to/files       ${DIM}# Process directory${NC}
    $SCRIPT_NAME test --debug               ${DIM}# Run tests with debug info${NC}
    $SCRIPT_NAME config show               ${DIM}# Show current config${NC}

${BOLD}CONFIG VALUES:${NC}
    ${GREEN}option1${NC}    First configuration option
    ${GREEN}option2${NC}    Second configuration option
    ${GREEN}option3${NC}    Third configuration option

${BOLD}AUTHOR:${NC}
    ${AUTHOR}

EOF
}

show_version() {
	printf "%s %s\n" "$SCRIPT_NAME" "$VERSION"
	[[ "$DEBUG" == true ]] && {
		printf "Description: %s\n" "$DESCRIPTION"
		printf "Author: %s\n" "$AUTHOR"
		printf "Bash: %s\n" "$BASH_VERSION"
	}
}

# ===================================
# ARGUMENT PARSING
# ===================================
parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-c | --config)
			CONFIG_VALUE="${2:?Missing argument for $1}"
			shift 2
			;;
		-n | --number)
			NUMERIC_OPTION="${2:?Missing argument for $1}"
			validate_positive_integer "$NUMERIC_OPTION" "numeric option"
			shift 2
			;;
		-f | --flag)
			FLAG_OPTION=true
			shift
			;;
		-q | --quiet)
			QUIET=true
			shift
			;;
		-d | --debug)
			DEBUG=true
			shift
			;;
		--dry-run)
			DRY_RUN=true
			shift
			;;
		-h | --help)
			show_help
			exit 0
			;;
		-v | --version)
			show_version
			exit 0
			;;
		-*)
			die "Unknown option: $1"
			;;
		*)
			# Return remaining arguments
			printf '%s\n' "$@"
			return
			;;
		esac
	done
}

# ===================================
# MAIN FUNCTION
# ===================================
main() {
	local command="${1:-help}"
	parse_arguments "$@"

	# Execute command
	case "$command" in
	start) cmd_start ;;
	stop) cmd_stop ;;
	status) cmd_status ;;
	process) cmd_process "$@" ;;
	batch) cmd_batch "$@" ;;
	test) cmd_test ;;
	config) cmd_config "$@" ;;
	help) show_help ;;
	version) show_version ;;
	*) die "Unknown command: '$command'. Use '$SCRIPT_NAME help' for usage information." ;;
	esac
}

# ===================================
# ENTRY POINT
# ===================================
main "$@"
