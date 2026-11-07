#!/usr/bin/env bash
exec 3<>/dev/tcp/127.0.0.1/${GODOT_CONSOLE_PORT:-7777} && printf '%s\n' "$1" >&3 && read -r line <&3 && echo "$line"
