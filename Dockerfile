# Multi-stage build for mlat-server
# Stage 1: Build environment
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3 -m venv /opt/mlat-venv

# Install Python dependencies
RUN /opt/mlat-venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/mlat-venv/bin/pip install --no-cache-dir \
    numpy \
    scipy \
    pykalman \
    python-graph-core \
    uvloop \
    ujson \
    Cython \
    setuptools

# Copy source code
COPY . /opt/mlat-server

# Build Cython extensions
WORKDIR /opt/mlat-server
RUN /opt/mlat-venv/bin/python3 setup.py build_ext --inplace

# Stage 2: Runtime environment
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment and built code from builder
COPY --from=builder /opt/mlat-venv /opt/mlat-venv
COPY --from=builder /opt/mlat-server /opt/mlat-server

# Create working directory for runtime data
RUN mkdir -p /run/mlat-server && chmod 755 /run/mlat-server

# Set environment variables for performance
# These reduce multithreading overhead which is detrimental for this workload
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1
ENV OMP_NUM_THREADS=1
ENV PYTHONOPTIMIZE=2

WORKDIR /opt/mlat-server

# Expose default ports
# 31090: client connections
# 31003: filtered basestation output
# 31004: basestation output
EXPOSE 31090 31003 31004

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD test -f /run/mlat-server/positions.csv || exit 1

# Default command
CMD ["/opt/mlat-venv/bin/python3", "/opt/mlat-server/mlat-server", \
     "--client-listen", "31090", \
     "--filtered-basestation-listen", "31003", \
     "--basestation-listen", "31004", \
     "--write-csv", "/run/mlat-server/positions.csv", \
     "--work-dir", "/run/mlat-server"]
