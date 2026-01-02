#!/bin/bash
set -e

# Restrict numerical libraries to single-threaded mode.
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1

# Defaults
WORK_DIR=${WORK_DIR:-/run/mlat-server}

# Ensure work directory exists (optional, mostly for safety)
mkdir -p "$WORK_DIR"

# Optional: Start a simple HTTP server to expose the work directory (JSON files)
if [ -n "$HTTP_PORT" ]; then
    echo "Starting HTTP server on port $HTTP_PORT serving $WORK_DIR"
    python3 -m http.server "$HTTP_PORT" --directory "$WORK_DIR" &
fi

# Pass ALL arguments directly to mlat-server
exec python3 mlat-server "$@"
