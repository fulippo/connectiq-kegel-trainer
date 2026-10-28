#!/bin/bash
# Writes shot/ShotConfig.mc for a screenshot-mode build (monkey-shot.jungle; see source/ShotMode.mc).
#   tools/shot_config.sh SCREEN [STATE] [REMAINING] [REP] [SERIES]
# SCREEN: ready | exercise | complete. STATE: 0 ready, 1 countdown, 2 contract, 3 relax, 4 complete.
# REMAINING: seconds left in the phase. REP / SERIES: the numbers shown.
set -e
cd "$(dirname "$0")/.."
mkdir -p shot
cat > shot/ShotConfig.mc <<EOF
const SHOT_SCREEN = "${1:-ready}";
const SHOT_STATE = ${2:-0};
const SHOT_REMAINING = ${3:-3};
const SHOT_REP = ${4:-1};
const SHOT_SERIES = ${5:-1};
EOF
