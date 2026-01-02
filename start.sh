#!/bin/bash
set -e

# Restrict numerical libraries to single-threaded mode.
# This is important for mlat-server because it uses asyncio for concurrency.
# If these libraries spawn multiple threads, it can interrupt the main event loop
# and cause significant CPU contention and overhead, reducing performance.
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1

# Execute the mlat-server with arguments passed to the script
exec python3 mlat-server "$@"
