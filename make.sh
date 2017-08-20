#!/bin/sh
set -x
dmd -m64 genesis.d
rm *.o
