#!/bin/bash
# Runs every scripted scenario headless and prints a summary.
cd "$(dirname "$0")/.."
run() {
	local name=$1; shift
	local log=/tmp/tide_test_$name.log
	timeout 600 godot --headless --path . res://tests/driver.tscn -- "$@" > "$log" 2>&1
	local res=$(grep -oE "scenario [a-z_]+: (PASS|FAIL)" "$log" | tail -1)
	echo "${res:-scenario $name: CRASH/TIMEOUT}"
	grep -E "FAIL:|SCRIPT ERROR" "$log" | head -10
}
run ai --cp=settlement --flags=entered_settlement --scenario=ai --wait=1
run death --cp=settlement --flags=entered_settlement --scenario=death --wait=1
run full_break --cp=dock_start --scenario=full_break --wait=1
run full_send --cp=dock_start --scenario=full_send --wait=1
