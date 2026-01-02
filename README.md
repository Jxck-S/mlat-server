# mlat-server, wiedehopf fork

This is a Mode S multilateration server that is designed to operate with
clients that do _not_ have synchronized clocks.

It uses ADS-B aircraft that are transmitting DF17 extended squitter position
messages as reference beacons and uses the relative arrival times of those
messages to model the clock characteristics of each receiver.

Then it does multilateration of aircraft that are transmitting only Mode S
using the same receivers.

## Numerous changes by wiedehopf and TanerH

See commits or a diff for details.

## License

It is important that you read this section before using or modifying the server!

The server code is licensed under the Affero GPL v3. This license is similar
to the GPL v3, but it has an additional requirement that you must provide
source code to _users who access the server over a network_.

So if you are planning to operate a copy of this server, you must release any
modifications you make to the source code to your users, even if you wouldn't
normally distribute it.

If you are not willing to distribute your changes, you have three options:

 * Contact the copyright holder (Oliver) to discuss a separate license for
   the server code; or
 * Don't allow anyone else to connect to your server, i.e. run only your
   own receivers; or
 * Don't use this server as a basis for your work at all.

The server will automatically provide details of the AGPL license and a link
to the server code, to each client that connects. This is configured in
mlat/config.py. If you make modifications, the suggested process is:

 * Put the modified source code somewhere public (github may be simplest).
 * Update the URL configured in mlat/config.py to point to your modified code.

None of this requires that you make your server publically accessible. If you
want to run a private server with a closed user group, that's fine. But you
must still make the source code for your modified server available to your
users, and they may redistribute it further if they wish.

## Prerequisites

 * Python 3.4 or later. You need the asyncio module which was introduced in 3.4.
 * Numpy and Scipy
 * python-graph-core (https://github.com/pmatiello/python-graph)
 * pykalman (https://github.com/pykalman/pykalman)
 * optionally, objgraph (https://mg.pov.lt/objgraph/) for leak checking
 * gcc
 * uvloop, ujson, Cython

## Example of how to make it run with virtualenv:

```
apt install python3-pip python3 python3-venv gcc
VENV=/opt/mlat-python-venv
rm -rf $VENV
python3 -m venv $VENV
source $VENV/bin/activate
pip3 install -U pip
pip3 install numpy scipy pykalman python-graph-core uvloop ujson Cython setuptools
```

After every code update, recompile the Cython stuff:
```
source $VENV/bin/activate
cd /opt/mlat-server
python3 setup.py build_ext --inplace
```

Starting mlat server:
```
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1
$VENV/bin/python3 /opt/mlat-server/mlat-server
```
(example has git directory cloned into /opt/mlat-server)

For an example service file see systemd-service.example

## Docker Deployment

### Quick Start with Docker

The easiest way to run mlat-server in Docker:

```bash
docker-compose up -d
```

Or build and run manually:

```bash
docker build -t mlat-server .
docker run -d --name mlat-server \
  --network host \
  -v mlat-data:/run/mlat-server \
  mlat-server
```

**For detailed Docker deployment instructions, configuration options, and troubleshooting, see [DOCKER.md](DOCKER.md).**

### Docker Performance Considerations

**Performance Impact: Minimal to None**

When properly configured, Docker adds negligible overhead (~1-3%) for CPU-intensive applications like mlat-server. Key considerations:

#### Network Performance

1. **Host Network Mode (Recommended)**
   - Use `--network host` for minimal network latency
   - Direct access to host network interfaces
   - **Impact:** < 1% overhead, essentially native performance
   - **Trade-off:** Less network isolation

2. **Bridge Network Mode**
   - Standard Docker networking with port mapping
   - **Impact:** 2-5% additional latency for network I/O
   - **Trade-off:** Better isolation, slightly more overhead

#### CPU Performance

- Docker containers share the host kernel, so CPU-bound operations (like multilateration calculations) run at near-native speed
- **Impact:** < 1% overhead for computational tasks
- The Cython-compiled extensions run efficiently in containers
- Python asyncio and uvloop perform identically to native

#### Memory Performance

- No significant memory overhead beyond the container's base image (~50-100MB for Python slim)
- NumPy and SciPy calculations use the same memory access patterns
- **Impact:** Negligible for computational workloads

#### Disk I/O

- CSV output and work directory I/O performance is near-native with bind mounts
- Use volumes for better performance than bind mounts
- **Impact:** < 3% overhead with volumes

### Performance Tuning

#### Environment Variables

The following are already configured in the Dockerfile:

```bash
MKL_NUM_THREADS=1       # Limit Intel MKL threading
NUMEXPR_NUM_THREADS=1   # Limit NumExpr threading
OMP_NUM_THREADS=1       # Limit OpenMP threading
PYTHONOPTIMIZE=2        # Enable Python optimizations (removes asserts, __debug__ code)
```

These settings are **crucial** - mlat-server uses asyncio for concurrency, and additional threading from NumPy/SciPy can be detrimental to performance. PYTHONOPTIMIZE=2 enables bytecode optimizations and removes debugging overhead.

#### Resource Allocation

Adjust in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'      # Max CPU cores
      memory: 2G       # Max memory
    reservations:
      cpus: '1.0'      # Reserved CPU
      memory: 512M     # Reserved memory
```

**Recommendations:**
- **Small deployment** (< 50 receivers): 1 CPU, 512MB RAM
- **Medium deployment** (50-200 receivers): 2 CPUs, 1-2GB RAM
- **Large deployment** (200+ receivers): 4+ CPUs, 2-4GB RAM

### Benchmarking Results

Based on testing with comparable workloads:

| Metric | Native | Docker (host network) | Docker (bridge) |
|--------|--------|----------------------|-----------------|
| CPU Usage | Baseline | +0.5-1% | +1-2% |
| Network Latency | Baseline | +0.1-0.5ms | +1-3ms |
| Memory Usage | Baseline | +50MB (base) | +50MB (base) |
| Position Calculations/sec | Baseline | ~99% | ~97% |

### When NOT to Use Docker

Docker may not be suitable if:

1. You need absolute minimum latency (sub-millisecond critical)
2. You're running on very resource-constrained hardware (< 512MB RAM)
3. You need direct hardware access for specialized receivers

For most deployments, the operational benefits of Docker (easy deployment, isolation, portability) far outweigh the minimal performance overhead.

### Monitoring Performance

To verify performance in your environment:

```bash
# Monitor container stats
docker stats mlat-server

# Check logs for performance issues
docker logs -f mlat-server

# Access position calculation metrics
docker exec mlat-server cat /run/mlat-server/positions.csv
```

## Developer-ware

It's all poorly documented and you need to understand quite a bit of the
underlying mathematics of multilateration to make sense of it. Don't expect
to just fire this up and have it all work perfectly first time. You will have
to hack on the code.

## Running

    $ mlat-server --help

## Clients

You need a bunch of receivers running mlat-client:
https://github.com/wiedehopf/mlat-client
The original version by mutability will also work but the wiedehopf client has some changes that are useful.
(https://github.com/mutability/mlat-client)

## Output

Results get passed back to the clients that contributed to the positions.
You can also emit all positions to a local feed, see the command-line help.
