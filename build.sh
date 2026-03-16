#!/bin/zsh

# Exit on any error
set -e

# Run build command
odin build src -debug -vet-cast -vet-style -vet-using-param -strict-style -disallow-do -warnings-as-errors -collection:libs=./libs/ -out:build/silicon

# Run the program
./build/silicon
