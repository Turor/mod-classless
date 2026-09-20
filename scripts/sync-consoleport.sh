#!/usr/bin/env bash
# Copy Turor/ConsolePortLK (apps/consoleport-lk) into the patch-n AddOns tree for mpqcli.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/apps/consoleport-lk"
DST="$ROOT/UIMods/patch-n/Interface/AddOns"
if [[ ! -d "$SRC/ConsolePort" ]]; then
  echo "missing submodule $SRC (git submodule update --init apps/consoleport-lk)" >&2
  exit 1
fi
for addon in ConsolePort ConsolePortAdvanced ConsolePortBar ConsolePortHelp ConsolePortKeyboard ConsolePortLoader ConsolePortUI_Loot ConsolePortUI_Menu; do
  mkdir -p "$DST/$addon"
  rsync -a --delete --exclude .git "$SRC/$addon/" "$DST/$addon/"
done
echo "synced ConsolePort* from apps/consoleport-lk -> UIMods/patch-n/Interface/AddOns"
