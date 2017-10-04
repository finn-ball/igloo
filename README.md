# Igloo Project Builder
A project builder for the iCE40 FPGA series. Uses the [IceStorm](http://www.clifford.at/icestorm/) toolset.

## Install 
Make sure you have the [IceStorm](http://www.clifford.at/icestorm/) toolset installed

```
git clone https://github.com/finnball/igloo.git
cd igloo
source source.sh
igloo.py --help
```
# Creating Projects

Creating projects involves abiding by the file structure and creating settings files.

## Quick Project Build

```
igloo.py create projects/blink/cfg/config.ini
make
make burn
```
