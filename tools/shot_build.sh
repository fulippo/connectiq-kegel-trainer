#!/bin/bash
# Builds a screenshot-mode .prg in English whatever language the simulator is set to: the
# language folders are left out of a scratch copy. Writes shot/ShotConfig.mc first.
#   tools/shot_build.sh DEVICE OUT.prg SCREEN [STATE] [REMAINING] [REP] [SERIES]
# (DEV_KEY and the SDK's bin/ on PATH, as for monkeyc; see tools/shot_config.sh for the screens)
set -e
cd "$(dirname "$0")/.."
DEVICE="$1"; OUT="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2
tools/shot_config.sh "$@"
tmp=$(mktemp -d)
cp -R source shot resources manifest.xml monkey-shot.jungle "$tmp"/
monkeyc -f "$tmp/monkey-shot.jungle" -d "$DEVICE" -o "$OUT" -y "$DEV_KEY" -w
rm -rf "$tmp"
