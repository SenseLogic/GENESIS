#!/bin/sh
set -x
../genesis --input_folder GS/ --output_folder GO/ --recursive --style --verbose --debug .gs .go
cd GO
go run import.go

