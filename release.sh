#!/bin/sh
set -x
dmd -O -inline -m64 genesis.d
rm *.o
