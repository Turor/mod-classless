#!/bin/bash
# Apply classless DBC SQLite patches with Flyway.
set -euo pipefail

FLYWAY_VERSION="${FLYWAY_VERSION:-11.10.1}"
SQLITE_DB="${SQLITE_DB:-./wow_dbc/wrath_dbcs.sqlite}"
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FLYWAY_HOME="${FLYWAY_HOME:-$BASE_DIR/.flyway/flyway-${FLYWAY_VERSION}}"

if [[ "$SQLITE_DB" != /* ]]; then
    SQLITE_DB="$BASE_DIR/$SQLITE_DB"
fi

if [ ! -f "$SQLITE_DB" ]; then
    echo "Error: SQLite database not found: $SQLITE_DB" >&2
    echo "Create it first with wow_dbc_converter, e.g.:" >&2
    echo "  cargo run -p wow_dbc_converter -- wrath -i /path/to/DBFilesClient -o wrath_dbcs.sqlite" >&2
    exit 1
fi

ensure_flyway() {
    if [ -x "$FLYWAY_HOME/flyway" ]; then
        return 0
    fi
    if command -v flyway >/dev/null 2>&1; then
        FLYWAY_BIN="$(command -v flyway)"
        return 0
    fi

    local archive="flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz"
    local url="https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/${FLYWAY_VERSION}/${archive}"
    local dest="$BASE_DIR/.flyway"
    mkdir -p "$dest"
    echo "Downloading Flyway ${FLYWAY_VERSION}..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest/$archive"
    else
        wget -qO "$dest/$archive" "$url"
    fi
    tar -xzf "$dest/$archive" -C "$dest"
    rm -f "$dest/$archive"
    FLYWAY_HOME="$dest/flyway-${FLYWAY_VERSION}"
}

ensure_flyway

if [ -z "${FLYWAY_BIN:-}" ]; then
    FLYWAY_BIN="$FLYWAY_HOME/flyway"
fi

# jdbc:sqlite needs an absolute path so Flyway's cwd does not matter.
JDBC_URL="jdbc:sqlite:${SQLITE_DB}"

echo "Migrating $SQLITE_DB with Flyway..."
"$FLYWAY_BIN" \
    -configFiles="$BASE_DIR/flyway.conf" \
    -workingDirectory="$BASE_DIR" \
    -url="$JDBC_URL" \
    migrate

echo "Finished applying patches."
echo "  flyway info: $FLYWAY_BIN -configFiles=$BASE_DIR/flyway.conf -workingDirectory=$BASE_DIR -url=$JDBC_URL info"
