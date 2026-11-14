#!/usr/bin/env bash
# shot.sh <binary-name> <out.png>
# Captures the on-screen window of the newest process named <binary-name> (the crate's binary,
# e.g. `shot.sh my_game /tmp/shot.png`), even when other windows cover it.
# macOS only; needs Screen Recording access. The first call takes a few seconds while Swift warms up.
pid=$(pgrep -n -x "$1") || { echo "no process named $1" >&2; exit 1; }
id=$(swift - "$pid" <<'SWIFT' 2>/dev/null
import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
if let w = windows.first(where: { ($0[kCGWindowOwnerPID as String] as? Int32) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }) {
    print(w[kCGWindowNumber as String]!)
}
SWIFT
)
[ -n "$id" ] || { echo "process $pid has no on-screen window yet" >&2; exit 1; }
screencapture -x -o -l "$id" "$2" && echo "$2"
