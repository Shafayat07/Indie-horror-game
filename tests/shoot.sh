#!/bin/bash
# Usage: tests/shoot.sh <args...>   (renders with software GL under Xvfb)
cd "$(dirname "$0")/.."
timeout ${TIMEOUT:-240} xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --audio-driver Dummy --path . res://tests/driver.tscn -- "$@" 2>&1 | grep -vE "ALSA|^\s*$|audio_driver|at: |init_output"
