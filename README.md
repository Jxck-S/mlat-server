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

See the `COPYING` file for license details (AGPL v3).

## Prerequisites

 * Python 3.14.
 * See `requirements.txt` for Python dependencies.
 * gcc

## Example of how to make it run with virtualenv:

```
apt install python3-pip python3 python3-venv gcc
VENV=/opt/mlat-python-venv
rm -rf $VENV
python3 -m venv $VENV
source $VENV/bin/activate
pip3 install -U pip
pip3 install -r requirements.txt
```

After every code update, recompile the Cython stuff:
```
source $VENV/bin/activate
cd /opt/mlat-server
python3 setup.py build_ext --inplace
```

Starting mlat server:
```
chmod +x start.sh
./start.sh
```
(example has git directory cloned into /opt/mlat-server)

For an example service file see systemd-service.example

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
