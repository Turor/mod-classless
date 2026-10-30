#!/bin/bash
# Render the daily-restart files for one realm into an output directory (no install, no side effects).
#   ./render.sh realms/standard.env out/standard
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
[ $# -eq 2 ] || { echo "usage: $0 <realm.env> <outdir>"; exit 1; }
# shellcheck disable=SC1090
. "$1"; out=$2; mkdir -p "$out"
: "${TRIGGER:?}" "${UNIT:?}"
sub(){ sed -e "s|@TRIGGER@|$TRIGGER|g" -e "s|@UNIT@|$UNIT|g" "$1"; }
sub "$here/DailyRestart.lua.tmpl" > "$out/DailyRestart.lua"
sub "$here/wow-daily-restart.sh.tmpl" > "$out/wow-daily-restart.sh"; chmod 755 "$out/wow-daily-restart.sh"
cp "$here"/wow-daily-restart-{trigger,watchdog}.{service,timer} "$out/"
echo "rendered $UNIT -> $out (DailyRestart.lua goes in ${LUA_DIR:-<lua_scripts>})"
