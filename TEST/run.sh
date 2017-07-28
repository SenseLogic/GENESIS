#!/bin/sh
set -x
../generis --style --verbose --debug .gp .go
go run import_test.go

