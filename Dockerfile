FROM python:3.14-slim

WORKDIR /app

# Install build dependencies
# gcc and python3-dev are required for compiling Cython extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Build the Cython extensions in-place
RUN python3 setup.py build_ext --inplace && \
    chmod +x start.sh

# Copy docker-entrypoint
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

# Expose default ports
EXPOSE 31090 30104 8080

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["--help"]
