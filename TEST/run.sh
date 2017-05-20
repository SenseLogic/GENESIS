#!/bin/sh
set -x
../genesis --style --verbose --debug .gp .go
go run import_test.go

