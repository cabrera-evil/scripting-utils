#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/utils/usbresetctl"

fail() {
	printf 'not ok - %s\n' "$*" >&2
	exit 1
}

assert_contains() {
	local haystack="$1"
	local needle="$2"

	[[ "$haystack" == *"$needle"* ]] || fail "Expected output to contain: $needle"
}

run_cmd() {
	local output
	if ! output="$("$@" 2>&1)"; then
		printf '%s\n' "$output"
		return 1
	fi
	printf '%s\n' "$output"
}

make_device() {
	local root="$1"
	local name="$2"
	local vendor="$3"
	local product="$4"
	local busnum="$5"
	local devnum="$6"
	local manufacturer="$7"
	local product_name="$8"

	mkdir -p "$root/$name/driver"
	printf '%s\n' "$vendor" >"$root/$name/idVendor"
	printf '%s\n' "$product" >"$root/$name/idProduct"
	printf '%s\n' "$busnum" >"$root/$name/busnum"
	printf '%s\n' "$devnum" >"$root/$name/devnum"
	printf '%s\n' "$manufacturer" >"$root/$name/manufacturer"
	printf '%s\n' "$product_name" >"$root/$name/product"
}

make_device_with_driver_symlink() {
	local root="$1"
	local name="$2"
	local vendor="$3"
	local product="$4"
	local busnum="$5"
	local devnum="$6"
	local manufacturer="$7"
	local product_name="$8"
	local driver_dir="$9"

	make_device "$root" "$name" "$vendor" "$product" "$busnum" "$devnum" "$manufacturer" "$product_name"
	rm -rf "$root/$name/driver"
	ln -s "$driver_dir" "$root/$name/driver"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

sysfs="$tmpdir/sys/bus/usb/devices"
mkdir -p "$sysfs"
make_device "$sysfs" "1-2" "046d" "0ac4" "001" "004" "Logitech" "USB Headset"
make_device "$sysfs" "1-3" "046d" "0ac4" "001" "005" "Logitech" "Spare Headset"
make_device "$sysfs" "2-1" "1234" "abcd" "002" "006" "Example" "Other Device"

help_output="$(run_cmd "$SCRIPT" help)"
assert_contains "$help_output" "list"
assert_contains "$help_output" "reset"
assert_contains "$help_output" "--vidpid 046d:0ac4"

version_output="$(run_cmd "$SCRIPT" version)"
assert_contains "$version_output" "usbresetctl"

list_output="$(run_cmd "$SCRIPT" list --sysfs-root "$sysfs")"
assert_contains "$list_output" "046d:0ac4"
assert_contains "$list_output" "001:004"
assert_contains "$list_output" "Logitech USB Headset"

dry_run_output="$(run_cmd "$SCRIPT" reset --sysfs-root "$sysfs" --path 1-2 --dry-run)"
assert_contains "$dry_run_output" "[DRY RUN]"
assert_contains "$dry_run_output" "unbind 1-2"
assert_contains "$dry_run_output" "bind 1-2"

set +e
ambiguous_output="$("$SCRIPT" reset --sysfs-root "$sysfs" --vidpid 046d:0ac4 --dry-run 2>&1)"
ambiguous_status=$?
set -e
[[ "$ambiguous_status" -ne 0 ]] || fail "Expected ambiguous VID:PID reset to fail"
assert_contains "$ambiguous_output" "matched 2 devices"

all_output="$(run_cmd "$SCRIPT" reset --sysfs-root "$sysfs" --vidpid 046d:0ac4 --all --dry-run)"
assert_contains "$all_output" "Reset plan: 2 device(s)"
assert_contains "$all_output" "unbind 1-2"
assert_contains "$all_output" "unbind 1-3"

live_sysfs="$tmpdir/live/sys/bus/usb/devices"
live_driver="$tmpdir/live/driver/usb"
mkdir -p "$live_sysfs" "$live_driver"
make_device_with_driver_symlink "$live_sysfs" "9-9" "046d" "0ac4" "009" "009" "Logitech" "Live Fake Headset" "$live_driver"
mkfifo "$live_driver/unbind"
mkfifo "$live_driver/bind"

{
	IFS= read -r unbound_name <"$live_driver/unbind" || [[ -n "$unbound_name" ]]
	printf '%s\n' "$unbound_name" >"$tmpdir/unbound"
	rm -f "$live_sysfs/9-9/driver"
} &
unbind_reader=$!

{
	IFS= read -r rebound_name <"$live_driver/bind" || [[ -n "$rebound_name" ]]
	printf '%s\n' "$rebound_name" >"$tmpdir/rebound"
} &
bind_reader=$!

live_output="$(run_cmd "$SCRIPT" reset --sysfs-root "$live_sysfs" --path 9-9)"
wait "$unbind_reader" || fail "Unbind reader failed"
wait "$bind_reader" || fail "Bind reader failed"
assert_contains "$live_output" "Reset complete"
[[ "$(cat "$tmpdir/unbound")" == "9-9" ]] || fail "Expected unbind to target 9-9"
[[ "$(cat "$tmpdir/rebound")" == "9-9" ]] || fail "Expected bind to target 9-9"

printf 'ok - usbresetctl cli behavior\n'
