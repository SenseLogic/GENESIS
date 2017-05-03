#!/bin/sh
set -x
../genesis --join_lines --verbose --debug .gp .go
read key
go run import_test.go
read key

