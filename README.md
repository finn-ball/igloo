# Igloo Project Builder
A project builder for the iCE40 FPGA series. Uses the [IceStorm](http://www.clifford.at/icestorm/) toolset.

## Install 
Follow the [IceStorm](http://www.clifford.at/icestorm/) installation instructions, including the installation of [arachne-pnr] (https://github.com/cseed/arachne-pnr).

```
git clone https://github.com/finnball/igloo.git
cd igloo
source source.sh
igloo.py --help
```
# Quick Project Build

Creating projects involves abiding by the file structure and creating settings files.

## Create and Burn

```
igloo.py create projects/blink/cfg/config.ini
make
make burn
```
You should notice a pretty LED pattern.

## Timing Information

`make time`

Displays the timing information using [icetime](http://www.clifford.at/icestorm/).

## Simulating

Each project should come with a test bench. A simple way to simulate the project is to use [iverilog](http://iverilog.icarus.com/) and [gtkwave](http://gtkwave.sourceforge.net/).

```
make gtkwave
gtkwave ./build/iverilog/blink.vcd
```

This will produce a `.vvp` file followed by a `.vcd` file for gtkwave.

# Echo Project

```
igloo.py create projects/uart_echo/cfg/config.ini
make
make burn
```

Run `igloo.py echo` (Requires [pySerial](https://pythonhosted.org/pyserial/) to be [installed](http://pyserial.readthedocs.io/en/latest/pyserial.html)):

```
igloo.py echo Hello --tty=/dev/ttyUSB1
```

### Error: SerialException: No such file or directory

Find the serial device the FPGA is connected to with a command such as:

```
dmesg | grep tty
```

### Error: SerialException: Permission Denied

Test if you have permission:

```
cat /dev/ttyUSB1
```

If you don't have permission to view:

```
sudo usermod -a -G dialout $(USER)
```
You may have to log out / in after running this command.