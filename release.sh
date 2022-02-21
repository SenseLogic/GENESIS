#!/bin/sh
set -x
dmd -O -m64 genesis.d
rm *.o
