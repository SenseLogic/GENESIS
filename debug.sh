#!/bin/sh
set -x
dmd -debug -g -gf -gs -m64 genesis.d
rm *.o
