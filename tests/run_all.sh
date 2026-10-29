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
run walk_surface --cp=dock_start --scenario=walk_surface --wait=1
run walk_cliff --cp=station_transmit --flags=tide_out,transmitted,has_station_key,reached_station,door_station_gate,door_station_main,station_power,relays_ok --scenario=walk_cliff --wait=1
run walk_cave_a --cp=caves --flags=tide_out,found_caves --scenario=walk_cave_a --wait=1
run walk_cave --cp=caves_gate --flags=tide_out,found_caves,seal_open,door_seal --scenario=walk_cave --wait=1
run walk_lighthouse --cp=lighthouse --flags=tide_out,reached_lighthouse --scenario=walk_lighthouse --wait=1
run walk_return --cp=aftermath --flags=tide_out,chose_break,lh_unbarred,gate_unchained,entered_settlement --scenario=walk_return --wait=1
run menus --cp=settlement --flags=entered_settlement --scenario=menus --wait=1
