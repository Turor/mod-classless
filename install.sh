#!/bin/bash

# Full installation script for mod-classless.
# Automates: DBC -> SQLite -> SQL Patches -> DBC -> UIMods/Server -> MPQ

set -e # Exit on error

# Default paths (can be overridden by environment variables)
DBC_INPUT_PATH="${1:-}"
SQLITE_DB_NAME="wrath_dbcs.sqlite"
SERVER_DBC_PATH="${SERVER_DBC_PATH:-../../cmake-build-debug-visual-studio/bin/Debug/dbc}"
MPQ_OUT_PATH="${MPQ_OUT_PATH:-D:/CustomWowRebuild/patchn-new/patch-n.mpq}"
GAME_CLIENT_DATA_PATH="${GAME_CLIENT_DATA_PATH:-D:/CustomWowRebuild/GameClient/Data}"
MPQ_CLI_PATH="${MPQ_CLI_PATH:-D:/CustomWowRebuild/Tools/mpqcli/mpqcli.exe}"
TEMP_GEN_PATH="${TEMP_GEN_PATH:-D:/CustomWowRebuild/patchn-new/gen}"

if [ -z "$DBC_INPUT_PATH" ]; then
    echo "Usage: $0 <path-to-extracted-DBFilesClient>"
    exit 1
fi

MODULE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATCH_GEN_DIR="$MODULE_ROOT/apps/patchgenerator"
WOW_DBC_DIR="$PATCH_GEN_DIR/wow_dbc"
SQLITE_DB_PATH="$WOW_DBC_DIR/$SQLITE_DB_NAME"
UI_MODS_PATH="$MODULE_ROOT/UIMods/patch-n"

echo "--- Phase 1: Creating SQLite Database ---"
pushd "$WOW_DBC_DIR" > /dev/null
cargo run -p wow_dbc_converter -- wrath -i "$DBC_INPUT_PATH" -o "$SQLITE_DB_NAME"
popd > /dev/null

echo -e "\n--- Phase 2: Applying SQL Patches ---"
pushd "$PATCH_GEN_DIR" > /dev/null
./apply_patches.sh
popd > /dev/null

echo -e "\n--- Phase 3: Generating DBCs ---"
mkdir -p "$TEMP_GEN_PATH"
pushd "$WOW_DBC_DIR" > /dev/null
DMLS_REQUIRED="$PATCH_GEN_DIR/dmls/required"
cargo run -p wow_custom_dbc -- wrath -o "$TEMP_GEN_PATH" -i "$DMLS_REQUIRED"
popd > /dev/null

echo -e "\n--- Phase 4: Deploying DBCs ---"
GEN_DBC_PATH="$TEMP_GEN_PATH/dbc"
TARGET_UI_MOD_DBC_PATH="$UI_MODS_PATH/DBFilesClient"

echo "Copying to UIMods..."
mkdir -p "$TARGET_UI_MOD_DBC_PATH"
cp -v "$GEN_DBC_PATH"/* "$TARGET_UI_MOD_DBC_PATH/"

echo "Copying to Worldserver..."
mkdir -p "$SERVER_DBC_PATH"
cp -v "$GEN_DBC_PATH"/* "$SERVER_DBC_PATH/"

echo -e "\n--- Phase 5: Generating MPQ ---"
rm -f "$MPQ_OUT_PATH"
mkdir -p "$(dirname "$MPQ_OUT_PATH")"

"$MPQ_CLI_PATH" create -o "$MPQ_OUT_PATH" "$UI_MODS_PATH"

echo "Copying MPQ to Game Client..."
if [ -d "$GAME_CLIENT_DATA_PATH" ]; then
    cp -v "$MPQ_OUT_PATH" "$GAME_CLIENT_DATA_PATH/"
else
    echo "Warning: Game client data path not found: $GAME_CLIENT_DATA_PATH. Skipping copy."
fi

echo -e "\nInstallation complete!"
